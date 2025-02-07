// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SERC20} from "./SERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title USDY - Yield-bearing USD Stablecoin with Privacy Features
 * @notice A yield-bearing stablecoin that uses shielded types for privacy protection
 * @dev Implements SERC20 for shielded balances and transfers
 */
contract USDY is SERC20, UUPSUpgradeable, PausableUpgradeable, AccessControlUpgradeable {
    // Base value for rewardMultiplier (18 decimals)
    uint256 private constant BASE = 1e18;
    
    // Current reward multiplier, represents accumulated yield
    suint256 private rewardMultiplier;

    // Access control roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");

    // Events
    event RewardMultiplierUpdated(uint256 newMultiplier);

    // Custom errors
    error InvalidRewardMultiplier(uint256 multiplier);
    error ZeroRewardIncrement();

    /**
     * @notice Initializes the USDY contract
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param admin The address that will have admin rights
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address admin
    ) external initializer {
        __SERC20_init(name_, symbol_);
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        rewardMultiplier = suint256(BASE); // Initialize with 1.0 multiplier
    }

    /**
     * @notice Converts an amount of tokens to shares
     * @param amount The amount of tokens to convert
     * @return The equivalent amount of shares
     */
    function convertToShares(suint256 amount) public view returns (suint256) {
        return (amount * suint256(BASE)) / rewardMultiplier;
    }

    /**
     * @notice Converts an amount of shares to tokens
     * @param shares The amount of shares to convert
     * @return The equivalent amount of tokens
     */
    function convertToTokens(suint256 shares) public view returns (suint256) {
        return (shares * rewardMultiplier) / suint256(BASE);
    }

    /**
     * @notice Updates the reward multiplier to reflect new yield
     * @param increment The amount to increase the multiplier by
     */
    function addRewardMultiplier(uint256 increment) external onlyRole(ORACLE_ROLE) {
        if (increment == 0) revert ZeroRewardIncrement();
        
        suint256 newMultiplier = rewardMultiplier + suint256(increment);
        _setRewardMultiplier(newMultiplier);
    }

    /**
     * @notice Sets a new reward multiplier
     * @param newMultiplier The new multiplier value
     */
    function _setRewardMultiplier(suint256 newMultiplier) private {
        if (newMultiplier < suint256(BASE)) {
            revert InvalidRewardMultiplier(uint256(newMultiplier));
        }

        rewardMultiplier = newMultiplier;
        emit RewardMultiplierUpdated(uint256(newMultiplier));
    }

    /**
     * @notice Mints new tokens to an address
     * @param to The address to mint to
     * @param amount The amount to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from an address
     * @param from The address to burn from
     * @param amount The amount to burn
     */
    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) whenNotPaused {
        _burn(from, amount);
    }

    /**
     * @notice Pauses all token transfers
     */
    function pause() external onlyRole(PAUSE_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers
     */
    function unpause() external onlyRole(PAUSE_ROLE) {
        _unpause();
    }

    /**
     * @notice Hook that is called before any transfer of tokens
     * @dev Adds pausable functionality to transfers
     */
    function _beforeTokenTransfer(
        saddress from,
        saddress to,
        suint256 amount
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract
     */
    function _authorizeUpgrade(address) internal override onlyRole(UPGRADE_ROLE) {}

    /**
     * @notice Hook that is called after any transfer of tokens
     * @dev Converts shares to tokens based on current reward multiplier
     */
    function _update(
        saddress from,
        saddress to,
        suint256 value
    ) internal virtual override {
        if (from == saddress(address(0))) {
            // Minting: Convert tokens to shares
            suint256 shares = convertToShares(value);
            super._update(from, to, shares);
        } else if (to == saddress(address(0))) {
            // Burning: Convert shares to tokens
            suint256 shares = convertToShares(value);
            super._update(from, to, shares);
        } else {
            // Transfer: Convert tokens to shares for transfer
            suint256 shares = convertToShares(value);
            super._update(from, to, shares);
        }
    }
}
