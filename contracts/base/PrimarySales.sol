// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./PricingStrategy.sol";

/// @title PrimarySales - manages how to sell them out.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract PrimarySales is PricingStrategy {
	function _checkBeforeBuy(uint256 tokenId) internal {
		require(periods[tokenId].pricing == Ad.Pricing.RRP, "KD120");
		require(!periods[tokenId].sold, "KD121");
		require(periods[tokenId].minPrice == msg.value, "KD122");
	}

	function _checkBeforeBuyBasedOnTime(uint256 tokenId) internal {
		require(periods[tokenId].pricing == Ad.Pricing.DPBT, "KD123");
		require(!periods[tokenId].sold, "KD121");
		require(currentPrice(tokenId) <= msg.value, "KD122");
	}

	function _checkBeforeBid(uint256 tokenId) internal {
		require(periods[tokenId].pricing == Ad.Pricing.BIDDING, "KD124");
		require(!periods[tokenId].sold, "KD121");
		require(currentPrice(tokenId) < msg.value, "KD122");
	}

	function _refundLockedAmount(uint256 tokenId) internal returns (bool sent) {
		if (
			periods[tokenId].pricing == Ad.Pricing.BIDDING &&
			bidding[tokenId].bidder != address(0)
		) {
			sent = payable(bidding[tokenId].bidder).send(bidding[tokenId].price);
		}
	}
}
