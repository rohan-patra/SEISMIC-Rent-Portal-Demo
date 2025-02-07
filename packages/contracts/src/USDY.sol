// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SERC20} from "./SERC20.sol";

/**
 * @title USDY - Yield-bearing USD Stablecoin with Privacy Features
 * @notice A yield-bearing stablecoin that uses shielded types for privacy protection
 * @dev Implements SERC20 for shielded balances and transfers
 */
contract USDY is SERC20 {
    // Base value for rewardMultiplier (18 decimals)
    uint256 private constant BASE = 1e18;
    
    // Current reward multiplier, represents accumulated yield
    suint256 private rewardMultiplier;

    // Access control roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // Role management
    mapping(bytes32 => mapping(address => bool)) private _roles;
    
    // Pause state
    bool private _paused;

    // Events
    event RewardMultiplierUpdated(uint256 newMultiplier);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event Paused(address account);
    event Unpaused(address account);

    // Custom errors
    error InvalidRewardMultiplier(uint256 multiplier);
    error ZeroRewardIncrement();
    error MissingRole(bytes32 role, address account);
    error TransferWhilePaused();

    /**
     * @notice Constructs the USDY contract
     * @param admin The address that will have admin rights
     */
    constructor(address admin) SERC20("USD Yield", "USDY") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        rewardMultiplier = suint256(BASE); // Initialize with 1.0 multiplier
    }

    /**
     * @notice Modifier that checks if the caller has a specific role
     */
    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, _msgSender())) {
            revert MissingRole(role, _msgSender());
        }
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract is not paused
     */
    modifier whenNotPaused() {
        if (_paused) revert TransferWhilePaused();
        _;
    }

    /**
     * @notice Returns true if `account` has been granted `role`
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    /**
     * @notice Grants `role` to `account`
     * @dev The caller must have the admin role
     */
    function grantRole(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @notice Revokes `role` from `account`
     * @dev The caller must have the admin role
     */
    function revokeRole(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @notice Internal function to grant a role to an account
     */
    function _grantRole(bytes32 role, address account) internal {
        _roles[role][account] = true;
        emit RoleGranted(role, account, _msgSender());
    }

    /**
     * @notice Internal function to revoke a role from an account
     */
    function _revokeRole(bytes32 role, address account) internal {
        _roles[role][account] = false;
        emit RoleRevoked(role, account, _msgSender());
    }

    /**
     * @notice Returns true if the contract is paused, and false otherwise
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @notice Converts an amount of tokens to shares
     * @param amount The amount of tokens to convert
     * @return The equivalent amount of shares
     */
    function convertToShares(suint256 amount) internal view returns (suint256) {
        return (amount * suint256(BASE)) / rewardMultiplier;
    }

    /**
     * @notice Converts an amount of shares to tokens
     * @param shares The amount of shares to convert
     * @return The equivalent amount of tokens
     */
    function convertToTokens(suint256 shares) internal view returns (suint256) {
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
        _mint(saddress(to), suint256(amount));
    }

    /**
     * @notice Burns tokens from an address
     * @param from The address to burn from
     * @param amount The amount to burn
     */
    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) whenNotPaused {
        _burn(saddress(from), suint256(amount));
    }

    /**
     * @notice Pauses all token transfers
     */
    function pause() external onlyRole(PAUSE_ROLE) {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @notice Unpauses all token transfers
     */
    function unpause() external onlyRole(PAUSE_ROLE) {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @notice Hook that is called before any transfer
     * @dev Adds pausable functionality to transfers
     */
    function _beforeTransfer() internal view {
        if (_paused) revert TransferWhilePaused();
    }

    /**
     * @notice Override of the transfer function to add pause functionality
     */
    function transfer(saddress to, suint256 amount) public virtual override returns (bool) {
        _beforeTransfer();
        return super.transfer(to, convertToShares(amount));
    }

    /**
     * @notice Override of the transferFrom function to add pause functionality
     */
    function transferFrom(saddress from, saddress to, suint256 amount) public virtual override returns (bool) {
        _beforeTransfer();
        return super.transferFrom(from, to, convertToShares(amount));
    }
}
