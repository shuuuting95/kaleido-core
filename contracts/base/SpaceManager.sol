// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @title SpaceManager - manages ad spaces.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract SpaceManager {
	event NewSpace(string metadata);
	event DeleteSpace(string metadata);

	uint256 public spaceNonce = 10000001;

	/// @dev Returns spaceId that is tied with space metadata.
	mapping(string => bytes32) public spaceId;

	function _newSpace(string memory spaceMetadata) internal {
		require(spaceId[spaceMetadata] == 0, "KD102");
		spaceId[spaceMetadata] = _computeSpaceId(spaceNonce++);
		emit NewSpace(spaceMetadata);
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
		emit DeleteSpace(spaceMetadata);
	}

	function _computeSpaceId(uint256 nonce) private view returns (bytes32) {
		return keccak256(abi.encodePacked(nonce, address(this)));
	}
}
