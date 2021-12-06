// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Sale.sol";

/// @title IOpenBid
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IOpenBid {
	function bid(
		uint256 tokenId,
		string memory proposal,
		address sender,
		uint256 amount
	) external;

	function biddingList(uint256 tokenId)
		external
		view
		returns (Sale.OpenBid[] memory);

	function bidding(uint256 tokenId, uint256 index)
		external
		view
		returns (Sale.OpenBid memory);

	function selectProposal(uint256 tokenId, uint256 index)
		external
		returns (Sale.OpenBid memory selected, Sale.OpenBid[] memory nonSelected);
}
