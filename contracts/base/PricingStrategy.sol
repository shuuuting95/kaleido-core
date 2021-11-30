// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./PeriodManager.sol";
import "../common/BlockTimestamp.sol";
import "../libraries/Sale.sol";

/// @title PricingStrategy - manages how to sell them out.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract PricingStrategy is PeriodManager, BlockTimestamp {
	struct Offer {
		string spaceMetadata;
		uint256 displayStartTimestamp;
		uint256 displayEndTimestamp;
		address sender;
		uint256 price;
	}
	struct Appeal {
		uint256 tokenId;
		address sender;
		uint256 price;
		string content;
	}
	/// @dev Maps tokenId with bidding info
	mapping(uint256 => Sale.Bidding) public bidding;

	/// @dev Maps tokenId with offer info
	mapping(uint256 => Offer) public offered;

	/// @dev Maps tokenId with appeal info
	mapping(uint256 => Appeal[]) public appealed;

	/// @dev The total bidding value
	uint256 internal _biddingTotal;

	/// @dev The total value offered by users
	uint256 internal _offeredTotal;

	/// @dev Returns the current price.
	/// @param tokenId uint256 of the token ID
	function currentPrice(uint256 tokenId) public view returns (uint256) {
		Ad.Period memory period = periods[tokenId];
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
		if (period.pricing == Ad.Pricing.APPEAL) {
			return 0;
		}
		revert("not exist");
	}
}
