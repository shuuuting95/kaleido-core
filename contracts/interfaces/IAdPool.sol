// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Ad.sol";

/// @title IAdPool - stores all ads accorss every space.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IAdPool {
	function addSpace(string memory spaceMetadata) external;

	function addPeriod(uint256 tokenId, Ad.Period memory period) external;

	function deletePeriod(uint256 tokenId) external;

	function mediaProxyOf(uint256 tokenId) external view returns (address);
}
