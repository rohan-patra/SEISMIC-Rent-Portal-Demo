pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {USDY} from "../../src/USDY.sol";
import {IERC20Errors} from "../../openzeppelin/interfaces/draft-IERC6093.sol";

contract USDYPauseTest is Test {
    USDY public token;
    address public admin;
    address public minter;
    address public burner;
    address public pauser;
    address public user1;
    address public user2;
    uint256 public constant BASE = 1e18;
    uint256 public constant INITIAL_MINT = 1000 * 1e18;

    event Paused(address account);
    event Unpaused(address account);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        admin = address(1);
        minter = address(2);
        burner = address(3);
        pauser = address(4);
        user1 = address(5);
        user2 = address(6);

        token = new USDY(admin);

        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.BURNER_ROLE(), burner);
        token.grantRole(token.PAUSE_ROLE(), pauser);
        vm.stopPrank();

        // Initial mint to test transfers
        vm.prank(minter);
        token.mint(saddress(user1), suint256(INITIAL_MINT));
    }

    function test_MintingWhenUnpaused() public {
        uint256 amount = 10 * 1e18;

        // Pause and then unpause
        vm.startPrank(pauser);
        token.pause();
        token.unpause();
        vm.stopPrank();

        // Should be able to mint after unpausing
        vm.prank(minter);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user2, amount);
        token.mint(saddress(user2), suint256(amount));

        // Verify mint was successful
        vm.prank(user2);
        assertEq(token.balanceOf(saddress(user2)), amount);
    }

    function test_MintingWhenPaused() public {
        uint256 amount = 10 * 1e18;

        // Pause
        vm.prank(pauser);
        token.pause();

        // Should not be able to mint while paused
        vm.prank(minter);
        vm.expectRevert(USDY.TransferWhilePaused.selector);
        token.mint(saddress(user2), suint256(amount));
    }

    function test_BurningWhenUnpaused() public {
        uint256 amount = 10 * 1e18;

        // Pause and then unpause
        vm.startPrank(pauser);
        token.pause();
        token.unpause();
        vm.stopPrank();

        // Should be able to burn after unpausing
        vm.prank(burner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, address(0), amount);
        token.burn(saddress(user1), suint256(amount));

        // Verify burn was successful
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), INITIAL_MINT - amount);
    }

    function test_BurningWhenPaused() public {
        uint256 amount = 10 * 1e18;

        // Pause
        vm.prank(pauser);
        token.pause();

        // Should not be able to burn while paused
        vm.prank(burner);
        vm.expectRevert(USDY.TransferWhilePaused.selector);
        token.burn(saddress(user1), suint256(amount));
    }

    function test_TransfersWhenUnpaused() public {
        uint256 amount = 10 * 1e18;

        // Pause and then unpause
        vm.startPrank(pauser);
        token.pause();
        token.unpause();
        vm.stopPrank();

        // Should be able to transfer after unpausing
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, user2, amount);
        token.transfer(saddress(user2), suint256(amount));

        // Verify transfer was successful
        vm.prank(user2);
        assertEq(token.balanceOf(saddress(user2)), amount);
    }

    function test_TransfersWhenPaused() public {
        uint256 amount = 10 * 1e18;

        // Pause
        vm.prank(pauser);
        token.pause();

        // Should not be able to transfer while paused
        vm.prank(user1);
        vm.expectRevert(USDY.TransferWhilePaused.selector);
        token.transfer(saddress(user2), suint256(amount));
    }

    function test_TransferFromWhenUnpaused() public {
        uint256 amount = 10 * 1e18;

        // Setup approval
        vm.prank(user1);
        token.approve(saddress(user2), suint256(amount));

        // Pause and then unpause
        vm.startPrank(pauser);
        token.pause();
        token.unpause();
        vm.stopPrank();

        // Should be able to transferFrom after unpausing
        vm.prank(user2);
        token.transferFrom(saddress(user1), saddress(user2), suint256(amount));

        // Verify transfer was successful
        vm.prank(user2);
        assertEq(token.balanceOf(saddress(user2)), amount);
    }

    function test_TransferFromWhenPaused() public {
        uint256 amount = 10 * 1e18;

        // Setup approval
        vm.prank(user1);
        token.approve(saddress(user2), suint256(amount));

        // Pause
        vm.prank(pauser);
        token.pause();

        // Should not be able to transferFrom while paused
        vm.prank(user2);
        vm.expectRevert(USDY.TransferWhilePaused.selector);
        token.transferFrom(saddress(user1), saddress(user2), suint256(amount));
    }

    function test_PauseUnpauseEvents() public {
        // Test pause event
        vm.prank(pauser);
        vm.expectEmit(true, true, true, true);
        emit Paused(pauser);
        token.pause();

        // Test unpause event
        vm.prank(pauser);
        vm.expectEmit(true, true, true, true);
        emit Unpaused(pauser);
        token.unpause();
    }

    function test_OnlyPauserCanPauseUnpause() public {
        // Non-pauser cannot pause
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(USDY.MissingRole.selector, token.PAUSE_ROLE(), user1));
        token.pause();

        // Pause with correct role
        vm.prank(pauser);
        token.pause();

        // Non-pauser cannot unpause
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(USDY.MissingRole.selector, token.PAUSE_ROLE(), user1));
        token.unpause();

        // Unpause with correct role
        vm.prank(pauser);
        token.unpause();
    }

    function test_CannotPauseWhenPaused() public {
        // Pause first time
        vm.prank(pauser);
        token.pause();

        // Try to pause again
        vm.prank(pauser);
        vm.expectRevert("Pausable: paused");
        token.pause();
    }

    function test_CannotUnpauseWhenUnpaused() public {
        // Try to unpause when not paused
        vm.prank(pauser);
        vm.expectRevert("Pausable: not paused");
        token.unpause();
    }
}

