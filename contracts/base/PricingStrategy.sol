// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./PeriodManager.sol";
import "../common/BlockTimestamp.sol";

/// @title PricingStrategy - manages how to sell them out.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract PricingStrategy is PeriodManager, BlockTimestamp {
	struct Bidding {
		uint256 tokenId;
		address bidder;
		uint256 price;
	}
	struct Offer {
		string spaceMetadata;
		uint256 displayStartTimestamp;
		uint256 displayEndTimestamp;
		address sender;
		uint256 price;
	}
	/// @dev Maps tokenId with bidding info
	mapping(uint256 => Bidding) public bidding;

	/// @dev Maps tokenId with offer info
	mapping(uint256 => Offer) public offered;

	/// @dev Returns the current price.
	/// @param tokenId uint256 of the token ID
	function currentPrice(uint256 tokenId) public view returns (uint256) {
		Ad.Period memory period = allPeriods[tokenId];
		if (period.pricing == Ad.Pricing.RRP) {
			return period.minPrice;
		}
		if (period.pricing == Ad.Pricing.DPBT) {
			return
				period.startPrice -
				((period.startPrice - period.minPrice) *
					(_blockTimestamp() - period.saleStartTimestamp)) /
				(period.saleEndTimestamp - period.saleStartTimestamp);
		}
		if (period.pricing == Ad.Pricing.BIDDING) {
			return bidding[tokenId].price;
		}
		if (period.pricing == Ad.Pricing.OFFER) {
			return offered[tokenId].price;
		}
		revert("not exist");
	}

	function _startPrice(Ad.Period memory period)
		internal
		pure
		returns (uint256)
	{
		if (period.pricing == Ad.Pricing.RRP) {
			return period.minPrice;
		} else if (period.pricing == Ad.Pricing.DPBT) {
			return period.minPrice * 10;
		} else if (period.pricing == Ad.Pricing.BIDDING) {
			return period.minPrice;
		} else if (period.pricing == Ad.Pricing.OFFER) {
			return period.minPrice;
		} else {
			return 0;
		}
	}
}