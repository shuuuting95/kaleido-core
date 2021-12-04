// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../interfaces/IAdPool.sol";
import "../interfaces/IMediaRegistry.sol";
import "../interfaces/IEventEmitter.sol";
import "../libraries/Schedule.sol";

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
	function addSpace(string memory metadata) external onlyProxies {
		require(!spaced[metadata], "KD100");
		spaced[metadata] = true;
		_eventEmitter().emitNewSpace(metadata);
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
	) external onlyProxies returns (uint256 tokenId) {
		require(saleEndTimestamp > _blockTimestamp(), "KD111");
		require(saleEndTimestamp < displayStartTimestamp, "KD112");
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
		period.startPrice = Sale._startPrice(period);
		periods[tokenId] = period;
		_periodKeys[spaceMetadata].push(tokenId);
		_eventEmitter().emitNewPeriod(
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
	function deletePeriod(uint256 tokenId) external onlyProxies {
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
		_eventEmitter().emitDeletePeriod(tokenId);
	}

	function acceptOffer(
		uint256 tokenId,
		string memory tokenMetadata,
		Sale.Offer memory offer
	) external {
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
		_eventEmitter().emitAcceptOffer(
			tokenId,
			offer.spaceMetadata,
			tokenMetadata,
			offer.displayStartTimestamp,
			offer.displayEndTimestamp,
			offer.price
		);
	}

	function sold(uint256 tokenId) external onlyProxies {
		periods[tokenId].sold = true;
	}

	function allPeriods(uint256 tokenId)
		external
		view
		returns (Ad.Period memory)
	{
		return periods[tokenId];
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

	function _checkOverlapping(
		string memory metadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp
	) internal view virtual {
		for (uint256 i = 0; i < _periodKeys[metadata].length; i++) {
			// Ad.Period memory existing = _adPool().allPeriods(
			// 	_periodKeys[metadata][i]
			// );
			uint256 existDisplayStart = displayStart(_periodKeys[metadata][i]);
			uint256 existDisplayEnd = displayEnd(_periodKeys[metadata][i]);

			if (
				Schedule._isOverlapped(
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
			_eventEmitter().emitNewSpace(metadata);
		}
	}

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view returns (IMediaRegistry) {
		return IMediaRegistry(mediaRegistryAddress());
	}

	function _eventEmitter() internal view virtual returns (IEventEmitter) {
		return IEventEmitter(eventEmitterAddress());
	}
}
