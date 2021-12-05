// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

library Schedule {
	function isOverlapped(
		uint256 newFromTimestamp,
		uint256 newToTimestamp,
		uint256 currentFromTimestamp,
		uint256 currentToTimestamp
	) public pure returns (bool) {
		return
			!(isPast(newToTimestamp, currentFromTimestamp) ||
				isFuture(newFromTimestamp, currentToTimestamp));
	}

	function isPast(uint256 newToTimestamp, uint256 currentFromTimestamp)
		public
		pure
		returns (bool)
	{
		return newToTimestamp < currentFromTimestamp;
	}

	function isFuture(uint256 newFromTimestamp, uint256 currentToTimestamp)
		public
		pure
		returns (bool)
	{
		return currentToTimestamp < newFromTimestamp;
	}
}
