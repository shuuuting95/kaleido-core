// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./PeriodManager.sol";
import "../common/BlockTimestamp.sol";
import "../libraries/Sale.sol";

/// @title PrimarySales - manages how to sell them out.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract PrimarySales is PeriodManager, BlockTimestamp {
	/// @dev Maps tokenId with bidding info
	mapping(uint256 => Sale.Bidding) public bidding;

	/// @dev Maps tokenId with offer info
	mapping(uint256 => Sale.Offer) public offered;

	/// @dev Maps tokenId with appeal info
	mapping(uint256 => Sale.Appeal[]) public appealed;

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

	function _checkBeforeBidWithProposal(uint256 tokenId) internal {
		require(periods[tokenId].pricing == Ad.Pricing.APPEAL, "KD127");
		require(!periods[tokenId].sold, "KD121");
		require(periods[tokenId].minPrice <= msg.value, "KD122");
	}

	function _alreadyBid(uint256 tokenId) internal view returns (bool) {
		return
			bidding[tokenId].bidder != address(0) || appealed[tokenId].length != 0;
	}

	function _refundBiddingAmount(uint256 tokenId) internal returns (bool sent) {
		if (
			periods[tokenId].pricing == Ad.Pricing.BIDDING &&
			bidding[tokenId].bidder != address(0)
		) {
			sent = payable(bidding[tokenId].bidder).send(bidding[tokenId].price);
		}
	}

	function _refundOfferedAmount(uint256 tokenId) internal returns (bool sent) {
		if (
			periods[tokenId].pricing == Ad.Pricing.OFFER &&
			offered[tokenId].sender != address(0)
		) {
			sent = payable(offered[tokenId].sender).send(offered[tokenId].price);
		}
	}
}
