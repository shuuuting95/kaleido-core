// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../libraries/IDGenerator.sol";

contract AdManager {
	struct PostContent {
		uint256 postId;
		string metadata;
		uint256 currentPrice;
		uint256 periodHours;
		uint256 startTime;
		uint256 endTime;
		address successfulBidder;
	}

	mapping(uint256 => PostContent) public allPosts;

	function newPost(
		string memory metadata,
		uint256 currentPrice,
		uint256 periodHours
	) public {
		PostContent memory post;
		post.postId = IDGenerator.postId(metadata, block.number);
		post.metadata = metadata;
		post.currentPrice = currentPrice;
		post.startTime = block.timestamp;
		post.endTime = block.timestamp + periodHours;
		allPosts[post.postId] = post;
	}
}
