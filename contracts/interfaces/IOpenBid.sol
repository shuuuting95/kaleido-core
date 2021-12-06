// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Sale.sol";

/// @title IOpenBid
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IOpenBid {
	/// @dev Bids to participate in an auction.
	///      It is defined as an Open Bid.
	/// @param tokenId uint256 of the token ID
	/// @param proposal string of the metadata hash
	/// @param sender address of the msg.sender
	/// @param amount uint256 of the msg.value
	function bid(
		uint256 tokenId,
		string memory proposal,
		address sender,
		uint256 amount
	) external;

	/// @dev Selects the best proposal bidded with.
	/// @param tokenId uint256 of the token ID
	/// @param index uint256 of the index number
	function selectProposal(uint256 tokenId, uint256 index)
		external
		returns (Sale.OpenBid memory selected, Sale.OpenBid[] memory nonSelected);

	function biddingList(uint256 tokenId)
		external
		view
		returns (Sale.OpenBid[] memory);

	function bidding(uint256 tokenId, uint256 index)
		external
		view
		returns (Sale.OpenBid memory);
}
