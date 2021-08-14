// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../libraries/IDGenerator.sol";
import "../access/NameAccessor.sol";
import "../token/DistributionRight.sol";
import "hardhat/console.sol";

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

	event NewPost(
		uint256 postId,
		address owner,
		string metadata,
		uint256 currentPrice,
		uint256 periodHours,
		uint256 startTime,
		uint256 endTime
	);

	event Bid(
		uint256 bidId,
		uint256 postId,
		address sender,
		uint256 price,
		string metadata
	);

	event Close(
		uint256 bitId,
		uint256 postId,
		address successfulBidder,
		uint256 price,
		string metadata
	);

	// postId => PostContent
	mapping(uint256 => PostContent) public allPosts;

	// postId => bidIds
	mapping(uint256 => uint256[]) public bidders;

	// bidId => Bidder
	mapping(uint256 => Bidder) public bidderInfo;

	constructor(address nameRegistry) NameAccessor(nameRegistry) {}

	function newPost(
		string memory metadata,
		uint256 initialPrice,
		uint256 periodHours
	) public {
		PostContent memory post;
		post.postId = IDGenerator.computePostId(metadata, block.number);
		post.owner = msg.sender;
		post.metadata = metadata;
		post.currentPrice = initialPrice;
		post.periodHours = periodHours;
		post.startTime = block.timestamp;
		post.endTime = block.timestamp + periodHours;
		allPosts[post.postId] = post;
		emit NewPost(
			post.postId,
			post.owner,
			post.metadata,
			post.currentPrice,
			post.periodHours = periodHours,
			post.startTime,
			post.endTime
		);
	}

	function bid(uint256 postId, string memory metadata) public payable {
		require(allPosts[postId].endTime > block.timestamp, "AD101");
		Bidder memory bidder;
		bidder.bidId = IDGenerator.computeBidId(postId, metadata);
		bidder.postId = postId;
		bidder.sender = msg.sender;
		bidder.price = msg.value;
		bidder.metadata = metadata;
		bidderInfo[bidder.bidId] = bidder;
		bidders[postId].push(bidder.bidId);
		emit Bid(
			bidder.bidId,
			bidder.postId,
			bidder.sender,
			bidder.price,
			bidder.metadata
		);
	}

	function close(uint256 bidId) public {
		Bidder memory bidder = bidderInfo[bidId];
		require(bidder.bidId != 0, "AD103");
		require(allPosts[bidder.postId].owner == msg.sender, "AD102");
		// require(allPosts[bidder.postId].endTime > block.timestamp, "AD105");

		allPosts[bidder.postId].successfulBidder = bidder.sender;
		payable(msg.sender).transfer((bidder.price * 9) / 10);
		payable(owner()).transfer((bidder.price * 1) / 10);
		_right().mint(bidder.sender, bidId);
		emit Close(
			bidder.bidId,
			bidder.postId,
			bidder.sender,
			bidder.price,
			bidder.metadata
		);
	}

	function refund(uint256 bidId) public {
		require(bidderInfo[bidId].sender == msg.sender, "AD104");
		require(
			allPosts[bidderInfo[bidId].postId].endTime < block.timestamp,
			"AD105"
		);
		payable(msg.sender).transfer(bidderInfo[bidId].price);
	}

	function bidderList(uint256 postId) public view returns (uint256[] memory) {
		return bidders[postId];
	}

	function computePostId(string memory metadata, uint256 blockNumber)
		public
		pure
		returns (uint256)
	{
		return IDGenerator.computePostId(metadata, blockNumber);
	}

	function computeBidId(uint256 postId, string memory metadata)
		public
		pure
		returns (uint256)
	{
		return IDGenerator.computeBidId(postId, metadata);
	}

	function _right() internal view returns (DistributionRight) {
		return DistributionRight(distributionRight());
	}
}
