// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./ProposalManager.sol";
import "../common/BlockTimestamp.sol";

/// @title PrimarySales - manages how to sell them out.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract PrimarySales is ProposalManager, BlockTimestamp {
	/// @dev Returns the current price.
	/// @param tokenId uint256 of the token ID
	function currentPrice(uint256 tokenId) public view virtual returns (uint256) {
		Ad.Period memory period = periods[tokenId];
		if (period.pricing == Ad.Pricing.RRP) {
			return period.minPrice;
		}
		if (period.pricing == Ad.Pricing.DUTCH) {
			return
				period.startPrice -
				((period.startPrice - period.minPrice) *
					(_blockTimestamp() - period.saleStartTimestamp)) /
				(period.saleEndTimestamp - period.saleStartTimestamp);
		}
		// if (period.pricing == Ad.Pricing.ENGLISH) {
		// 	return bidding[tokenId].price;
		// }
		// if (period.pricing == Ad.Pricing.OFFER) {
		// 	return offered[tokenId].price;
		// }
		if (period.pricing == Ad.Pricing.OPEN) {
			return 0;
		}
		revert("not exist");
	}

	function _checkBeforeBuy(uint256 tokenId) internal view virtual {
		require(periods[tokenId].pricing == Ad.Pricing.RRP, "KD120");
		require(!periods[tokenId].sold, "KD121");
		require(periods[tokenId].minPrice == msg.value, "KD122");
	}

	// function _checkBeforeBuyBasedOnTime(uint256 tokenId) internal view virtual {
	// 	require(periods[tokenId].pricing == Ad.Pricing.DUTCH, "KD123");
	// 	require(!periods[tokenId].sold, "KD121");
	// 	require(currentPrice(tokenId) <= msg.value, "KD122");
	// }

	// function _checkBeforeBid(uint256 tokenId) internal view virtual {
	// 	require(periods[tokenId].pricing == Ad.Pricing.ENGLISH, "KD124");
	// 	require(!periods[tokenId].sold, "KD121");
	// 	require(currentPrice(tokenId) < msg.value, "KD122");
	// 	require(periods[tokenId].saleEndTimestamp >= _blockTimestamp(), "KD129");
	// }

	function _checkBeforeBidWithProposal(uint256 tokenId) internal view virtual {
		require(periods[tokenId].pricing == Ad.Pricing.OPEN, "KD127");
		require(!periods[tokenId].sold, "KD121");
		require(periods[tokenId].minPrice <= msg.value, "KD122");
		require(periods[tokenId].saleEndTimestamp >= _blockTimestamp(), "KD129");
	}

	function _alreadyBid(uint256 tokenId) internal view virtual returns (bool) {
		return appealed[tokenId].length != 0;
		// return
		// 	bidding[tokenId].bidder != address(0) || appealed[tokenId].length != 0;
	}

	// function _refundBiddingAmount(uint256 tokenId) internal virtual {
	// 	if (
	// 		periods[tokenId].pricing == Ad.Pricing.ENGLISH &&
	// 		bidding[tokenId].bidder != address(0)
	// 	) {
	// 		(bool success, ) = payable(bidding[tokenId].bidder).call{
	// 			value: bidding[tokenId].price,
	// 			gas: 10000
	// 		}("");
	// 		if (!success) {
	// 			_eventEmitter().emitPaymentFailure(
	// 				bidding[tokenId].bidder,
	// 				bidding[tokenId].price
	// 			);
	// 		}
	// 	}
	// }

	// function _refundOfferedAmount(uint256 tokenId) internal virtual {
	// 	if (
	// 		periods[tokenId].pricing == Ad.Pricing.OFFER &&
	// 		offered[tokenId].sender != address(0)
	// 	) {
	// 		(bool success, ) = payable(offered[tokenId].sender).call{
	// 			value: offered[tokenId].price,
	// 			gas: 10000
	// 		}("");
	// 		if (!success) {
	// 			_eventEmitter().emitPaymentFailure(
	// 				offered[tokenId].sender,
	// 				offered[tokenId].price
	// 			);
	// 		}
	// 	}
	// }
}
