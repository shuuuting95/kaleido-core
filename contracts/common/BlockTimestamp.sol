// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/// @title BlockTimestamp - gets a block timestamp.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract BlockTimestamp {
	/// @dev Method that exists purely to be overridden for tests
	function _blockTimestamp() internal view virtual returns (uint256) {
		return block.timestamp;
	}
}
