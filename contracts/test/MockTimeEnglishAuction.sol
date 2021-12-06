// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../peripheries/EnglishAuction.sol";

contract MockTimeEnglishAuction is EnglishAuction {
	uint256 public time;

	constructor(address _nameRegistry) EnglishAuction(_nameRegistry) {}

	function _blockTimestamp() internal view override returns (uint256) {
		return time;
	}

	function setTime(uint256 _time) external {
		time = _time;
	}
}
