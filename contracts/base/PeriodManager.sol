// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./SpaceManager.sol";
import "../libraries/Ad.sol";
import "../libraries/Schedule.sol";

/// @title PeriodManager - manages ad periods.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract PeriodManager is SpaceManager {
	/// @dev tokenId <- metadata * displayStartTimestamp * displayEndTimestamp
	mapping(uint256 => Ad.Period) public periods;

	/// @dev Maps the space metadata with tokenIds of ad periods.
	mapping(string => uint256[]) internal _periodKeys;

	function _checkOverlapping(
		string memory metadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp
	) internal view {
		for (uint256 i = 0; i < _periodKeys[metadata].length; i++) {
			Ad.Period memory existing = periods[_periodKeys[metadata][i]];
			if (
				Schedule._isOverlapped(
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

	function _deletePeriod(uint256 tokenId) internal {
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
		_adPool().deletePeriod(tokenId);
	}

	function _savePeriod(
		string memory spaceMetadata,
		uint256 tokenId,
		Ad.Period memory period
	) internal {
		_periodKeys[spaceMetadata].push(tokenId);
		periods[tokenId] = period;
		_adPool().addPeriod(tokenId, period);
	}

	function _checkNowOnSale(string memory spaceMetadata) internal view {
		for (uint256 i = 0; i < _periodKeys[spaceMetadata].length; i++) {
			if (!periods[_periodKeys[spaceMetadata][i]].sold) {
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
