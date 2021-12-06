// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Ad.sol";
import "../libraries/Sale.sol";

/// @title IAdPool - stores all ads accorss every space.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IAdPool {
	function allPeriods(uint256 tokenId) external view returns (Ad.Period memory);

	function spaced(string memory spaceMetadata) external view returns (bool);

	/// @dev Creates a new space for the media account.
	/// @param spaceMetadata string of the space metadata
	function addSpace(string memory spaceMetadata) external;

	/// @dev Create a new period for a space. This function requires some params
	///      to decide which kinds of pricing way and how much price to get started.
	/// @param proxy address of the media proxy
	/// @param spaceMetadata string of the space metadata
	/// @param tokenMetadata string of the token metadata
	/// @param saleEndTimestamp uint256 of the end timestamp for the sale
	/// @param displayStartTimestamp uint256 of the start timestamp for the display
	/// @param displayEndTimestamp uint256 of the end timestamp for the display
	/// @param pricing uint256 of the pricing way
	/// @param minPrice uint256 of the minimum price to sell it out
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

	function currentPrice(uint256 tokenId) external view returns (uint256);

	function display(string memory spaceMetadata)
		external
		view
		returns (string memory, uint256);

	function soldByFixedPrice(uint256 tokenId, uint256 msgValue) external;

	function soldByDutchAuction(uint256 tokenId, uint256 msgValue) external;

	function bidByEnglishAuction(
		uint256 tokenId,
		address msgSender,
		uint256 msgValue
	) external returns (Sale.Bidding memory);

	function soldByEnglishAuction(uint256 tokenId)
		external
		returns (address, uint256);

	function bidWithProposal(
		uint256 tokenId,
		string memory proposalMetadata,
		address msgSender,
		uint256 msgValue
	) external;
}
