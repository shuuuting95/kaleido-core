// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../AdManager.sol";

contract AdManagerV2 is AdManager {
	string public spaceDataV2;
	uint256 public time;

	function newSpace(string memory spaceMetadata)
		external
		virtual
		override
		onlyMedia
	{
		_newSpace(spaceMetadata);
		spaceDataV2 = "additional state";
	}

	function getAdditional() public view returns (string memory) {
		return spaceDataV2;
	}

	function _blockTimestamp() internal view override returns (uint256) {
		return time;
	}

	function setTime(uint256 _time) external {
		time = _time;
	}
}
