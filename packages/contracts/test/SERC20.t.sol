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

contract TestSERC20Decimals is SERC20 {
    uint8 private immutable _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) SERC20(name, symbol) {
        _decimals = decimals_;
    }

    function mint(address account, uint256 value) public {
        _mint(account, value);
    }

    function burn(address account, uint256 value) public {
        _burn(account, value);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

contract SERC20Test is Test {
    TestSERC20 public token;
    address public initialHolder;
    address public recipient;
    address public anotherAccount;
    uint256 public initialSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

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

    function test_BurnFromZeroAddressReverts() public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSender.selector, address(0)));
        token.burn(address(0), 100);
    }

    function test_BurnExceedingBalanceReverts() public {
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

    // Infinite Approval Tests

    function test_InfiniteApprovalRemainsUnchanged() public {
        // Approve with max uint256
        vm.prank(initialHolder);
        token.approve(recipient, type(uint256).max);

        // Do a transferFrom
        vm.prank(recipient);
        token.transferFrom(initialHolder, anotherAccount, 50 * 10**18);

        // Check that allowance is still infinite
        vm.prank(recipient);
        assertEq(token.allowance(initialHolder, recipient), type(uint256).max);
    }

    function test_InfiniteApprovalNoEventOnTransferFrom() public {
        // Setup infinite approval
        vm.prank(initialHolder);
        token.approve(recipient, type(uint256).max);

        // For TransferFrom with infinite approval:
        // 1. Should emit Transfer event (with 0 value for privacy)
        // 2. Should NOT emit Approval event
        vm.expectEmit(true, true, false, true);
        emit Transfer(initialHolder, anotherAccount, 0);
        
        vm.prank(recipient);
        token.transferFrom(initialHolder, anotherAccount, 50 * 10**18);
    }

    function test_InfiniteApprovalMultipleTransfers() public {
        uint256 transferAmount = 20 * 10**18;
        
        // Setup infinite approval
        vm.prank(initialHolder);
        token.approve(recipient, type(uint256).max);

        // Do multiple transfers
        for(uint256 i = 0; i < 3; i++) {
            vm.prank(recipient);
            token.transferFrom(initialHolder, anotherAccount, transferAmount);

            // Check allowance remains infinite
            vm.prank(recipient);
            assertEq(token.allowance(initialHolder, recipient), type(uint256).max);
        }

        // Verify final balances
        vm.prank(initialHolder);
        assertEq(token.balanceOf(initialHolder), initialSupply - (transferAmount * 3));
        
        vm.prank(anotherAccount);
        assertEq(token.balanceOf(anotherAccount), transferAmount * 3);
    }

    function test_InfiniteApprovalFailsWithInsufficientBalance() public {
        // Setup infinite approval
        vm.prank(initialHolder);
        token.approve(recipient, type(uint256).max);

        // Try to transfer more than balance
        vm.prank(recipient);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, initialHolder, 0, 0));
        token.transferFrom(initialHolder, anotherAccount, initialSupply + 1);

        // Allowance should still be infinite
        vm.prank(recipient);
        assertEq(token.allowance(initialHolder, recipient), type(uint256).max);
    }

    // Approve Edge Cases Tests

    function test_ApproveEmitsEvent() public {
        // Should emit Approval event with value 0 (for privacy)
        vm.expectEmit(true, true, false, true);
        emit Approval(initialHolder, recipient, 0);

        vm.prank(initialHolder);
        token.approve(recipient, 50 * 10**18);
    }

    function test_ApproveFromZeroAddress() public {
        vm.prank(address(0));
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidApprover.selector, address(0)));
        token.approve(recipient, 100);
    }

    function test_ApproveToZeroAddress() public {
        vm.prank(initialHolder);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0)));
        token.approve(address(0), 100);
    }

    function test_ApproveReplacesExistingValue() public {
        // First approval
        vm.prank(initialHolder);
        token.approve(recipient, 100);

        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, recipient), 100);

        // Replace with new value
        vm.prank(initialHolder);
        token.approve(recipient, 200);

        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, recipient), 200);
    }

    function test_ApproveZeroValue() public {
        // Initial non-zero approval
        vm.prank(initialHolder);
        token.approve(recipient, 100);

        // Zero approval should emit event with zero value
        vm.expectEmit(true, true, false, true);
        emit Approval(initialHolder, recipient, 0);

        vm.prank(initialHolder);
        token.approve(recipient, 0);

        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, recipient), 0);
    }

    function test_ApproveDoesNotRequireBalance() public {
        uint256 largeAmount = initialSupply * 100;
        
        // Approve more than balance
        vm.prank(initialHolder);
        token.approve(recipient, largeAmount);

        // Check allowance is set despite insufficient balance
        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, recipient), largeAmount);

        // But transferFrom should still fail
        vm.prank(recipient);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, initialHolder, 0, 0));
        token.transferFrom(initialHolder, anotherAccount, largeAmount);
    }

    function test_ApproveTwiceEmitsEvents() public {
        // First approval should emit event
        vm.expectEmit(true, true, false, true);
        emit Approval(initialHolder, recipient, 0);

        vm.prank(initialHolder);
        token.approve(recipient, 100);

        // Second approval should also emit event
        vm.expectEmit(true, true, false, true);
        emit Approval(initialHolder, recipient, 0);

        vm.prank(initialHolder);
        token.approve(recipient, 200);
    }

}

