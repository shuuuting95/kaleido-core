// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/// @title Integers - utilities for Integers.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
library Integers {
	function parseInt(string memory _value) public pure returns (uint256 _ret) {
		bytes memory b = bytes(_value);
		uint256 i;
		_ret = 0;
		for (i = 0; i < b.length; i++) {
			uint256 c = uint8(b[i]);
			if (c >= 48 && c <= 57) {
				_ret = _ret * 10 + (c - 48);
			}
		}
	}
}
