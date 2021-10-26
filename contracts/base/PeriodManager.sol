// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./SpaceManager.sol";
import "../libraries/Ad.sol";

/// @title PeriodManager - manages ad periods.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract PeriodManager is SpaceManager {
	event NewPeriod(
		uint256 tokenId,
		string spaceMetadata,
		string tokenMetadata,
		uint256 fromTimestamp,
		uint256 toTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	);

	/// @dev tokenId <- metadata * displayStartTimestamp * displayEndTimestamp
	/// TODO: delete
	mapping(uint256 => Ad.Period) public allPeriods;

	/// @dev Maps the space metadata with tokenIds of ad periods.
	mapping(string => uint256[]) internal _periodKeys;

	function _checkOverlapping(
		string memory metadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp
	) internal view {
		for (uint256 i = 0; i < _periodKeys[metadata].length; i++) {
			Ad.Period memory existing = allPeriods[_periodKeys[metadata][i]];
			if (
				_isOverlapped(
					displayStartTimestamp,
					displayEndTimestamp,
					existing.displayStartTimestamp,
					existing.displayEndTimestamp
				)
			) {
				revert("KD110");
			}
		}
	}

	function _isOverlapped(
		uint256 newFromTimestamp,
		uint256 newToTimestamp,
		uint256 currentFromTimestamp,
		uint256 currentToTimestamp
	) internal pure returns (bool) {
		return
			!(_isPast(newToTimestamp, currentFromTimestamp) ||
				_isFuture(newFromTimestamp, currentToTimestamp));
	}

	function _isPast(uint256 newToTimestamp, uint256 currentFromTimestamp)
		internal
		pure
		returns (bool)
	{
		return newToTimestamp < currentFromTimestamp;
	}

	function _isFuture(uint256 newFromTimestamp, uint256 currentToTimestamp)
		internal
		pure
		returns (bool)
	{
		return currentToTimestamp < newFromTimestamp;
	}

	function _checkNowOnSale(string memory spaceMetadata) internal view {
		for (uint256 i = 0; i < _periodKeys[spaceMetadata].length; i++) {
			if (!allPeriods[_periodKeys[spaceMetadata][i]].sold) {
				revert("now on sale");
			}
		}
	}

	/// @dev Returns tokenIds tied with the space metadata
	/// @param spaceMetadata string of the space metadata
	function tokenIdsOf(string memory spaceMetadata)
		public
		view
		returns (uint256[] memory)
	{
		return _periodKeys[spaceMetadata];
	}
}