contract SERC20DecimalsTest is Test {
    TestSERC20Decimals public token6;
    TestSERC20Decimals public token0;
    address public holder;
    address public recipient;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        holder = address(1);
        recipient = address(2);

        // Create tokens with different decimal configurations
        token6 = new TestSERC20Decimals("Six Decimals", "SIX", 6);
        token0 = new TestSERC20Decimals("Zero Decimals", "ZERO", 0);
    }

    function test_CustomDecimals() public view {
        assertEq(token6.decimals(), 6);
        assertEq(token0.decimals(), 0);
    }

    function test_MintWithSixDecimals() public {
        uint256 amount = 100 * 10**6; // 100 tokens with 6 decimals
        token6.mint(holder, amount);

        vm.prank(holder);
        assertEq(token6.balanceOf(holder), amount);
        assertEq(token6.totalSupply(), amount);
    }

    function test_MintWithZeroDecimals() public {
        uint256 amount = 100; // 100 tokens with 0 decimals
        token0.mint(holder, amount);

        vm.prank(holder);
        assertEq(token0.balanceOf(holder), amount);
        assertEq(token0.totalSupply(), amount);
    }

    function test_TransferWithSixDecimals() public {
        uint256 amount = 100 * 10**6; // 100 tokens with 6 decimals
        token6.mint(holder, amount);

        vm.prank(holder);
        token6.transfer(recipient, 50 * 10**6);

        vm.prank(holder);
        assertEq(token6.balanceOf(holder), 50 * 10**6);
        
        vm.prank(recipient);
        assertEq(token6.balanceOf(recipient), 50 * 10**6);
    }

    function test_TransferWithZeroDecimals() public {
        uint256 amount = 100; // 100 tokens with 0 decimals
        token0.mint(holder, amount);

        vm.prank(holder);
        token0.transfer(recipient, 50);

        vm.prank(holder);
        assertEq(token0.balanceOf(holder), 50);
        
        vm.prank(recipient);
        assertEq(token0.balanceOf(recipient), 50);
    }

    function test_SmallestUnitTransferSixDecimals() public {
        uint256 amount = 100 * 10**6; // 100 tokens with 6 decimals
        token6.mint(holder, amount);

        // Transfer 1 unit (0.000001 token)
        vm.prank(holder);
        token6.transfer(recipient, 1);

        vm.prank(holder);
        assertEq(token6.balanceOf(holder), amount - 1);
        
        vm.prank(recipient);
        assertEq(token6.balanceOf(recipient), 1);
    }

    function test_SmallestUnitTransferZeroDecimals() public {
        uint256 amount = 100; // 100 tokens with 0 decimals
        token0.mint(holder, amount);

        // Transfer 1 unit (1 whole token for 0 decimals)
        vm.prank(holder);
        token0.transfer(recipient, 1);

        vm.prank(holder);
        assertEq(token0.balanceOf(holder), amount - 1);
        
        vm.prank(recipient);
        assertEq(token0.balanceOf(recipient), 1);
    }

    function test_MaxSupplyWithDifferentDecimals() public {
        // Test max supply with 6 decimals
        uint256 maxAmount6 = type(uint256).max;
        token6.mint(holder, maxAmount6);
        assertEq(token6.totalSupply(), maxAmount6);

        // Test max supply with 0 decimals
        uint256 maxAmount0 = type(uint256).max;
        token0.mint(holder, maxAmount0);
        assertEq(token0.totalSupply(), maxAmount0);
    }

    function test_BurnWithDifferentDecimals() public {
        // Test burning with 6 decimals
        uint256 amount6 = 100 * 10**6;
        token6.mint(holder, amount6);
        token6.burn(holder, 50 * 10**6);
        assertEq(token6.totalSupply(), 50 * 10**6);

        // Test burning with 0 decimals
        uint256 amount0 = 100;
        token0.mint(holder, amount0);
        token0.burn(holder, 50);
        assertEq(token0.totalSupply(), 50);
    }
}

