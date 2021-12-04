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

	function bidding(uint256 tokenId, uint256 index)
		public
		view
		returns (Sale.OpenBid memory)
	{
		require(
			_bidding[tokenId].length >= index &&
				_bidding[tokenId][index].sender != address(0),
			"KD114"
		);
		return _bidding[tokenId][index];
	}

	function selectProposal(uint256 tokenId, uint256 index)
		external
		returns (address successfulBidder)
	{
		require(
			_adPool().allPeriods(tokenId).saleEndTimestamp < _blockTimestamp(),
			"KD129"
		);
		successfulBidder = bidding(tokenId, index).sender;
		delete _bidding[tokenId];
		_eventEmitter().emitSelectProposal(tokenId, successfulBidder);
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
