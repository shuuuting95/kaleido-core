// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../peripheries/OpenBid.sol";

contract MockTimeOpenBid is OpenBid {
	uint256 public time;

	constructor(address _nameRegistry) OpenBid(_nameRegistry) {}

	function _blockTimestamp() internal view override returns (uint256) {
		return time;
	}

	function setTime(uint256 _time) external {
		time = _time;
	}
}