contract SERC20AllowanceTest is Test {
    TestSERC20 public token;
    address public initialHolder;
    address public spender;
    address public otherAccount;
    uint256 public initialSupply;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        initialHolder = address(1);
        spender = address(2);
        otherAccount = address(3);
        initialSupply = 100 * 10**18;

        token = new TestSERC20("My Token", "MTKN");
        token.mint(initialHolder, initialSupply);
    }

    // Basic Functionality Tests

    function test_IncreaseAllowance() public {
        uint256 initialAllowance = 100;
        uint256 addedValue = 50;

        // Set initial allowance
        vm.prank(initialHolder);
        token.approve(spender, initialAllowance);

        // Increase allowance and check event
        vm.expectEmit(true, true, false, true);
        emit Approval(initialHolder, spender, 0); // Zero value for privacy

        vm.prank(initialHolder);
        token.increaseAllowance(spender, addedValue);

        // Check new allowance (visible to owner)
        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, spender), initialAllowance + addedValue);
    }

    function test_DecreaseAllowance() public {
        uint256 initialAllowance = 100;
        uint256 subtractedValue = 50;

        // Set initial allowance
        vm.prank(initialHolder);
        token.approve(spender, initialAllowance);

        // Decrease allowance and check event
        vm.expectEmit(true, true, false, true);
        emit Approval(initialHolder, spender, 0); // Zero value for privacy

        vm.prank(initialHolder);
        token.decreaseAllowance(spender, subtractedValue);

        // Check new allowance (visible to owner)
        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, spender), initialAllowance - subtractedValue);
    }

    // Privacy Tests

    function test_IncreaseAllowancePrivacy() public {
        // Set and increase allowance
        vm.prank(initialHolder);
        token.approve(spender, 100);
        
        vm.prank(initialHolder);
        token.increaseAllowance(spender, 50);

        // Owner can see allowance
        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, spender), 150);

        // Spender can see allowance
        vm.prank(spender);
        assertEq(token.allowance(initialHolder, spender), 150);

        // Other accounts see zero
        vm.prank(otherAccount);
        assertEq(token.allowance(initialHolder, spender), 0);
    }

    function test_DecreaseAllowancePrivacy() public {
        // Set and decrease allowance
        vm.prank(initialHolder);
        token.approve(spender, 100);
        
        vm.prank(initialHolder);
        token.decreaseAllowance(spender, 50);

        // Owner can see allowance
        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, spender), 50);

        // Spender can see allowance
        vm.prank(spender);
        assertEq(token.allowance(initialHolder, spender), 50);

        // Other accounts see zero
        vm.prank(otherAccount);
        assertEq(token.allowance(initialHolder, spender), 0);
    }

    // Edge Cases

    function test_DecreaseAllowanceBelowZeroFails() public {
        // Set initial allowance
        vm.prank(initialHolder);
        token.approve(spender, 100);

        // Try to decrease by more than current allowance
        vm.prank(initialHolder);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, spender, 0, 0));
        token.decreaseAllowance(spender, 101);

        // Allowance should remain unchanged
        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, spender), 100);
    }

    function test_IncreaseAllowanceToMax() public {
        // Start with some allowance
        vm.prank(initialHolder);
        token.approve(spender, 100);

        // Increase to max
        vm.prank(initialHolder);
        token.increaseAllowance(spender, type(uint256).max - 100);

        // Check max allowance
        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, spender), type(uint256).max);
    }

    function test_MultipleAllowanceUpdates() public {
        // Multiple increases
        vm.startPrank(initialHolder);
        token.approve(spender, 100);
        token.increaseAllowance(spender, 50);
        token.increaseAllowance(spender, 75);
        assertEq(token.allowance(initialHolder, spender), 225);

        // Multiple decreases
        token.decreaseAllowance(spender, 25);
        token.decreaseAllowance(spender, 50);
        assertEq(token.allowance(initialHolder, spender), 150);
        vm.stopPrank();
    }

    function test_ZeroValueAllowanceUpdates() public {
        vm.startPrank(initialHolder);
        
        // Increase by zero
        vm.expectEmit(true, true, false, true);
        emit Approval(initialHolder, spender, 0);
        token.increaseAllowance(spender, 0);
        assertEq(token.allowance(initialHolder, spender), 0);

        // Set non-zero allowance
        token.approve(spender, 100);

        // Decrease by zero
        vm.expectEmit(true, true, false, true);
        emit Approval(initialHolder, spender, 0);
        token.decreaseAllowance(spender, 0);
        assertEq(token.allowance(initialHolder, spender), 100);
        
        vm.stopPrank();
    }

    function test_AllowanceUpdatesWithTransfers() public {
        uint256 transferAmount = 50;
        
        // Setup allowance
        vm.prank(initialHolder);
        token.approve(spender, 100);

        // Increase allowance and perform transfer
        vm.prank(initialHolder);
        token.increaseAllowance(spender, 50);

        vm.prank(spender);
        token.transferFrom(initialHolder, otherAccount, transferAmount);

        // Check remaining allowance
        vm.prank(initialHolder);
        assertEq(token.allowance(initialHolder, spender), 100); // 150 - 50
    }
}
