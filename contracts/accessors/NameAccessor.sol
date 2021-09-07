// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./NameRegistry.sol";

/// @title NameAccessor - manages the endpoints.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract NameAccessor {
	NameRegistry internal _nameRegistry;

	/// @dev Sets the address of NameRegistry.
	/// @param nameRegistry address of the NameRegistry
	constructor(address nameRegistry) {
		_nameRegistry = NameRegistry(nameRegistry);
	}

	/// @dev Prevents calling a function from anyone except the accepted contract.
	modifier onlyAllowedContract() {
		require(_nameRegistry.allowedContracts(msg.sender), "AR201");
		_;
	}

	/// @dev Throws if called by any account other than the owner.
	modifier onlyOwner() {
		require(owner() == msg.sender, "AR202");
		_;
	}

	/// @dev Gets the address of NameRegistry
	function nameRegistryAddress() public view returns (address) {
		return address(_nameRegistry);
	}

	/// @dev Gets the address of DistributionRight.
	function distributionRightAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("DistributionRight")));
	}

	/// @dev Gets the address of ReservedRight.
	function reservedRightAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("ReservedRight")));
	}

	/// @dev Gets the address of Vault.
	function vaultAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("Vault")));
	}

	function postOwnerPoolAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("PostOwnerPool")));
	}

	/// @dev Gets the owner address.
	function owner() public view returns (address) {
		return _nameRegistry.owner();
	}
}
