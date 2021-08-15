// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../libraries/IDGenerator.sol";
import "../accessors/NameAccessor.sol";
import "../token/DistributionRight.sol";
import "../interfaces/IAdManager.sol";
import "./Vault.sol";
import "hardhat/console.sol";

/// @title AdManager - allows anyone to create a post and bit to the post.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdManager is IAdManager, NameAccessor {
	struct PostContent {
		uint256 postId;
		address owner;
		string metadataURI;
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
		string metadataURI;
	}

	// postId => PostContent
	mapping(uint256 => PostContent) public allPosts;

	// postId => bidIds
	mapping(uint256 => uint256[]) public bidders;

	// bidId => Bidder
	mapping(uint256 => Bidder) public bidderInfo;

	constructor(address nameRegistry) NameAccessor(nameRegistry) {}

	/// @inheritdoc IAdManager
	function newPost(
		string memory metadataURI,
		uint256 initialPrice,
		uint256 periodHours
	) public override {
		PostContent memory post;
		post.postId = IDGenerator.computePostId(metadataURI, block.number);
		post.owner = msg.sender;
		post.metadataURI = metadataURI;
		post.currentPrice = initialPrice;
		post.periodHours = periodHours;
		post.startTime = block.timestamp;
		post.endTime = block.timestamp + periodHours;
		allPosts[post.postId] = post;
		emit NewPost(
			post.postId,
			post.owner,
			post.metadataURI,
			post.currentPrice,
			post.periodHours = periodHours,
			post.startTime,
			post.endTime
		);
	}

	/// @inheritdoc IAdManager
	function bid(uint256 postId, string memory metadataURI)
		public
		payable
		override
	{
		require(allPosts[postId].endTime > block.timestamp, "AD101");

		Bidder memory bidder;
		bidder.bidId = IDGenerator.computeBidId(postId, metadataURI);
		bidder.postId = postId;
		bidder.sender = msg.sender;
		bidder.price = msg.value;
		bidder.metadataURI = metadataURI;
		bidderInfo[bidder.bidId] = bidder;
		bidders[postId].push(bidder.bidId);
		emit Bid(
			bidder.bidId,
			bidder.postId,
			bidder.sender,
			bidder.price,
			bidder.metadataURI
		);
	}

	/// @inheritdoc IAdManager
	function close(uint256 bidId) public override {
		Bidder memory bidder = bidderInfo[bidId];
		require(bidder.bidId != 0, "AD103");
		require(allPosts[bidder.postId].owner == msg.sender, "AD102");

		allPosts[bidder.postId].successfulBidder = bidder.sender;
		payable(msg.sender).transfer((bidder.price * 9) / 10);
		payable(_vault()).transfer((bidder.price * 1) / 10);
		_right().mint(bidder.sender, bidId, allPosts[bidder.postId].metadataURI);
		emit Close(
			bidder.bidId,
			bidder.postId,
			bidder.sender,
			bidder.price,
			bidder.metadataURI
		);
	}

	/// @inheritdoc IAdManager
	function refund(uint256 bidId) public override {
		require(bidderInfo[bidId].sender == msg.sender, "AD104");

		payable(msg.sender).transfer(bidderInfo[bidId].price);
		emit Refund(
			bidId,
			bidderInfo[bidId].postId,
			msg.sender,
			bidderInfo[bidId].price
		);
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
		return DistributionRight(distributionRightAddress());
	}

	function _vault() internal view returns (Vault) {
		return Vault(payable(vaultAddress()));
	}
}
