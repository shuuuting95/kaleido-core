// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../peripheries/MediaRegistry.sol";
import "../peripheries/AdPool.sol";
import "../peripheries/EventEmitter.sol";

/// @title SpaceManager - manages ad spaces.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract SpaceManager is NameAccessor {
	/// @dev Returns spaceId that is tied with space metadata.
	mapping(string => bool) public spaced;

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
	function _mediaRegistry() internal view returns (MediaRegistry) {
		return MediaRegistry(mediaRegistryAddress());
	}

	function _adPool() internal view returns (AdPool) {
		return AdPool(adPoolAddress());
	}

	function _eventEmitter() internal view returns (EventEmitter) {
		return EventEmitter(eventEmitterAddress());
	}
}