contract USDYBalanceAndSharesTest is Test {
    USDY public token;
    address public admin;
    address public minter;
    address public oracle;
    address public user1;
    address public user2;
    uint256 public constant BASE = 1e18;
    uint256 public constant INITIAL_MINT = 1000 * 1e18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event RewardMultiplierUpdated(uint256 newMultiplier);

    function setUp() public {
        admin = address(1);
        minter = address(2);
        oracle = address(3);
        user1 = address(4);
        user2 = address(5);

        token = new USDY(admin);

        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.ORACLE_ROLE(), oracle);
        vm.stopPrank();
    }

    function test_BalanceReturnsTokensNotShares() public {
        uint256 tokensAmount = 10 * 1e18;
        uint256 yieldIncrement = 0.0001e18; // 0.01% yield

        // Mint tokens first
        vm.prank(minter);
        token.mint(saddress(user1), suint256(tokensAmount));

        // Add yield
        vm.prank(oracle);
        token.addRewardMultiplier(yieldIncrement);

        // Check balance reflects tokens with yield
        vm.prank(user1);
        assertEq(
            token.balanceOf(saddress(user1)), 
            (tokensAmount * (BASE + yieldIncrement)) / BASE
        );
    }

    function test_ZeroBalanceAndSharesForNewAccounts() public {
        // Check balance
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), 0);

        // Check shares
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), 0);
    }

    function test_SharesUnchangedWithYield() public {
        uint256 sharesAmount = 1 * 1e18;

        // Mint initial shares
        vm.prank(minter);
        token.mint(saddress(user1), suint256(sharesAmount));

        // Record initial shares
        vm.prank(user1);
        uint256 initialShares = token.sharesOf(saddress(user1));

        // Add yield multiple times
        vm.startPrank(oracle);
        token.addRewardMultiplier(0.0001e18); // +0.01%
        token.addRewardMultiplier(0.0002e18); // +0.02%
        token.addRewardMultiplier(0.0003e18); // +0.03%
        vm.stopPrank();

        // Verify shares remain unchanged
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), initialShares);
    }

    function test_SharesPrivacy() public {
        uint256 amount = 100 * 1e18;

        // Mint tokens to user1
        vm.prank(minter);
        token.mint(saddress(user1), suint256(amount));

        // User1 can see their own shares
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), amount);

        // User2 cannot see user1's shares (should see 0)
        vm.prank(user2);
        assertEq(token.sharesOf(saddress(user1)), 0);
    }

    function test_SharesWithTransfers() public {
        uint256 initialAmount = 100 * 1e18;
        uint256 transferAmount = 40 * 1e18;
        uint256 yieldIncrement = 0.0001e18; // 0.01% yield

        // Mint initial tokens
        vm.prank(minter);
        token.mint(saddress(user1), suint256(initialAmount));

        // Add yield
        vm.prank(oracle);
        token.addRewardMultiplier(yieldIncrement);

        // Calculate shares for transfer
        uint256 transferShares = (transferAmount * BASE) / (BASE + yieldIncrement);

        // Transfer tokens
        vm.prank(user1);
        token.transfer(saddress(user2), suint256(transferAmount));

        // Verify shares
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), initialAmount - transferShares);
        
        vm.prank(user2);
        assertEq(token.sharesOf(saddress(user2)), transferShares);
    }

    function test_SharesWithMintingAfterYield() public {
        uint256 initialAmount = 100 * 1e18;
        uint256 mintAmount = 50 * 1e18;
        uint256 yieldIncrement = 0.0001e18; // 0.01% yield

        // Mint initial tokens
        vm.prank(minter);
        token.mint(saddress(user1), suint256(initialAmount));

        // Add yield
        vm.prank(oracle);
        token.addRewardMultiplier(yieldIncrement);

        // Mint more tokens
        vm.prank(minter);
        token.mint(saddress(user2), suint256(mintAmount));

        // Verify shares
        // User1's shares should remain unchanged
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), initialAmount);

        // User2's shares should be calculated with current yield
        vm.prank(user2);
        assertEq(token.sharesOf(saddress(user2)), (mintAmount * BASE) / (BASE + yieldIncrement));
    }

    function test_TotalShares() public {
        uint256 amount1 = 100 * 1e18;
        uint256 amount2 = 50 * 1e18;
        uint256 yieldIncrement = 0.0001e18; // 0.01% yield

        // Mint to first user
        vm.prank(minter);
        token.mint(saddress(user1), suint256(amount1));

        // Add yield
        vm.prank(oracle);
        token.addRewardMultiplier(yieldIncrement);

        // Mint to second user
        vm.prank(minter);
        token.mint(saddress(user2), suint256(amount2));

        // Calculate expected total shares
        uint256 shares1 = amount1; // First mint is 1:1
        uint256 shares2 = (amount2 * BASE) / (BASE + yieldIncrement); // Second mint accounts for yield
        uint256 expectedTotalShares = shares1 + shares2;

        // Verify total shares
        assertEq(token.totalShares(), expectedTotalShares);
    }
}

