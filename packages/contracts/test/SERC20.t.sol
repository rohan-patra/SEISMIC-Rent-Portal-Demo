// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SERC20} from "../src/SERC-20.sol";
import {IERC20Errors} from "../openzeppelin/interfaces/draft-IERC6093.sol";

contract TestSERC20 is SERC20 {
    constructor(string memory name, string memory symbol) SERC20(name, symbol) {}

    function mint(address account, uint256 value) public {
        _mint(account, value);
    }

    function burn(address account, uint256 value) public {
        _burn(account, value);
    }
}

contract SERC20Test is Test {
    TestSERC20 public token;
    address public initialHolder;
    address public recipient;
    address public anotherAccount;
    uint256 public initialSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        initialHolder = address(1);
        recipient = address(2);
        anotherAccount = address(3);
        initialSupply = 100 * 10**18; // 100 tokens with 18 decimals

        token = new TestSERC20("My Token", "MTKN");
        token.mint(initialHolder, initialSupply);
    }

    function test_Metadata() public view {
        assertEq(token.name(), "My Token");
        assertEq(token.symbol(), "MTKN");
        assertEq(token.decimals(), 18);
    }

    function test_TotalSupply() public view {
        assertEq(token.totalSupply(), initialSupply);
    }

    function test_BalanceOf() public {
        // When checking own balance
        vm.prank(initialHolder);
        assertEq(token.balanceOf(initialHolder), initialSupply);

        // When checking other's balance (should return 0 for privacy)
        assertEq(token.balanceOf(initialHolder), 0);
    }

    function test_Transfer() public {
        uint256 transferAmount = 50 * 10**18;
        
        vm.prank(initialHolder);
        token.transfer(recipient, transferAmount);

        // Check balances
        vm.prank(initialHolder);
        assertEq(token.balanceOf(initialHolder), initialSupply - transferAmount);
        
        vm.prank(recipient);
        assertEq(token.balanceOf(recipient), transferAmount);
    }

    function test_TransferFailsForInsufficientBalance() public {
        uint256 transferAmount = initialSupply + 1;
        
        vm.prank(initialHolder);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, initialHolder, 0, 0));
        token.transfer(recipient, transferAmount);
    }

    function test_TransferFailsForZeroAddress() public {
        vm.prank(initialHolder);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.transfer(address(0), 1);
    }

    function test_Approve() public {
        vm.prank(initialHolder);
        token.approve(recipient, initialSupply);

        // Check allowance (visible only to owner or spender)
        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, recipient), initialSupply);
        
        vm.prank(recipient);
        assertEq(token.allowance(initialHolder, recipient), initialSupply);

        // Check allowance (should be 0 for others)
        vm.prank(anotherAccount);
        assertEq(token.allowance(initialHolder, recipient), 0);
    }

    function test_TransferFrom() public {
        uint256 transferAmount = 50 * 10**18;
        
        // Approve first
        vm.prank(initialHolder);
        token.approve(recipient, transferAmount);

        // Transfer using transferFrom
        vm.prank(recipient);
        token.transferFrom(initialHolder, anotherAccount, transferAmount);

        // Check balances
        vm.prank(initialHolder);
        assertEq(token.balanceOf(initialHolder), initialSupply - transferAmount);
        
        vm.prank(anotherAccount);
        assertEq(token.balanceOf(anotherAccount), transferAmount);

        // Check allowance is reduced
        vm.prank(recipient);
        assertEq(token.allowance(initialHolder, recipient), 0);
    }

    function test_TransferFromFailsWithoutAllowance() public {
        vm.prank(recipient);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, recipient, 0, 0));
        token.transferFrom(initialHolder, anotherAccount, 1);
    }

    function test_MintToZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.mint(address(0), 1);
    }

    function test_BurnFromZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSender.selector, address(0)));
        token.burn(address(0), 1);
    }

    function test_BurnExceedingBalance() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, initialHolder, 0, 0));
        token.burn(initialHolder, initialSupply + 1);
    }

    // Transfer Events Tests

    function test_TransferEmitsEvent() public {
        uint256 transferAmount = 50 * 10**18;
        
        // We expect a Transfer event with value 0 (for privacy)
        vm.expectEmit(true, true, false, true);
        emit Transfer(initialHolder, recipient, 0);
        
        vm.prank(initialHolder);
        token.transfer(recipient, transferAmount);
    }

    function test_MintEmitsTransferEvent() public {
        uint256 mintAmount = 100 * 10**18;
        
        // Minting should emit a Transfer from zero address with value 0 (for privacy)
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), recipient, 0);
        
        token.mint(recipient, mintAmount);
    }

    function test_BurnEmitsTransferEvent() public {
        uint256 burnAmount = 50 * 10**18;
        
        // Burning should emit a Transfer to zero address with value 0 (for privacy)
        vm.expectEmit(true, true, false, true);
        emit Transfer(initialHolder, address(0), 0);
        
        token.burn(initialHolder, burnAmount);
    }

    function test_TransferFromEmitsTransferEvent() public {
        uint256 transferAmount = 50 * 10**18;
        
        // Approve first
        vm.prank(initialHolder);
        token.approve(recipient, transferAmount);
        
        // TransferFrom should emit a Transfer event with value 0 (for privacy)
        vm.expectEmit(true, true, false, true);
        emit Transfer(initialHolder, anotherAccount, 0);
        
        vm.prank(recipient);
        token.transferFrom(initialHolder, anotherAccount, transferAmount);
    }

    function test_ZeroValueTransferEmitsEvent() public {
        // Even zero-value transfers should emit an event
        vm.expectEmit(true, true, false, true);
        emit Transfer(initialHolder, recipient, 0);
        
        vm.prank(initialHolder);
        token.transfer(recipient, 0);
    }

}
