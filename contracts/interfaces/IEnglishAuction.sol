// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Sale.sol";

/// @title IEnglishAuction
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IEnglishAuction {
	function bid(
		uint256 tokenId,
		address sender,
		uint256 amount
	) external;

	function bidding(uint256 tokenId) external view returns (Sale.Bidding memory);

	function currentPrice(uint256 tokenId) external view returns (uint256);
}