contract USDYMintTest is Test {
    USDY public token;
    address public admin;
    address public minter;
    address public oracle;
    address public user1;
    address public user2;
    uint256 public constant BASE = 1e18;
    uint256 public constant INITIAL_MINT = 1000 * 1e18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event RewardMultiplierUpdated(uint256 newMultiplier);

    function setUp() public {
        admin = address(1);
        minter = address(2);
        oracle = address(3);
        user1 = address(4);
        user2 = address(5);

        token = new USDY(admin);

        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.ORACLE_ROLE(), oracle);
        vm.stopPrank();
    }

    function test_MintIncrementsTotalShares() public {
        uint256 amount = 1 * 1e18;

        // Record initial total shares
        uint256 initialTotalShares = token.totalShares();

        // Mint tokens
        vm.prank(minter);
        token.mint(saddress(user1), suint256(amount));

        // Verify total shares increased by mint amount
        assertEq(token.totalShares(), initialTotalShares + amount);
    }

    function test_MintIncrementsTotalSupply() public {
        uint256 amount = 1 * 1e18;

        // Record initial total supply
        uint256 initialTotalSupply = token.totalSupply();

        // Mint tokens
        vm.prank(minter);
        token.mint(saddress(user1), suint256(amount));

        // Verify total supply increased by mint amount
        assertEq(token.totalSupply(), initialTotalSupply + amount);
    }

    function test_MintEmitsTransferEvent() public {
        uint256 amount = 1 * 1e18;

        // Mint should emit Transfer event from zero address
        vm.prank(minter);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user1, amount);
        token.mint(saddress(user1), suint256(amount));
    }

    function test_MintEmitsTransferEventWithTokensNotShares() public {
        uint256 amount = 1000 * 1e18;
        uint256 yieldIncrement = 0.0001e18; // 0.01% yield

        // Add yield first
        vm.prank(oracle);
        token.addRewardMultiplier(yieldIncrement);

        // Mint should emit Transfer event with token amount, not shares
        vm.prank(minter);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user1, amount);
        token.mint(saddress(user1), suint256(amount));
    }

    function test_MintSharesAssignedToCorrectAddress() public {
        uint256 amount = 1 * 1e18;

        // Mint tokens
        vm.prank(minter);
        token.mint(saddress(user1), suint256(amount));

        // Verify shares were assigned to correct address
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), amount);
    }

    function test_MintToZeroAddressReverts() public {
        uint256 amount = 1 * 1e18;

        // Attempt to mint to zero address should revert
        vm.prank(minter);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.mint(saddress(address(0)), suint256(amount));
    }

    function test_MintWithYieldCalculatesSharesCorrectly() public {
        uint256 amount = 100 * 1e18;
        uint256 yieldIncrement = 0.1e18; // 10% yield

        // Add yield first
        vm.prank(oracle);
        token.addRewardMultiplier(yieldIncrement);

        // Calculate expected shares
        uint256 expectedShares = (amount * BASE) / (BASE + yieldIncrement);

        // Mint tokens
        vm.prank(minter);
        token.mint(saddress(user1), suint256(amount));

        // Verify correct number of shares were minted
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), expectedShares);

        // Verify balance shows full token amount
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), amount);
    }

    function test_MultipleMints() public {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 * 1e18;
        amounts[1] = 50 * 1e18;
        amounts[2] = 75 * 1e18;

        uint256 totalAmount = 0;
        uint256 totalShares = 0;

        // Perform multiple mints with yield changes in between
        for(uint256 i = 0; i < amounts.length; i++) {
            if(i > 0) {
                // Add some yield before subsequent mints
                vm.prank(oracle);
                token.addRewardMultiplier(0.0001e18 * (i + 1)); // Increasing yield each time
            }

            vm.prank(minter);
            token.mint(saddress(user1), suint256(amounts[i]));

            totalAmount += amounts[i];
            totalShares += (amounts[i] * BASE) / (BASE + (0.0001e18 * i)); // Account for yield in share calculation
        }

        // Verify final balance reflects total minted amount
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), totalAmount);

        // Verify shares are calculated correctly
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), totalShares);
    }

    function test_MintPrivacy() public {
        uint256 amount = 100 * 1e18;

        // Mint tokens
        vm.prank(minter);
        token.mint(saddress(user1), suint256(amount));

        // Recipient can see their balance
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), amount);

        // Other users cannot see the balance
        vm.prank(user2);
        assertEq(token.balanceOf(saddress(user1)), 0);
    }

    function test_OnlyMinterCanMint() public {
        uint256 amount = 100 * 1e18;

        // Non-minter cannot mint
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(USDY.MissingRole.selector, token.MINTER_ROLE(), user1));
        token.mint(saddress(user2), suint256(amount));

        // Minter can mint
        vm.prank(minter);
        token.mint(saddress(user2), suint256(amount));

        // Verify mint was successful
        vm.prank(user2);
        assertEq(token.balanceOf(saddress(user2)), amount);
    }

    function test_MintZeroAmount() public {
        // Minting zero amount should succeed but not change state
        vm.prank(minter);
        token.mint(saddress(user1), suint256(0));

        // Verify no shares or balance were assigned
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), 0);
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), 0);
    }
}

