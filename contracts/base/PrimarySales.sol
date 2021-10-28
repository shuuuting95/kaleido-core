// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./PricingStrategy.sol";

/// @title PrimarySales - manages how to sell them out.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract PrimarySales is PricingStrategy {
	struct Offer {
		string spaceMetadata;
		uint256 displayStartTimestamp;
		uint256 displayEndTimestamp;
		address sender;
		uint256 price;
	}
	mapping(uint256 => Offer) public offered;

	function _checkBeforeBuy(uint256 tokenId) internal {
		require(allPeriods[tokenId].pricing == Ad.Pricing.RRP, "KD120");
		require(!allPeriods[tokenId].sold, "KD121");
		require(allPeriods[tokenId].minPrice == msg.value, "KD122");
	}

	function _checkBeforeBuyBasedOnTime(uint256 tokenId) internal {
		require(allPeriods[tokenId].pricing == Ad.Pricing.DPBT, "KD123");
		require(!allPeriods[tokenId].sold, "KD121");
		require(currentPrice(tokenId) <= msg.value, "KD122");
	}

	function _checkBeforeBid(uint256 tokenId) internal {
		require(allPeriods[tokenId].pricing == Ad.Pricing.BIDDING, "KD124");
		require(!allPeriods[tokenId].sold, "KD121");
		require(currentPrice(tokenId) <= msg.value, "KD122");
	}

	function _refundLockedAmount(uint256 tokenId) internal {
		if (
			allPeriods[tokenId].pricing == Ad.Pricing.BIDDING &&
			bidding[tokenId].bidder != address(0)
		) {
			payable(bidding[tokenId].bidder).transfer(bidding[tokenId].price);
		}
	}
}
