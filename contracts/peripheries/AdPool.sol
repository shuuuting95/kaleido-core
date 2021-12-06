// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../interfaces/IAdPool.sol";
import "../interfaces/IMediaRegistry.sol";
import "../interfaces/IEventEmitter.sol";
import "../interfaces/IOfferBid.sol";
import "../interfaces/IEnglishAuction.sol";
import "../interfaces/IProposalReview.sol";
import "../interfaces/IOpenBid.sol";
import "../libraries/Schedule.sol";
import "../libraries/Purchase.sol";

/// @title AdPool - stores all ads accorss every space.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdPool is IAdPool, BlockTimestamp, NameAccessor {
	/// @dev tokenId <- metadata * displayStartTimestamp * displayEndTimestamp
	mapping(uint256 => Ad.Period) public periods;

	/// @dev Returns spaceId that is tied with space metadata.
	mapping(string => bool) public spaced;

	/// @dev Maps the space metadata with tokenIds of ad periods.
	mapping(string => uint256[]) internal _periodKeys;

	modifier onlyProxies() {
		require(_mediaRegistry().ownerOf(msg.sender) != address(0x0), "KD011");
		_;
	}

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	/// @inheritdoc IAdPool
	function addSpace(string memory metadata) external virtual onlyProxies {
		require(!spaced[metadata], "KD100");
		spaced[metadata] = true;
		_event().emitNewSpace(metadata);
	}

	/// @inheritdoc IAdPool
	function addPeriod(
		address proxy,
		string memory spaceMetadata,
		string memory tokenMetadata,
		uint256 saleEndTimestamp,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	) external virtual onlyProxies returns (uint256 tokenId) {
		require(saleEndTimestamp > _blockTimestamp(), "KD111");
		require(saleEndTimestamp <= displayStartTimestamp, "KD112");
		require(displayStartTimestamp < displayEndTimestamp, "KD113");

		_addSpaceIfNot(spaceMetadata);
		_checkOverlapping(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp
		);
		tokenId = Ad.id(spaceMetadata, displayStartTimestamp, displayEndTimestamp);
		Ad.Period memory period = Ad.Period(
			proxy,
			spaceMetadata,
			tokenMetadata,
			_blockTimestamp(),
			saleEndTimestamp,
			displayStartTimestamp,
			displayEndTimestamp,
			pricing,
			minPrice,
			0,
			false
		);
		period.startPrice = Sale.startPrice(period);
		periods[tokenId] = period;
		_periodKeys[spaceMetadata].push(tokenId);
		_event().emitNewPeriod(
			tokenId,
			spaceMetadata,
			tokenMetadata,
			_blockTimestamp(),
			saleEndTimestamp,
			displayStartTimestamp,
			displayEndTimestamp,
			pricing,
			minPrice
		);
	}

	/// @inheritdoc IAdPool
	function deletePeriod(uint256 tokenId) external virtual onlyProxies {
		require(periods[tokenId].mediaProxy != address(0), "KD114");
		require(!_alreadyBid(tokenId), "KD128");
		string memory spaceMetadata = periods[tokenId].spaceMetadata;
		uint256 index = 0;
		for (uint256 i = 1; i < _periodKeys[spaceMetadata].length + 1; i++) {
			if (_periodKeys[spaceMetadata][i - 1] == tokenId) {
				index = i;
			}
		}
		require(index != 0, "No deletable keys");
		delete _periodKeys[spaceMetadata][index - 1];
		delete periods[tokenId];
		_event().emitDeletePeriod(tokenId);
	}

	/// @inheritdoc IAdPool
	function soldByFixedPrice(uint256 tokenId, uint256 msgValue)
		external
		onlyProxies
	{
		Purchase.checkBeforeBuy(periods[tokenId], msgValue);
		periods[tokenId].sold = true;
	}

	/// @inheritdoc IAdPool
	function soldByDutchAuction(uint256 tokenId, uint256 msgValue)
		external
		onlyProxies
	{
		Purchase.checkBeforeBuyBasedOnTime(
			periods[tokenId],
			currentPrice(tokenId),
			_blockTimestamp(),
			msgValue
		);
		periods[tokenId].sold = true;
	}

	function acceptOffer(
		uint256 tokenId,
		string memory tokenMetadata,
		Sale.Offer memory offer
	) external virtual onlyProxies {
		_checkOverlapping(
			offer.spaceMetadata,
			offer.displayStartTimestamp,
			offer.displayEndTimestamp
		);
		Ad.Period memory period = Ad.Period(
			offer.sender,
			offer.spaceMetadata,
			tokenMetadata,
			_blockTimestamp(),
			_blockTimestamp(),
			offer.displayStartTimestamp,
			offer.displayEndTimestamp,
			Ad.Pricing.OFFER,
			offer.price,
			offer.price,
			true
		);
		periods[tokenId] = period;
		_periodKeys[offer.spaceMetadata].push(tokenId);
		_event().emitAcceptOffer(
			tokenId,
			offer.spaceMetadata,
			tokenMetadata,
			offer.displayStartTimestamp,
			offer.displayEndTimestamp,
			offer.price
		);
	}

	function bidByEnglishAuction(
		uint256 tokenId,
		address msgSender,
		uint256 msgValue
	) external onlyProxies returns (Sale.Bidding memory) {
		Purchase.checkBeforeBid(
			periods[tokenId],
			currentPrice(tokenId),
			_blockTimestamp(),
			msgValue
		);
		return _english().bid(tokenId, msgSender, msgValue);
	}

	function soldByEnglishAuction(uint256 tokenId)
		external
		onlyProxies
		returns (address bidder, uint256 price)
	{
		(bidder, price) = _english().receiveToken(tokenId);
		periods[tokenId].sold = true;
	}

	function bidWithProposal(
		uint256 tokenId,
		string memory proposalMetadata,
		address msgSender,
		uint256 msgValue
	) external onlyProxies {
		Purchase.checkBeforeBidWithProposal(
			periods[tokenId],
			_blockTimestamp(),
			msgValue
		);
		_openBid().bid(tokenId, proposalMetadata, msgSender, msgValue);
	}

	function allPeriods(uint256 tokenId)
		external
		view
		returns (Ad.Period memory)
	{
		return periods[tokenId];
	}

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

	/// @dev Displays the ad content that is approved by the media owner.
	/// @param spaceMetadata string of the space metadata
	function display(string memory spaceMetadata)
		external
		view
		virtual
		returns (string memory, uint256)
	{
		uint256[] memory tokenIds = tokenIdsOf(spaceMetadata);
		for (uint256 i = 0; i < tokenIds.length; i++) {
			if (tokenIds[i] != 0) {
				Ad.Period memory period = periods[tokenIds[i]];
				if (
					period.displayStartTimestamp <= _blockTimestamp() &&
					period.displayEndTimestamp >= _blockTimestamp()
				) {
					string memory content = _review().acceptedContent(tokenIds[i]);
					return (content, tokenIds[i]);
				}
			}
		}
		return ("", 0);
	}

	/// @inheritdoc IAdPool
	function mediaProxyOf(uint256 tokenId) external view returns (address) {
		return periods[tokenId].mediaProxy;
	}

	function displayStart(uint256 tokenId) public view returns (uint256) {
		return periods[tokenId].displayStartTimestamp;
	}

	function displayEnd(uint256 tokenId) public view returns (uint256) {
		return periods[tokenId].displayEndTimestamp;
	}

	/// @dev Returns tokenIds tied with the space metadata
	/// @param spaceMetadata string of the space metadata
	function tokenIdsOf(string memory spaceMetadata)
		public
		view
		virtual
		returns (uint256[] memory)
	{
		return _periodKeys[spaceMetadata];
	}

	function _alreadyBid(uint256 tokenId) internal view virtual returns (bool) {
		return
			_english().bidding(tokenId).bidder != address(0) ||
			_openBid().biddingList(tokenId).length != 0;
	}

	function _checkOverlapping(
		string memory metadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp
	) internal view virtual {
		for (uint256 i = 0; i < _periodKeys[metadata].length; i++) {
			uint256 existDisplayStart = displayStart(_periodKeys[metadata][i]);
			uint256 existDisplayEnd = displayEnd(_periodKeys[metadata][i]);

			if (
				Schedule.isOverlapped(
					displayStartTimestamp,
					displayEndTimestamp,
					existDisplayStart,
					existDisplayEnd
				)
			) {
				revert("KD110");
			}
		}
	}

	function _addSpaceIfNot(string memory metadata) internal {
		if (!spaced[metadata]) {
			spaced[metadata] = true;
			_event().emitNewSpace(metadata);
		}
	}

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view returns (IMediaRegistry) {
		return IMediaRegistry(mediaRegistryAddress());
	}

	function _event() internal view virtual returns (IEventEmitter) {
		return IEventEmitter(eventEmitterAddress());
	}

	function _offerBid() internal view virtual returns (IOfferBid) {
		return IOfferBid(offerBidAddress());
	}

	function _english() internal view virtual returns (IEnglishAuction) {
		return IEnglishAuction(englishAuctionAddress());
	}

	function _review() internal view virtual returns (IProposalReview) {
		return IProposalReview(proposalReviewAddress());
	}

	function _openBid() internal view virtual returns (IOpenBid) {
		return IOpenBid(openBidAddress());
	}
}
