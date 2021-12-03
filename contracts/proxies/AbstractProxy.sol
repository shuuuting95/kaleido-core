// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./IProxy.sol";
import "../interfaces/IEventEmitter.sol";
import "../accessors/NameRegistry.sol";
import "../common/EtherPaymentFallback.sol";
import "hardhat/console.sol";

/// @title MediaProxy - do delegatecalls to the destination contract.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract AbstractProxy is IProxy, EtherPaymentFallback {
	/// @dev Initializer
	/// @param nameRegistry address of NameRegistry
	constructor(address nameRegistry) {
		require(nameRegistry != address(0), "AR001");
		_setImplementation(nameRegistry);
	}

	/// @dev Returns the address of the destination contract
	function masterCopy() public view returns (address) {
		return _implementation();
	}

	/// @dev Calls logic on the destination contract.
	///      The desitination is decided by NameRegistry, which can be switched by the administrator
	///      if the contract has any changes.
	fallback() external payable {
		_fallback();
	}

	function _fallback() internal {
		address _singleton = NameRegistry(masterCopy()).get(
			keccak256(abi.encodePacked("AdManager"))
		);
		// solhint-disable-next-line no-inline-assembly
		assembly {
			if eq(
				calldataload(0),
				0xa619486e00000000000000000000000000000000000000000000000000000000
			) {
				mstore(0, _singleton)
				return(0, 0x20)
			}
			calldatacopy(0, 0, calldatasize())
			let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
			returndatacopy(0, 0, returndatasize())
			switch success
			case 0 {
				revert(0, returndatasize())
			}
			default {
				return(0, returndatasize())
			}
		}
	}

	/// @dev Transfers fees to Vault when receiving Ether payments.
	receive() external payable override {
		require(msg.value != 0, "msg.value is zero");
		address vault = NameRegistry(masterCopy()).get(
			keccak256(abi.encodePacked("Vault"))
		);
		(bool success, ) = payable(vault).call{ value: msg.value / 2, gas: 10000 }(
			""
		);
		if (!success) {
			address _event = NameRegistry(masterCopy()).get(
				keccak256(abi.encodePacked("EventEmitter"))
			);
			IEventEmitter(_event).emitPaymentFailure(vault, msg.value / 2);
		}
	}

	/**
	 * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
	 * and {_fallback} should delegate.
	 */
	function _implementation() internal view virtual returns (address);

	function _setImplementation(address implementation) internal virtual;
}
