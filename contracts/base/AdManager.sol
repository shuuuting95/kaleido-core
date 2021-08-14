// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../libraries/IDGenerator.sol";
import "../access/NameAccessor.sol";
import "../token/DistributionRight.sol";

contract AdManager is NameAccessor {
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

	constructor(address nameRegistry) NameAccessor(nameRegistry) {}

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
		_right().mint(msg.sender, post.postId);
	}

	function _right() internal view returns (DistributionRight) {
		return DistributionRight(distributionRight());
	}
}
