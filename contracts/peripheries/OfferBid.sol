// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Ad.sol";
import "../libraries/Parchase.sol";
import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../interfaces/IAdPool.sol";
import "../interfaces/IEventEmitter.sol";
import "../interfaces/IOfferBid.sol";

contract OfferBid is IOfferBid, BlockTimestamp, NameAccessor {
	/// @dev Maps a tokenId with offer info
	mapping(uint256 => Sale.Offer) internal _offered;

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	function offer(
		string memory spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		address sender,
		uint256 value
	) external returns (uint256 tokenId) {
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
	}

	function cancel(uint256 tokenId) external {
		require(_offered[tokenId].sender == msg.sender, "KD116");
		_refundOfferedAmount(tokenId);

		delete _offered[tokenId];
	}

	function accept(uint256 tokenId, string memory tokenMetadata)
		external
		returns (address, uint256)
	{
		Sale.Offer memory offered = _offered[tokenId];
		require(offered.sender != address(0), "KD115");
		_adPool().acceptOffer(tokenId, tokenMetadata, offered);

		delete _offered[tokenId];
		return (offered.sender, offered.price);
	}

	function currentPrice(uint256 tokenId)
		public
		view
		override
		returns (uint256)
	{
		return _offered[tokenId].price;
	}

	function _refundOfferedAmount(uint256 tokenId) internal virtual {
		Ad.Period memory period = _adPool().allPeriods(tokenId);
		if (
			period.pricing == Ad.Pricing.OFFER &&
			_offered[tokenId].sender != address(0)
		) {
			(bool success, ) = payable(_offered[tokenId].sender).call{
				value: _offered[tokenId].price,
				gas: 10000
			}("");
			if (!success) {
				_eventEmitter().emitPaymentFailure(
					_offered[tokenId].sender,
					_offered[tokenId].price
				);
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
