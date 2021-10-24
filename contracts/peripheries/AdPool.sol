// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../libraries/Ad.sol";
import "./MediaRegistry.sol";

/// @title AdPool - stores all ads accorss every space.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdPool is BlockTimestamp, NameAccessor {
	mapping(uint256 => Ad.Period) public allPeriods;

	modifier onlyProxies() {
		require(_mediaRegistry().ownerOf(msg.sender) != address(0x0), "KD");
		_;
	}

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	function addPeriod(uint256 tokenId, Ad.Period memory period)
		external
		onlyProxies
	{
		allPeriods[tokenId] = period;
	}

	function deletePeriod(uint256 tokenId) external onlyProxies {
		delete allPeriods[tokenId];
	}

	function mediaProxyOf(uint256 tokenId) public view returns (address) {
		return allPeriods[tokenId].mediaProxy;
	}

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view returns (MediaRegistry) {
		return MediaRegistry(mediaRegistryAddress());
	}
}
