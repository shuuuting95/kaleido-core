// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./Ad.sol";

library Purchase {
	function checkBeforeBuy(Ad.Period memory period, uint256 msgValue)
		public
		pure
	{
		require(period.pricing == Ad.Pricing.RRP, "KD120");
		require(!period.sold, "KD121");
		require(period.minPrice == msgValue, "KD122");
	}

	function checkBeforeBuyBasedOnTime(
		Ad.Period memory period,
		uint256 currentPrice,
		uint256 blockTimestamp,
		uint256 msgValue
	) public pure {
		require(period.pricing == Ad.Pricing.DUTCH, "KD123");
		require(!period.sold, "KD121");
		require(currentPrice <= msgValue, "KD122");
		require(period.saleEndTimestamp >= blockTimestamp, "KD129");
	}

	function checkBeforeBid(
		Ad.Period memory period,
		uint256 currentPrice,
		uint256 blockTimestamp,
		uint256 msgValue
	) public pure {
		require(period.pricing == Ad.Pricing.ENGLISH, "KD124");
		require(!period.sold, "KD121");
		require(currentPrice < msgValue, "KD122");
		require(period.saleEndTimestamp >= blockTimestamp, "KD129");
	}

	function checkBeforeBidWithProposal(
		Ad.Period memory period,
		uint256 blockTimestamp,
		uint256 msgValue
	) public pure {
		require(period.pricing == Ad.Pricing.OPEN, "KD127");
		require(!period.sold, "KD121");
		require(period.minPrice <= msgValue, "KD122");
		require(period.saleEndTimestamp >= blockTimestamp, "KD129");
	}
}
