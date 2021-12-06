// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../MediaFacade.sol";

contract MockTimeMediaFacade is MediaFacade {
	uint256 public time;

	function _blockTimestamp() internal view override returns (uint256) {
		return time;
	}

	function setTime(uint256 _time) external {
		time = _time;
	}
}
