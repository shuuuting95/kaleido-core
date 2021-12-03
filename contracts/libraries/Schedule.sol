// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

library Schedule {
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
}
