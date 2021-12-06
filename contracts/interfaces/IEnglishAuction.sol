// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../libraries/Sale.sol";

/// @title IEnglishAuction
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IEnglishAuction {
	/// @dev Bids to participate in an auction.
	///      It is defined as an English Auction.
	/// @param tokenId uint256 of the token ID
	/// @param sender address of the msg.sender
	/// @param amount uint256 of the msg.value
	function bid(
		uint256 tokenId,
		address sender,
		uint256 amount
	) external returns (Sale.Bidding memory);

	/// @dev Receives the token you bidded if you are the successful bidder.
	/// @param tokenId uint256 of the token ID
	function receiveToken(uint256 tokenId) external returns (address, uint256);

	/// @dev Returns the current price.
	/// @param tokenId uint256 of the token ID
	function currentPrice(uint256 tokenId) external view returns (uint256);

	function bidding(uint256 tokenId) external view returns (Sale.Bidding memory);
}
