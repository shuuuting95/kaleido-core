// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Sale.sol";

/// @title IOfferBid
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IOfferBid {
	/// @dev Offers to buy a period that the sender requests.
	/// @param spaceMetadata string of the space metadata
	/// @param displayStartTimestamp uint256 of the start timestamp for the display
	/// @param displayEndTimestamp uint256 of the end timestamp for the display
	/// @param sender address of the msg.sender
	/// @param value uint256 of the msg.value
	function offer(
		string memory spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		address sender,
		uint256 value
	) external returns (uint256);

	/// @dev Cancels an offer.
	/// @param tokenId uint256 of the token ID
	/// @param sender address of the msg.sender
	function cancel(uint256 tokenId, address sender)
		external
		returns (Sale.Offer memory);

	/// @dev Accepts an offer by the Media.
	/// @param tokenId uint256 of the token ID
	function accept(uint256 tokenId) external returns (Sale.Offer memory);

	/// @dev Returns the current price.
	/// @param tokenId uint256 of the token ID
	function currentPrice(uint256 tokenId) external view returns (uint256);

	function offered(uint256 tokenId) external view returns (Sale.Offer memory);
}
