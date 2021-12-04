// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Ad.sol";
import "../libraries/Purchase.sol";
import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../interfaces/IAdPool.sol";
import "../interfaces/IEventEmitter.sol";
import "../interfaces/IOpenBid.sol";

contract OpenBid is IOpenBid, BlockTimestamp, NameAccessor {
	/// @dev Maps a tokenId with appeal info
	mapping(uint256 => Sale.OpenBid[]) internal _bidding;

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	function bid(
		uint256 tokenId,
		string memory proposal,
		address sender,
		uint256 value
	) external {
		_bidding[tokenId].push(Sale.OpenBid(tokenId, sender, value, proposal));
		_eventEmitter().emitBidWithProposal(
			tokenId,
			value,
			sender,
			proposal,
			_blockTimestamp()
		);
	}

	function biddingList(uint256 tokenId)
		public
		view
		returns (Sale.OpenBid[] memory)
	{
		return _bidding[tokenId];
	}

	function selectProposal(uint256 tokenId, uint256 index)
		external
		returns (address successfulBidder)
	{
		require(
			_bidding[tokenId].length >= index &&
				_bidding[tokenId][index].sender != address(0),
			"KD114"
		);
		require(
			_adPool().allPeriods(tokenId).saleEndTimestamp < _blockTimestamp(),
			"KD129"
		);
		_refundToProposers(tokenId, index);

		delete _bidding[tokenId];
		_eventEmitter().emitSelectProposal(tokenId, successfulBidder);
	}

	function _refundToProposers(uint256 tokenId, uint256 successfulBidderNo)
		internal
		virtual
	{
		for (uint256 i = 0; i < _bidding[tokenId].length; i++) {
			Sale.OpenBid memory appeal = _bidding[tokenId][i];
			// TODO: _biddingTotal -= appeal.price;
			if (i == successfulBidderNo) {
				// TODO: _collectFees(appeal.price / 10);
			} else {
				(bool success, ) = payable(appeal.sender).call{
					value: appeal.price,
					gas: 10000
				}("");
				if (!success) {
					_eventEmitter().emitPaymentFailure(appeal.sender, appeal.price);
				}
			}
		}
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
