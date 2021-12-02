// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../interfaces/IMediaRegistry.sol";
import "../interfaces/IAdPool.sol";
import "../interfaces/IEventEmitter.sol";
import "./Storage.sol";

/// @title SpaceManager - manages ad spaces.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract SpaceManager is NameAccessor, Storage {
	function _newSpace(string memory spaceMetadata) internal {
		require(
			!spaced[spaceMetadata] && !_adPool().spaced(spaceMetadata),
			"KD100"
		);
		spaced[spaceMetadata] = true;
		_adPool().addSpace(spaceMetadata);
		_eventEmitter().emitNewSpace(spaceMetadata);
	}

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view returns (IMediaRegistry) {
		return IMediaRegistry(mediaRegistryAddress());
	}

	function _adPool() internal view returns (IAdPool) {
		return IAdPool(adPoolAddress());
	}

	function _eventEmitter() internal view returns (IEventEmitter) {
		return IEventEmitter(eventEmitterAddress());
	}
}
