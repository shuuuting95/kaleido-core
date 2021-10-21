// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

library IDGenerator {
	uint256 private constant ID_CAP = 10000000000000000;

	function computePostId(
		string memory metadata,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) public pure returns (uint256) {
		return
			uint256(
				keccak256(abi.encodePacked(metadata, fromTimestamp, toTimestamp))
			) % ID_CAP;
	}
}