contract USDYBurnTest is Test {
    USDY public token;
    address public admin;
    address public minter;
    address public burner;
    address public oracle;
    address public user1;
    address public user2;
    uint256 public constant BASE = 1e18;
    uint256 public constant INITIAL_MINT = 1000 * 1e18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event RewardMultiplierUpdated(uint256 newMultiplier);

    function setUp() public {
        admin = address(1);
        minter = address(2);
        burner = address(3);
        oracle = address(4);
        user1 = address(5);
        user2 = address(6);

        token = new USDY(admin);

        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.BURNER_ROLE(), burner);
        token.grantRole(token.ORACLE_ROLE(), oracle);
        vm.stopPrank();

        // Initial mint for testing burns
        vm.prank(minter);
        token.mint(saddress(user1), suint256(INITIAL_MINT));
    }

    function test_BurnDecrementsAccountShares() public {
        uint256 burnAmount = 1 * 1e18;

        // Record initial shares
        vm.prank(user1);
        uint256 initialShares = token.sharesOf(saddress(user1));

        // Burn tokens
        vm.prank(burner);
        token.burn(saddress(user1), suint256(burnAmount));

        // Verify shares were reduced
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), initialShares - burnAmount);
    }

    function test_BurnDecrementsTotalShares() public {
        uint256 burnAmount = 1 * 1e18;

        // Record initial total shares
        uint256 initialTotalShares = token.totalShares();

        // Burn tokens
        vm.prank(burner);
        token.burn(saddress(user1), suint256(burnAmount));

        // Verify total shares were reduced
        assertEq(token.totalShares(), initialTotalShares - burnAmount);
    }

    function test_BurnFromZeroAddressReverts() public {
        uint256 burnAmount = 1 * 1e18;

        // Attempt to burn from zero address should revert
        vm.prank(burner);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSender.selector, address(0)));
        token.burn(saddress(address(0)), suint256(burnAmount));
    }

    function test_BurnExceedingBalanceReverts() public {
        // Get current balance
        vm.prank(user1);
        uint256 balance = token.balanceOf(saddress(user1));
        uint256 burnAmount = balance + 1;

        // Attempt to burn more than balance should revert
        vm.prank(burner);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, user1, balance, burnAmount));
        token.burn(saddress(user1), suint256(burnAmount));
    }

    function test_BurnEmitsTransferEvent() public {
        uint256 burnAmount = 1 * 1e18;

        // Burn should emit Transfer event to zero address
        vm.prank(burner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, address(0), burnAmount);
        token.burn(saddress(user1), suint256(burnAmount));
    }

    function test_BurnEmitsTransferEventWithTokensNotShares() public {
        uint256 burnAmount = 1000 * 1e18;
        uint256 yieldIncrement = 0.0001e18; // 0.01% yield

        // Add yield first
        vm.prank(oracle);
        token.addRewardMultiplier(yieldIncrement);

        // Burn should emit Transfer event with token amount, not shares
        vm.prank(burner);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, address(0), burnAmount);
        token.burn(saddress(user1), suint256(burnAmount));
    }

    function test_BurnWithYieldCalculatesSharesCorrectly() public {
        uint256 burnAmount = 100 * 1e18;
        uint256 yieldIncrement = 0.1e18; // 10% yield

        // Add yield first
        vm.prank(oracle);
        token.addRewardMultiplier(yieldIncrement);

        // Calculate expected shares to burn
        uint256 sharesToBurn = (burnAmount * BASE) / (BASE + yieldIncrement);

        // Record initial shares
        vm.prank(user1);
        uint256 initialShares = token.sharesOf(saddress(user1));

        // Burn tokens
        vm.prank(burner);
        token.burn(saddress(user1), suint256(burnAmount));

        // Verify correct number of shares were burned
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), initialShares - sharesToBurn);
    }

    function test_MultipleBurns() public {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 * 1e18;
        amounts[1] = 50 * 1e18;
        amounts[2] = 75 * 1e18;

        uint256 totalBurned = 0;
        uint256 totalSharesBurned = 0;

        // Perform multiple burns with yield changes in between
        for(uint256 i = 0; i < amounts.length; i++) {
            if(i > 0) {
                // Add some yield before subsequent burns
                vm.prank(oracle);
                token.addRewardMultiplier(0.0001e18 * (i + 1)); // Increasing yield each time
            }

            vm.prank(burner);
            token.burn(saddress(user1), suint256(amounts[i]));

            totalBurned += amounts[i];
            totalSharesBurned += (amounts[i] * BASE) / (BASE + (0.0001e18 * i)); // Account for yield in share calculation
        }

        // Verify final balance is reduced correctly
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), INITIAL_MINT - totalBurned);

        // Verify shares are reduced correctly
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), INITIAL_MINT - totalSharesBurned);
    }

    function test_BurnPrivacy() public {
        uint256 burnAmount = 100 * 1e18;

        // Record initial balance (only visible to owner)
        vm.prank(user1);
        uint256 initialBalance = token.balanceOf(saddress(user1));

        // Burn tokens
        vm.prank(burner);
        token.burn(saddress(user1), suint256(burnAmount));

        // Owner can see reduced balance
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), initialBalance - burnAmount);

        // Other users still see zero
        vm.prank(user2);
        assertEq(token.balanceOf(saddress(user1)), 0);
    }

    function test_OnlyBurnerCanBurn() public {
        uint256 burnAmount = 100 * 1e18;

        // Non-burner cannot burn
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(USDY.MissingRole.selector, token.BURNER_ROLE(), user2));
        token.burn(saddress(user1), suint256(burnAmount));

        // Burner can burn
        vm.prank(burner);
        token.burn(saddress(user1), suint256(burnAmount));

        // Verify burn was successful
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), INITIAL_MINT - burnAmount);
    }

    function test_BurnZeroAmount() public {
        // Record initial state
        vm.prank(user1);
        uint256 initialShares = token.sharesOf(saddress(user1));
        uint256 initialBalance = token.balanceOf(saddress(user1));

        // Burning zero amount should succeed but not change state
        vm.prank(burner);
        token.burn(saddress(user1), suint256(0));

        // Verify no changes to shares or balance
        vm.prank(user1);
        assertEq(token.sharesOf(saddress(user1)), initialShares);
        vm.prank(user1);
        assertEq(token.balanceOf(saddress(user1)), initialBalance);
    }
}

