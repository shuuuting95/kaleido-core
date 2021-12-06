// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./AbstractProxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @title MediaProxy - do delegatecalls to the destination contract.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract MediaProxy is AbstractProxy {
	/**
	 * @dev Storage slot with the address of the current implementation.
	 * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
	 * validated in the constructor.
	 */
	bytes32 internal constant _IMPLEMENTATION_SLOT =
		0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

	/// @dev Initializer
	/// @param nameRegistry address of NameRegistry
	constructor(address nameRegistry) AbstractProxy(nameRegistry) {}

	function _implementation()
		internal
		view
		virtual
		override
		returns (address impl)
	{
		return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
	}

	/**
	 * @dev Stores a new address in the EIP1967 implementation slot.
	 */
	function _setImplementation(address newImplementation)
		internal
		virtual
		override
	{
		require(
			Address.isContract(newImplementation),
			"ERC1967: new implementation is not a contract"
		);
		StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
	}
}
