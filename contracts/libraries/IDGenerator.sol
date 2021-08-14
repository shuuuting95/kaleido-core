// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

library IDGenerator {
	uint256 private constant ID_CAP = 10000000000000000;

	function computePostId(string memory metadata, uint256 blockNumber)
		public
		pure
		returns (uint256)
	{
		return uint256(keccak256(abi.encodePacked(blockNumber, metadata))) % ID_CAP;
	}

	function computeBidId(uint256 postId, string memory metadata)
		public
		pure
		returns (uint256)
	{
		return uint256(keccak256(abi.encodePacked(postId, metadata))) % ID_CAP;
	}
}