contract USDYApproveTest is Test {
    USDY public token;
    address public admin;
    address public minter;
    address public owner;
    address public spender;
    address public observer;
    address public recipient;
    address public oracle;
    uint256 public constant BASE = 1e18;
    uint256 public constant INITIAL_MINT = 1000 * 1e18;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        admin = address(1);
        minter = address(2);
        owner = address(3);
        spender = address(4);
        observer = address(5);
        recipient = address(6);
        oracle = address(7);
        token = new USDY(admin);

        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), minter);
        vm.stopPrank();

        // Initial mint for testing approvals
        vm.prank(minter);
        token.mint(saddress(owner), suint256(INITIAL_MINT));
    }

    function test_ApproveFromZeroAddressReverts() public {
        uint256 amount = 1 * 1e18;

        // Try to approve from zero address
        vm.prank(address(0));
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidApprover.selector, address(0)));
        token.approve(saddress(spender), suint256(amount));
    }

    function test_ApproveToZeroAddressReverts() public {
        uint256 amount = 1 * 1e18;

        // Try to approve to zero address
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0)));
        token.approve(saddress(address(0)), suint256(amount));
    }

    function test_ApproveEmitsEvent() public {
        uint256 amount = 1 * 1e18;

        // Approve should emit Approval event
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        token.approve(saddress(spender), suint256(amount));
    }

    function test_ApproveAmount() public {
        uint256 amount = 1 * 1e18;

        // Approve amount
        vm.prank(owner);
        token.approve(saddress(spender), suint256(amount));

        // Check allowance (from owner's view)
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount);

        // Check allowance (from spender's view)
        vm.prank(spender);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount);
    }

    function test_ApproveReplacePreviousAmount() public {
        uint256 amount = 1 * 1e18;

        // First approval
        vm.prank(owner);
        token.approve(saddress(spender), suint256(amount + 1));

        // Replace with new amount
        vm.prank(owner);
        token.approve(saddress(spender), suint256(amount));

        // Check new allowance
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount);
    }

    function test_ApprovePrivacy() public {
        uint256 amount = 1 * 1e18;

        // Set approval
        vm.prank(owner);
        token.approve(saddress(spender), suint256(amount));

        // Owner can see allowance
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount);

        // Spender can see allowance
        vm.prank(spender);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount);

        // Other accounts cannot see allowance
        vm.prank(observer);
        assertEq(token.allowance(saddress(owner), saddress(spender)), 0);
    }

    function test_ApproveZeroAmount() public {
        uint256 amount = 1 * 1e18;

        // Initial non-zero approval
        vm.prank(owner);
        token.approve(saddress(spender), suint256(amount));

        // Approve zero amount
        vm.prank(owner);
        token.approve(saddress(spender), suint256(0));

        // Check allowance is zero
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), 0);
    }

    function test_ApproveDoesNotRequireBalance() public {
        uint256 largeAmount = INITIAL_MINT * 2;

        // Approve more than balance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(largeAmount));

        // Check allowance is set despite insufficient balance
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), largeAmount);
    }

    function test_ApproveTwiceEmitsEvents() public {
        uint256 amount1 = 100 * 1e18;
        uint256 amount2 = 200 * 1e18;

        // First approval should emit event
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount1);
        token.approve(saddress(spender), suint256(amount1));

        // Second approval should also emit event
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount2);
        token.approve(saddress(spender), suint256(amount2));
    }

    function test_ApproveMultipleSpenders() public {
        address spender2 = address(6);
        uint256 amount1 = 100 * 1e18;
        uint256 amount2 = 200 * 1e18;

        // Approve different amounts to different spenders
        vm.startPrank(owner);
        token.approve(saddress(spender), suint256(amount1));
        token.approve(saddress(spender2), suint256(amount2));
        vm.stopPrank();

        // Check allowances are set correctly
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount1);
        assertEq(token.allowance(saddress(owner), saddress(spender2)), amount2);
    }

    function test_ApproveMaxUint() public {
        uint256 maxAmount = type(uint256).max;

        // Approve max uint256
        vm.prank(owner);
        token.approve(saddress(spender), suint256(maxAmount));

        // Check allowance is set to max
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), maxAmount);
    }

    function test_ApproveAllowanceIndependentOfBalance() public {
        uint256 amount = 100 * 1e18;

        // Approve amount
        vm.prank(owner);
        token.approve(saddress(spender), suint256(amount));

        // Burn all tokens (should not affect allowance)
        vm.prank(admin);
        token.grantRole(token.BURNER_ROLE(), admin);
        vm.prank(admin);
        token.burn(saddress(owner), suint256(INITIAL_MINT));

        // Check allowance remains unchanged
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount);
    }

    // Transfer From Tests

    function test_TransferFromWithInfiniteAllowance() public {
        uint256 transferAmount = 1 * 1e18;

        // Set infinite allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(type(uint256).max));

        // Record initial allowance
        vm.prank(owner);
        uint256 initialAllowance = token.allowance(saddress(owner), saddress(spender));

        // Transfer should not emit Approval event since allowance is infinite
        vm.prank(spender);
        token.transferFrom(saddress(owner), saddress(recipient), suint256(transferAmount));

        // Verify allowance remains infinite
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), initialAllowance);
    }

    function test_TransferFromWithSufficientAllowance() public {
        uint256 transferAmount = 1 * 1e18;

        // Set allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(transferAmount));

        // Record initial balances
        vm.prank(owner);
        uint256 initialOwnerBalance = token.balanceOf(saddress(owner));
        vm.prank(recipient);
        uint256 initialRecipientBalance = token.balanceOf(saddress(recipient));

        // Transfer
        vm.prank(spender);
        token.transferFrom(saddress(owner), saddress(recipient), suint256(transferAmount));

        // Verify balances
        vm.prank(owner);
        assertEq(token.balanceOf(saddress(owner)), initialOwnerBalance - transferAmount);
        vm.prank(recipient);
        assertEq(token.balanceOf(saddress(recipient)), initialRecipientBalance + transferAmount);
    }

    function test_TransferFromDecreasesAllowance() public {
        uint256 initialAllowance = 2 * 1e18;
        uint256 transferAmount = 1 * 1e18;

        // Set allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(initialAllowance));

        // Transfer
        vm.prank(spender);
        token.transferFrom(saddress(owner), saddress(recipient), suint256(transferAmount));

        // Verify allowance decreased
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), initialAllowance - transferAmount);
    }

    function test_TransferFromRevertsWithInsufficientAllowance() public {
        uint256 allowance = 1 * 1e18;
        uint256 transferAmount = 2 * 1e18;

        // Set allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(allowance));

        // Attempt transfer with insufficient allowance
        vm.prank(spender);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, spender, allowance, transferAmount));
        token.transferFrom(saddress(owner), saddress(recipient), suint256(transferAmount));
    }

    function test_TransferFromEmitsTransferEvent() public {
        uint256 transferAmount = 1 * 1e18;

        // Set allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(transferAmount));

        // Transfer should emit Transfer event
        vm.prank(spender);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, recipient, transferAmount);
        token.transferFrom(saddress(owner), saddress(recipient), suint256(transferAmount));
    }

    function test_TransferFromRevertsWithInsufficientBalance() public {
        uint256 excessAmount = INITIAL_MINT + 1;

        // Set high allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(excessAmount));

        // Attempt transfer with insufficient balance
        vm.prank(spender);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, owner, INITIAL_MINT, excessAmount));
        token.transferFrom(saddress(owner), saddress(recipient), suint256(excessAmount));
    }

    function test_TransferFromWithYieldDecreasesAllowanceByTokens() public {
        uint256 transferAmount = 100 * 1e18;
        uint256 yieldIncrement = 0.0004e18; // 4 bps

        // Set allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(transferAmount));

        // Add yield
        vm.prank(oracle);
        token.addRewardMultiplier(yieldIncrement);

        // Transfer
        vm.prank(spender);
        token.transferFrom(saddress(owner), saddress(recipient), suint256(transferAmount));

        // Verify allowance is reduced by token amount, not shares
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), 0);
    }

    function test_TransferFromPrivacy() public {
        uint256 transferAmount = 1 * 1e18;

        // Set allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(transferAmount));

        // Transfer
        vm.prank(spender);
        token.transferFrom(saddress(owner), saddress(recipient), suint256(transferAmount));

        // Owner can see their reduced balance
        vm.prank(owner);
        assertEq(token.balanceOf(saddress(owner)), INITIAL_MINT - transferAmount);

        // Recipient can see their increased balance
        vm.prank(recipient);
        assertEq(token.balanceOf(saddress(recipient)), transferAmount);

        // Other accounts cannot see balances
        vm.prank(observer);
        assertEq(token.balanceOf(saddress(owner)), 0);
        assertEq(token.balanceOf(saddress(recipient)), 0);
    }

    function test_TransferFromZeroAmount() public {
        // Set allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(1));

        // Record initial state
        vm.prank(owner);
        uint256 initialOwnerBalance = token.balanceOf(saddress(owner));
        uint256 initialAllowance = token.allowance(saddress(owner), saddress(spender));

        // Transfer zero amount
        vm.prank(spender);
        token.transferFrom(saddress(owner), saddress(recipient), suint256(0));

        // Verify state remains unchanged
        vm.prank(owner);
        assertEq(token.balanceOf(saddress(owner)), initialOwnerBalance);
        assertEq(token.allowance(saddress(owner), saddress(spender)), initialAllowance);
    }

    function test_IncreaseAllowanceAmount() public {
        uint256 amount = 100 * 1e18;

        // Increase allowance
        vm.prank(owner);
        token.increaseAllowance(saddress(spender), suint256(amount));

        // Check allowance is set correctly
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount);

        // Spender can also see allowance
        vm.prank(spender);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount);
    }

    function test_IncreaseAllowanceAddsToExisting() public {
        uint256 amount = 100 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(amount));

        // Increase allowance
        vm.prank(owner);
        token.increaseAllowance(saddress(spender), suint256(amount));

        // Check allowance is increased correctly
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount * 2);
    }

    function test_IncreaseAllowanceEmitsEvent() public {
        uint256 amount = 100 * 1e18;

        // Increase allowance should emit Approval event
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, amount);
        token.increaseAllowance(saddress(spender), suint256(amount));
    }

    function test_IncreaseAllowanceToZeroAddressReverts() public {
        uint256 amount = 100 * 1e18;

        // Try to increase allowance for zero address
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0)));
        token.increaseAllowance(saddress(address(0)), suint256(amount));
    }

    function test_IncreaseAllowancePrivacy() public {
        uint256 amount = 100 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(amount));

        // Increase allowance
        vm.prank(owner);
        token.increaseAllowance(saddress(spender), suint256(amount));

        // Owner can see allowance
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount * 2);

        // Spender can see allowance
        vm.prank(spender);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount * 2);

        // Other accounts cannot see allowance
        address otherUser = address(99);
        vm.prank(otherUser);
        assertEq(token.allowance(saddress(owner), saddress(spender)), 0);
    }

    function test_IncreaseAllowanceWithZeroValue() public {
        uint256 initialAmount = 100 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(initialAmount));

        // Increase by zero
        vm.prank(owner);
        token.increaseAllowance(saddress(spender), suint256(0));

        // Check allowance remains unchanged
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), initialAmount);
    }

    function test_IncreaseAllowanceMultipleTimes() public {
        uint256 amount = 100 * 1e18;

        // Multiple increases
        vm.startPrank(owner);
        token.increaseAllowance(saddress(spender), suint256(amount));
        token.increaseAllowance(saddress(spender), suint256(amount / 2));
        token.increaseAllowance(saddress(spender), suint256(amount / 4));
        vm.stopPrank();

        // Check final allowance
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), amount + (amount / 2) + (amount / 4));
    }

    function test_IncreaseAllowanceAfterSpending() public {
        uint256 amount = 100 * 1e18;
        uint256 spendAmount = 40 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(amount));

        // Spend some of the allowance
        vm.prank(spender);
        token.transferFrom(saddress(owner), saddress(recipient), suint256(spendAmount));

        // Increase allowance
        vm.prank(owner);
        token.increaseAllowance(saddress(spender), suint256(amount));

        // Check new allowance
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), (amount - spendAmount) + amount);
    }

    function test_DecreaseAllowanceRevertsWithoutApproval() public {
        uint256 amount = 1 * 1e18;

        // Try to decrease allowance without prior approval
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, spender, 0, amount));
        token.decreaseAllowance(saddress(spender), suint256(amount));
    }

    function test_DecreaseAllowanceSubtractsAmount() public {
        uint256 initialAmount = 2 * 1e18;
        uint256 decreaseAmount = 1 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(initialAmount));

        // Decrease allowance
        vm.prank(owner);
        token.decreaseAllowance(saddress(spender), suint256(decreaseAmount));

        // Check new allowance
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), initialAmount - decreaseAmount);
    }

    function test_DecreaseAllowanceToZero() public {
        uint256 amount = 1 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(amount));

        // Decrease entire allowance
        vm.prank(owner);
        token.decreaseAllowance(saddress(spender), suint256(amount));

        // Check allowance is zero
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), 0);
    }

    function test_DecreaseAllowanceRevertsWhenExceedingAllowance() public {
        uint256 initialAmount = 1 * 1e18;
        uint256 decreaseAmount = 2 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(initialAmount));

        // Try to decrease by more than allowed
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, spender, initialAmount, decreaseAmount));
        token.decreaseAllowance(saddress(spender), suint256(decreaseAmount));
    }

    function test_DecreaseAllowanceEmitsEvent() public {
        uint256 initialAmount = 2 * 1e18;
        uint256 decreaseAmount = 1 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(initialAmount));

        // Decrease allowance should emit Approval event
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, spender, initialAmount - decreaseAmount);
        token.decreaseAllowance(saddress(spender), suint256(decreaseAmount));
    }

    function test_DecreaseAllowancePrivacy() public {
        uint256 initialAmount = 100 * 1e18;
        uint256 decreaseAmount = 40 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(initialAmount));

        // Decrease allowance
        vm.prank(owner);
        token.decreaseAllowance(saddress(spender), suint256(decreaseAmount));

        // Owner can see decreased allowance
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), initialAmount - decreaseAmount);

        // Spender can see decreased allowance
        vm.prank(spender);
        assertEq(token.allowance(saddress(owner), saddress(spender)), initialAmount - decreaseAmount);

        // Other accounts cannot see allowance
        vm.prank(observer);
        assertEq(token.allowance(saddress(owner), saddress(spender)), 0);
    }

    function test_DecreaseAllowanceWithZeroValue() public {
        uint256 initialAmount = 100 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(initialAmount));

        // Decrease by zero
        vm.prank(owner);
        token.decreaseAllowance(saddress(spender), suint256(0));

        // Check allowance remains unchanged
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), initialAmount);
    }

    function test_DecreaseAllowanceMultipleTimes() public {
        uint256 initialAmount = 100 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(initialAmount));

        // Multiple decreases
        vm.startPrank(owner);
        token.decreaseAllowance(saddress(spender), suint256(20 * 1e18));
        token.decreaseAllowance(saddress(spender), suint256(30 * 1e18));
        token.decreaseAllowance(saddress(spender), suint256(10 * 1e18));
        vm.stopPrank();

        // Check final allowance
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), 40 * 1e18);
    }

    function test_DecreaseAllowanceAfterSpending() public {
        uint256 initialAmount = 100 * 1e18;
        uint256 spendAmount = 40 * 1e18;
        uint256 decreaseAmount = 30 * 1e18;

        // Set initial allowance
        vm.prank(owner);
        token.approve(saddress(spender), suint256(initialAmount));

        // Spend some of the allowance
        vm.prank(spender);
        token.transferFrom(saddress(owner), saddress(recipient), suint256(spendAmount));

        // Decrease allowance
        vm.prank(owner);
        token.decreaseAllowance(saddress(spender), suint256(decreaseAmount));

        // Check new allowance
        vm.prank(owner);
        assertEq(token.allowance(saddress(owner), saddress(spender)), initialAmount - spendAmount - decreaseAmount);
    }
}
