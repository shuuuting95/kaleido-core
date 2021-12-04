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
		Ad.Period memory period = _adPool().allPeriods(tokenId);
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
		if (period.pricing == Ad.Pricing.ENGLISH) {
			return _english().currentPrice(tokenId);
		}
		if (period.pricing == Ad.Pricing.OFFER) {
			return _offerBid().currentPrice(tokenId);
		}
		if (period.pricing == Ad.Pricing.OPEN) {
			return 0;
		}
		revert("not exist");
	}

	function _alreadyBid(uint256 tokenId) internal view virtual returns (bool) {
		return
			_english().bidding(tokenId).bidder != address(0) ||
			_openBid().biddingList(tokenId).length != 0;
	}
}
