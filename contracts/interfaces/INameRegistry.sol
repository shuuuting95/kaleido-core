// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @title INameRegistry - saves a set of addresses used in the system.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface INameRegistry {
	/// @dev Sets the address associated with the key name.
	///      If the address is the contract, not an EOA, it is
	///      saved as the allowed contract list.
	/// @param key bytes32 of the key
	/// @param value address of the value
	function set(bytes32 key, address value) external;

	/// @dev Gets the address associated with the key name.
	/// @param key bytes32 of the key
	function get(bytes32 key) external view returns (address);

	/// @dev Returns whether or not the address is the one that we deployed.
	/// @param caller address of the msg.sender
	function allowedContracts(address caller) external returns (bool);

	/// @dev Gets the deployer of NameRegistry.
	function deployer() external view returns (address);
}
