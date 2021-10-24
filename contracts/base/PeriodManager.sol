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
	/// @dev Maps the spaceId with tokenIds of ad periods.
	mapping(bytes32 => uint256[]) public periodKeys;

	/// @dev tokenId <- metadata * displayStartTimestamp * displayEndTimestamp
	mapping(uint256 => Ad.Period) public allPeriods;

	function _checkOverlapping(
		string memory metadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp
	) internal view {
		for (uint256 i = 0; i < periodKeys[spaceId[metadata]].length; i++) {
			Ad.Period memory existing = allPeriods[periodKeys[spaceId[metadata]][i]];
			if (
				_isOverlapped(
					displayStartTimestamp,
					displayEndTimestamp,
					existing.displayStartTimestamp,
					existing.displayEndTimestamp
				)
			) {
				revert("KD101");
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
			!(newFromTimestamp > currentToTimestamp ||
				newToTimestamp < currentFromTimestamp);
	}

	function _checkNowOnSale(string memory spaceMetadata) internal view {
		for (uint256 i = 0; i < periodKeys[spaceId[spaceMetadata]].length; i++) {
			if (!allPeriods[periodKeys[spaceId[spaceMetadata]][i]].sold) {
				revert("now on sale");
			}
		}
	}
}
