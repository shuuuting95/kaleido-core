// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Ad.sol";
import "../libraries/Purchase.sol";
import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../interfaces/IAdPool.sol";
import "../interfaces/IEventEmitter.sol";
import "../interfaces/IEnglishAuction.sol";

contract EnglishAuction is IEnglishAuction, NameAccessor {
	/// @dev Maps a tokenId with bidding info
	mapping(uint256 => Sale.Bidding) internal _bidding;

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	function bid(
		uint256 tokenId,
		address sender,
		uint256 amount
	) external override {
		_refundBiddingAmount(tokenId);
		_bidding[tokenId] = Sale.Bidding(tokenId, sender, amount);
	}

	function _refundBiddingAmount(uint256 tokenId) internal virtual {
		Ad.Period memory period = _adPool().allPeriods(tokenId);
		if (
			period.pricing == Ad.Pricing.ENGLISH &&
			_bidding[tokenId].bidder != address(0)
		) {
			(bool success, ) = payable(_bidding[tokenId].bidder).call{
				value: _bidding[tokenId].price,
				gas: 10000
			}("");
			if (!success) {
				_eventEmitter().emitPaymentFailure(
					_bidding[tokenId].bidder,
					_bidding[tokenId].price
				);
			}
		}
	}

	function bidding(uint256 tokenId)
		public
		view
		override
		returns (Sale.Bidding memory)
	{
		return _bidding[tokenId];
	}

	function currentPrice(uint256 tokenId)
		public
		view
		override
		returns (uint256)
	{
		return _bidding[tokenId].price;
	}

	/**
	 * Accessors
	 */
	function _adPool() internal view returns (IAdPool) {
		return IAdPool(adPoolAddress());
	}

	function _eventEmitter() internal view virtual returns (IEventEmitter) {
		return IEventEmitter(eventEmitterAddress());
	}
}
