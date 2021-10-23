// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../libraries/Ad.sol";
import "./MediaRegistry.sol";
import "./BlockTimestamp.sol";

/// @title AdPool - stores all ads accorss every space.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdPool is BlockTimestamp, NameAccessor {
	mapping(uint256 => Ad.Period) public allPeriods;

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	function addPeriod(uint256 tokenId, Ad.Period memory period) external {
		allPeriods[tokenId] = period;
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
