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

	/// @dev tokenId <- metadata * fromTimestamp * toTimestamp
	mapping(uint256 => Ad.Period) public allPeriods;

	function _checkOverlapping(
		string memory metadata,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) internal view {
		for (uint256 i = 0; i < periodKeys[spaceId[metadata]].length; i++) {
			Ad.Period memory existing = allPeriods[periodKeys[spaceId[metadata]][i]];
			if (
				_isOverlapped(
					fromTimestamp,
					toTimestamp,
					existing.fromTimestamp,
					existing.toTimestamp
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

	function _startPrice(Ad.Period memory period)
		internal
		pure
		returns (uint256)
	{
		if (period.pricing == Ad.Pricing.RRP) {
			return period.minPrice;
		} else if (period.pricing == Ad.Pricing.DPBT) {
			return period.minPrice * 10;
		} else if (period.pricing == Ad.Pricing.BIDDING) {
			return period.minPrice;
		} else {
			return 0;
		}
	}
}
