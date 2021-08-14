// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../libraries/IDGenerator.sol";
import "../access/NameAccessor.sol";
import "../token/DistributionRight.sol";

contract AdManager is NameAccessor {
	struct PostContent {
		uint256 postId;
		address owner; // TODO:ERC721
		string metadata;
		uint256 currentPrice;
		uint256 periodHours;
		uint256 startTime;
		uint256 endTime;
		address successfulBidder;
	}

	struct Bidder {
		uint256 bidId;
		uint256 postId;
		address sender;
		uint256 price;
		string metadata;
	}

	// postId => PostContent
	mapping(uint256 => PostContent) public allPosts;
	// postId => Bidders
	mapping(uint256 => Bidder[]) public allBidders;
	// bidId => Bidder
	mapping(uint256 => Bidder) public bidderInfo;

	constructor(address nameRegistry) NameAccessor(nameRegistry) {}

	function newPost(
		string memory metadata,
		uint256 currentPrice,
		uint256 periodHours
	) public {
		PostContent memory post;
		post.postId = IDGenerator.computePostId(metadata, block.number);
		post.metadata = metadata;
		post.currentPrice = currentPrice;
		post.startTime = block.timestamp;
		post.endTime = block.timestamp + periodHours;
		allPosts[post.postId] = post;
	}

	function bid(uint256 postId, string memory metadata) public payable {
		require(allPosts[postId].endTime > block.timestamp, "AD101");
		Bidder memory bidder;
		bidder.bidId = IDGenerator.computeBidId(postId, metadata);
		bidder.postId = postId;
		bidder.sender = msg.sender;
		bidder.price = msg.value;
		bidder.metadata = metadata;
		allBidders[postId].push(bidder);
	}

	function close(uint256 bidId) public {
		Bidder memory bidder = bidderInfo[bidId];
		require(bidder.bidId != 0, "AD103");
		require(allPosts[bidder.postId].owner == msg.sender, "AD102");

		payable(msg.sender).transfer((bidder.price * 9) / 10);
		payable(owner()).transfer((bidder.price * 1) / 10);
		_right().mint(bidder.sender, bidId);
	}

	function refund(uint256 bidId) public {
		require(bidderInfo[bidId].sender == msg.sender, "AD104");
		payable(msg.sender).transfer(bidderInfo[bidId].price);
	}

	function _right() internal view returns (DistributionRight) {
		return DistributionRight(distributionRight());
	}
}
