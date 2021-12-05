// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Ad.sol";
import "../libraries/Purchase.sol";
import "../accessors/NameAccessor.sol";
import "../interfaces/IAdPool.sol";
import "../interfaces/IEventEmitter.sol";
import "../interfaces/IOfferBid.sol";
import "../interfaces/IMediaRegistry.sol";

contract OfferBid is IOfferBid, NameAccessor {
	/// @dev Maps a tokenId with offer info
	mapping(uint256 => Sale.Offer) internal _offered;

	modifier onlyProxies() {
		require(_mediaRegistry().ownerOf(msg.sender) != address(0x0), "KD011");
		_;
	}

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	function offer(
		string memory spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		address sender,
		uint256 value
	) external virtual onlyProxies returns (uint256 tokenId) {
		require(_adPool().spaced(spaceMetadata), "KD101");
		require(displayStartTimestamp < displayEndTimestamp, "KD113");
		tokenId = Ad.id(spaceMetadata, displayStartTimestamp, displayEndTimestamp);
		_offered[tokenId] = Sale.Offer(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp,
			sender,
			value
		);
		_eventEmitter().emitOfferPeriod(
			tokenId,
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp,
			sender,
			value
		);
	}

	function cancel(uint256 tokenId, address sender)
		external
		virtual
		onlyProxies
	{
		require(_offered[tokenId].sender == sender, "KD116");
		delete _offered[tokenId];
		_eventEmitter().emitCancelOffer(tokenId);
	}

	function accept(uint256 tokenId)
		external
		virtual
		onlyProxies
		returns (Sale.Offer memory)
	{
		Sale.Offer memory target = _offered[tokenId];
		require(target.sender != address(0), "KD115");
		delete _offered[tokenId];
		return target;
	}

	function currentPrice(uint256 tokenId)
		public
		view
		override
		returns (uint256)
	{
		return _offered[tokenId].price;
	}

	function offered(uint256 tokenId) external view returns (Sale.Offer memory) {
		return _offered[tokenId];
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
