// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import {Test, console, stdError} from "forge-std/Test.sol";
import {USDY} from "../src/USDY.sol";
import {IERC20Errors} from "../openzeppelin/interfaces/draft-IERC6093.sol";

contract USDYTest is Test {
    USDY public token;
    address public admin;
    address public minter;
    address public burner;
    address public oracle;
    address public pauser;
    address public user1;
    address public user2;

    uint256 public constant BASE = 1e18;
    uint256 public constant INITIAL_MINT = 1000 * 1e18;

    event RewardMultiplierUpdated(uint256 newMultiplier);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event Paused(address account);
    event Unpaused(address account);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        admin = address(1);
        minter = address(2);
        burner = address(3);
        oracle = address(4);
        pauser = address(5);
        user1 = address(6);
        user2 = address(7);

        // Deploy with admin
        token = new USDY(admin);

        // Setup roles
        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.BURNER_ROLE(), burner);
        token.grantRole(token.ORACLE_ROLE(), oracle);
        token.grantRole(token.PAUSE_ROLE(), pauser);
        vm.stopPrank();

        // Initial mint
        vm.prank(minter);
        token.mint(user1, INITIAL_MINT);
    }

    // Basic Functionality Tests

    function test_Metadata() public view {
        assertEq(token.name(), "USD Yield");
        assertEq(token.symbol(), "USDY");
        assertEq(token.decimals(), 18);
    }

    function test_InitialState() public {
        assertEq(token.totalSupply(), INITIAL_MINT);
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), INITIAL_MINT);
    }

    // Role Management Tests

    function test_RoleManagement() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(token.MINTER_ROLE(), minter));
        assertTrue(token.hasRole(token.BURNER_ROLE(), burner));
        assertTrue(token.hasRole(token.ORACLE_ROLE(), oracle));
        assertTrue(token.hasRole(token.PAUSE_ROLE(), pauser));
    }

    function test_RoleGrantRevoke() public {
        address newMinter = address(10);
        
        vm.startPrank(admin);
        
        // Grant role
        vm.expectEmit(true, true, true, true);
        emit RoleGranted(token.MINTER_ROLE(), newMinter, admin);
        token.grantRole(token.MINTER_ROLE(), newMinter);
        assertTrue(token.hasRole(token.MINTER_ROLE(), newMinter));

        // Revoke role
        vm.expectEmit(true, true, true, true);
        emit RoleRevoked(token.MINTER_ROLE(), newMinter, admin);
        token.revokeRole(token.MINTER_ROLE(), newMinter);
        assertFalse(token.hasRole(token.MINTER_ROLE(), newMinter));
        
        vm.stopPrank();
    }

    function test_OnlyAdminCanGrantRoles() public {
        address caller = user1;
        
        // Verify precondition: caller should not have admin role
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), caller));
        
        // First set up who will make the call
        vm.prank(caller);
        // Then expect the revert and make the call
        vm.expectRevert(abi.encodeWithSelector(USDY.MissingRole.selector, token.DEFAULT_ADMIN_ROLE(), caller));
        token.grantRole(token.MINTER_ROLE(), user2);
    }

    // Minting and Burning Tests

    function test_Minting() public {
        uint256 mintAmount = 100 * 1e18;
        uint256 initialSupply = token.totalSupply();
        
        vm.prank(minter);
        token.mint(user2, mintAmount);

        assertEq(token.totalSupply(), initialSupply + mintAmount);
        vm.prank(user2);
        assertEq(token.balanceOf(saddress(user2)), mintAmount);
    }

    function test_OnlyMinterCanMint() public {
        address caller = user1;
        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(USDY.MissingRole.selector, token.MINTER_ROLE(), caller));
        token.mint(user2, 100 * 1e18);
    }

    function test_Burning() public {
        uint256 burnAmount = 100 * 1e18;
        uint256 initialSupply = token.totalSupply();
        
        vm.prank(burner);
        token.burn(user1, burnAmount);

        assertEq(token.totalSupply(), initialSupply - burnAmount);
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), INITIAL_MINT - burnAmount);
    }

    function test_OnlyBurnerCanBurn() public {
        address caller = user1;
        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(USDY.MissingRole.selector, token.BURNER_ROLE(), caller));
        token.burn(user1, 100 * 1e18);
    }

    // Yield/Reward Multiplier Tests

    function test_InitialRewardMultiplier() public {
        // Transfer to check initial yield behavior
        uint256 transferAmount = 100 * 1e18;
        vm.prank(user1);
        token.transfer(saddress(user2), suint256(transferAmount));

        // Check balances reflect 1:1 ratio initially
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), INITIAL_MINT - transferAmount);
        vm.prank(user2);
        assertEq(token.balanceOf(saddress(user2)), transferAmount);
    }

    function test_RewardMultiplierUpdate() public {
        uint256 increment = 0.1e18; // 10% increase
        
        vm.prank(oracle);
        vm.expectEmit(true, true, true, true);
        emit RewardMultiplierUpdated(BASE + increment);
        token.addRewardMultiplier(increment);

        // Transfer after yield increase
        uint256 transferAmount = 100 * 1e18;
        
        vm.prank(user1);
        token.transfer(saddress(user2), suint256(transferAmount));

        // Check balances
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), INITIAL_MINT - transferAmount);
        vm.prank(user2);
        assertEq(token.balanceOf(saddress(user2)), (transferAmount * BASE) / (BASE + increment));
    }

    function test_OnlyOracleCanUpdateRewardMultiplier() public {
        address caller = user1;
        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(USDY.MissingRole.selector, token.ORACLE_ROLE(), caller));
        token.addRewardMultiplier(0.1e18);
    }

    function test_CannotSetZeroRewardIncrement() public {
        vm.prank(oracle);
        vm.expectRevert(USDY.ZeroRewardIncrement.selector);
        token.addRewardMultiplier(0);
    }

    function test_RewardMultiplierOverflow() public {
        vm.prank(oracle);
        vm.expectRevert(stdError.arithmeticError);
        token.addRewardMultiplier(type(uint256).max);
    }

    // Pause Functionality Tests

    function test_Pause() public {
        vm.prank(pauser);
        token.pause();
        assertTrue(token.paused());

        // Transfers should fail while paused
        vm.prank(user1);
        vm.expectRevert(USDY.TransferWhilePaused.selector);
        token.transfer(saddress(user2), suint256(100 * 1e18));
    }

    function test_Unpause() public {
        // Pause first
        vm.prank(pauser);
        token.pause();
        
        // Then unpause
        vm.prank(pauser);
        token.unpause();
        assertFalse(token.paused());

        // Transfers should work again
        uint256 transferAmount = 100 * 1e18;
        vm.prank(user1);
        token.transfer(saddress(user2), suint256(transferAmount));
        
        vm.prank(user2);
        assertEq(token.balanceOf(saddress(user2)), transferAmount);
    }

    function test_OnlyPauserCanPauseUnpause() public {
        address caller = user1;
        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(USDY.MissingRole.selector, token.PAUSE_ROLE(), caller));
        token.pause();
    }

    // Privacy Tests

    function test_BalancePrivacy() public {
        // Other users can't see balance
        assertEq(token.balanceOf(saddress(user1)), 0);
        
        // Owner can see their balance
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), INITIAL_MINT);
    }

    function test_TransferPrivacy() public {
        uint256 transferAmount = 100 * 1e18;
        
        // Transfer should emit event with zero value
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, address(0), 0);
        token.transfer(saddress(user2), suint256(transferAmount));
    }

    // Combined Functionality Tests

    function test_PausedMintingAndBurning() public {
        vm.prank(pauser);
        token.pause();

        vm.prank(minter);
        vm.expectRevert(USDY.TransferWhilePaused.selector);
        token.mint(user2, 100 * 1e18);

        vm.prank(burner);
        vm.expectRevert(USDY.TransferWhilePaused.selector);
        token.burn(user1, 100 * 1e18);
    }

    function test_YieldAccumulationWithTransfers() public {
        // Add yield
        vm.prank(oracle);
        token.addRewardMultiplier(0.1e18); // 10% increase

        // Perform multiple transfers
        uint256 transferAmount = 100 * 1e18;
        uint256 expectedShares = (transferAmount * BASE) / (BASE + 0.1e18);
        
        vm.startPrank(user1);
        token.transfer(saddress(user2), suint256(transferAmount));
        token.transfer(saddress(user2), suint256(transferAmount));
        vm.stopPrank();

        // Check final balances
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), INITIAL_MINT - (2 * transferAmount));
        vm.prank(user2);
        assertEq(token.balanceOf(saddress(user2)), 2 * expectedShares);
    }
}
