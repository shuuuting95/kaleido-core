// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./NameRegistry.sol";

/// @title NameAccessor - manages the endpoints.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract NameAccessor {
	NameRegistry internal _nameRegistry;

	/// @dev Sets the address of NameRegistry.
	/// @param nameRegistry address of the NameRegistry
	function initialize(address nameRegistry) internal {
		_nameRegistry = NameRegistry(nameRegistry);
	}

	/// @dev Prevents calling a function from anyone except the accepted contract.
	modifier onlyAllowedContract() {
		require(_nameRegistry.allowedContracts(msg.sender), "KD013");
		_;
	}

	modifier onlyFactory() {
		require(msg.sender == mediaFactoryAddress(), "KD010");
		_;
	}

	/// @dev Throws if called by any account other than the owner.
	modifier onlyOwner() {
		require(owner() == msg.sender, "KD012");
		_;
	}

	/// @dev Gets the address of NameRegistry
	function nameRegistryAddress() public view returns (address) {
		return address(_nameRegistry);
	}

	/// @dev Gets the address of AdPool.
	function adPoolAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("AdPool")));
	}

	/// @dev Gets the address of MediaFactory.
	function mediaFactoryAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("MediaFactory")));
	}

	/// @dev Gets the address of MediaRegistry.
	function mediaRegistryAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("MediaRegistry")));
	}

	/// @dev Gets the address of Vault.
	function vaultAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("Vault")));
	}

	/// @dev Gets the address of EventEmitter.
	function eventEmitterAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("EventEmitter")));
	}

	/// @dev Gets the owner address.
	function owner() public view returns (address) {
		return _nameRegistry.owner();
	}
}
