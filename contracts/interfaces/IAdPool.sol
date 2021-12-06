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

	/// @dev Deletes a period and its token.
	///      If there is any users locking the fund for the sale, the amount would be transfered
	///      to the user when deleting the period.
	/// @param tokenId uint256 of the token ID
	function deletePeriod(uint256 tokenId) external;

	/// @dev Buys the token that is defined as the specific period on an ad space.
	///      The price of the token is fixed.
	/// @param tokenId uint256 of the token ID
	/// @param msgValue uint256 of the price
	function soldByFixedPrice(uint256 tokenId, uint256 msgValue) external;

	/// @dev Buys the token that is defined as the specific period on an ad space.
	///      The price is decreasing as time goes by, that is defined as an Dutch Auction.
	/// @param tokenId uint256 of the token ID
	/// @param msgValue uint256 of the price
	function soldByDutchAuction(uint256 tokenId, uint256 msgValue) external;

	/// @dev Bids to participate in an auction.
	///      It is defined as an English Auction.
	/// @param tokenId uint256 of the token ID
	/// @param msgSender address of the sender
	/// @param msgValue uint256 of the price
	function bidByEnglishAuction(
		uint256 tokenId,
		address msgSender,
		uint256 msgValue
	) external returns (Sale.Bidding memory);

	/// @dev Receives the token you bidded if you are the successful bidder.
	/// @param tokenId uint256 of the token ID
	function soldByEnglishAuction(uint256 tokenId)
		external
		returns (address, uint256);

	/// @dev Bids to participate in an auction.
	///      It is defined as an Open Bid.
	/// @param tokenId uint256 of the token ID
	/// @param proposalMetadata string of the metadata hash
	/// @param msgSender address of the sender
	/// @param msgValue uint256 of the price
	function bidWithProposal(
		uint256 tokenId,
		string memory proposalMetadata,
		address msgSender,
		uint256 msgValue
	) external;

	/// @dev Accepts an offer by the Media.
	/// @param tokenId uint256 of the token ID
	/// @param tokenMetadata string of the NFT token metadata
	/// @param offer Sale.Offer
	function acceptOffer(
		uint256 tokenId,
		string memory tokenMetadata,
		Sale.Offer memory offer
	) external;

	function mediaProxyOf(uint256 tokenId) external view returns (address);

	/// @dev Returns tokenIds tied with the space metadata
	/// @param spaceMetadata string of the space metadata
	function tokenIdsOf(string memory spaceMetadata)
		external
		view
		returns (uint256[] memory);

	/// @dev Returns the current price.
	/// @param tokenId uint256 of the token ID
	function currentPrice(uint256 tokenId) external view returns (uint256);

	/// @dev Displays the ad content that is approved by the media owner.
	/// @param spaceMetadata string of the space metadata
	function display(string memory spaceMetadata)
		external
		view
		returns (string memory, uint256);
}
