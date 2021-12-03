// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../interfaces/IAdPool.sol";
import "../interfaces/IMediaRegistry.sol";

/// @title AdPool - stores all ads accorss every space.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdPool is IAdPool, BlockTimestamp, NameAccessor {
	/// @dev tokenId <- metadata * displayStartTimestamp * displayEndTimestamp
	mapping(uint256 => Ad.Period) public allPeriods;
	/// @dev Returns spaceId that is tied with space metadata.
	mapping(string => bool) public spaced;

	modifier onlyProxies() {
		require(_mediaRegistry().ownerOf(msg.sender) != address(0x0), "KD011");
		_;
	}

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	/// @inheritdoc IAdPool
	function addSpace(string memory spaceMetadata) external onlyProxies {
		spaced[spaceMetadata] = true;
	}

	/// @inheritdoc IAdPool
	function addPeriod(uint256 tokenId, Ad.Period memory period)
		external
		onlyProxies
	{
		allPeriods[tokenId] = period;
	}

	/// @inheritdoc IAdPool
	function deletePeriod(uint256 tokenId) external onlyProxies {
		delete allPeriods[tokenId];
	}

	/// @inheritdoc IAdPool
	function mediaProxyOf(uint256 tokenId) external view returns (address) {
		return allPeriods[tokenId].mediaProxy;
	}

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view returns (IMediaRegistry) {
		return IMediaRegistry(mediaRegistryAddress());
	}
}
