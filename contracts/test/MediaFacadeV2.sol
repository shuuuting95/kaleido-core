// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../MediaFacade.sol";

contract MediaFacadeV2 is MediaFacade {
	string public spaceDataV2;
	uint256 public time;

	function newSpace(string memory spaceMetadata)
		external
		virtual
		override
		onlyMedia
	{
		_adPool().addSpace(spaceMetadata);
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
