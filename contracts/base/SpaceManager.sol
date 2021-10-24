// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../peripheries/MediaRegistry.sol";
import "../peripheries/AdPool.sol";
import "../peripheries/EventEmitter.sol";

/// @title SpaceManager - manages ad spaces.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract SpaceManager is NameAccessor {
	uint256 public spaceNonce = 10000001;

	/// @dev Returns spaceId that is tied with space metadata.
	mapping(string => bytes32) public spaceId;

	function _newSpace(string memory spaceMetadata) internal {
		require(spaceId[spaceMetadata] == 0, "KD102");
		spaceId[spaceMetadata] = computeSpaceId(spaceNonce++);
		_eventEmitter().emitNewSpace(spaceMetadata);
	}

	function _link(string memory spaceMetadata, bytes32 _spaceId) internal {
		spaceId[spaceMetadata] = _spaceId;
	}

	function _deleteSpace(string memory spaceMetadata)
		internal
		returns (bytes32 _spaceId)
	{
		require(spaceId[spaceMetadata] != 0, "KD");
		_spaceId = spaceId[spaceMetadata];
		spaceId[spaceMetadata] = 0;
		_eventEmitter().emitDeleteSpace(spaceMetadata);
	}

	function computeSpaceId(uint256 nonce) public view returns (bytes32) {
		return keccak256(abi.encodePacked(nonce, address(this)));
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
