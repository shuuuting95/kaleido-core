// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Ad.sol";
import "../libraries/Sale.sol";

/// @title IAdPool - stores all ads accorss every space.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IAdPool {
	function allPeriods(uint256 tokenId) external view returns (Ad.Period memory);

	function spaced(string memory spaceMetadata) external view returns (bool);

	function addSpace(string memory spaceMetadata) external;

	function addPeriod(
		address proxy,
		string memory spaceMetadata,
		string memory tokenMetadata,
		uint256 saleEndTimestamp,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	) external returns (uint256);

	function deletePeriod(uint256 tokenId) external;

	function sold(uint256 tokenId) external;

	function acceptOffer(
		uint256 tokenId,
		string memory tokenMetadata,
		Sale.Offer memory offer
	) external;

	function mediaProxyOf(uint256 tokenId) external view returns (address);

	function displayStart(uint256 tokenId) external view returns (uint256);

	function displayEnd(uint256 tokenId) external view returns (uint256);

	function tokenIdsOf(string memory spaceMetadata)
		external
		view
		returns (uint256[] memory);
}
