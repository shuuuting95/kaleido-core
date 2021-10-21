// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./IProxy.sol";
import "../accessors/NameRegistry.sol";

/// @title MediaProxy - do delegatecalls to the destination contract.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract MediaProxy is IProxy {
	NameRegistry internal _nameRegistry;

	constructor(address nameRegistry) {
		require(nameRegistry != address(0), "AR001");
		_nameRegistry = NameRegistry(nameRegistry);
	}

	function masterCopy() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("Post")));
	}

	/// @dev Calls when users request to the post.
	///      The desitination is decided by NameRegistry, which can be switched by the administrator
	///      if the contract has any problem.
	function _fallback() internal {
		address _singleton = masterCopy();
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

	fallback() external payable {
		_fallback();
	}

	receive() external payable {
		_fallback();
	}
}
