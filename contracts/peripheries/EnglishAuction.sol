// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Ad.sol";
import "../libraries/Purchase.sol";
import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../interfaces/IAdPool.sol";
import "../interfaces/IEventEmitter.sol";
import "../interfaces/IEnglishAuction.sol";
import "../interfaces/IMediaRegistry.sol";

contract EnglishAuction is IEnglishAuction, BlockTimestamp, NameAccessor {
	/// @dev Maps a tokenId with bidding info
	mapping(uint256 => Sale.Bidding) internal _bidding;

	modifier onlyProxies() {
		require(_mediaRegistry().ownerOf(msg.sender) != address(0x0), "KD011");
		_;
	}

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	function bid(
		uint256 tokenId,
		address sender,
		uint256 value
	) external virtual override onlyProxies {
		_bidding[tokenId] = Sale.Bidding(tokenId, sender, value);
		_eventEmitter().emitBid(tokenId, value, sender, _blockTimestamp());
	}

	function receiveToken(uint256 tokenId)
		external
		virtual
		override
		onlyProxies
		returns (address bidder, uint256 price)
	{
		_checkBeforeReceiveToken(tokenId);
		bidder = _bidding[tokenId].bidder;
		price = _bidding[tokenId].price;
		delete _bidding[tokenId];
		_eventEmitter().emitReceiveToken(tokenId, price, bidder, _blockTimestamp());
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

	function _checkBeforeReceiveToken(uint256 tokenId)
		internal
		view
		returns (Ad.Period memory period)
	{
		period = _adPool().allPeriods(tokenId);
		require(period.pricing == Ad.Pricing.ENGLISH, "KD124");
		require(!period.sold, "KD121");
		require(period.saleEndTimestamp < _blockTimestamp(), "KD125");
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

	function _mediaRegistry() internal view returns (IMediaRegistry) {
		return IMediaRegistry(mediaRegistryAddress());
	}
}