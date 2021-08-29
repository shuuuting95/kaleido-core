// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../accessors/NameAccessor.sol";
import "../token/DistributionRight.sol";
import "../interfaces/IAdManager.sol";
import "./Vault.sol";
import "./AdPool.sol";
import "hardhat/console.sol";

/// @title AdManager - allows anyone to create a post and bit to the post.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdManager is IAdManager, NameAccessor {
	enum DraftStatus {
		LISTED,
		CALLED,
		PROPOSED,
		DENIED,
		ACCEPTED,
		REFUNDED
	}

	struct PostContent {
		uint256 postId;
		address owner;
		string metadata;
		uint256 width;
		uint256 height;
		uint256 fromTimestamp;
		uint256 toTimestamp;
		uint256 successfulBidId;
	}

	struct Bidder {
		uint256 bidId;
		uint256 postId;
		address sender;
		uint256 price;
		string metadata;
		string originalLink;
		DraftStatus status;
	}

	// postId => PostContent
	mapping(uint256 => PostContent) public allPosts;

	// postId => bidIds
	mapping(uint256 => uint256[]) public bidders;

	// postId => reserved bidId
	mapping(uint256 => uint256) public reservedBidIds;

	// bidId => Bidder
	mapping(uint256 => Bidder) public bidderInfo;

	uint256 public nextPostId = 1;

	uint256 public nextBidId = 1;

	string private _baseURI = "https://kaleido.io/";

	constructor(address nameRegistry) NameAccessor(nameRegistry) {}

	/// @inheritdoc IAdManager
	function newPost(
		string memory metadata,
		uint256 width,
		uint256 height,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) public override {
		require(fromTimestamp < toTimestamp, "AD101");
		PostContent memory post;
		post.postId = nextPostId++;
		post.owner = msg.sender;
		post.metadata = metadata;
		post.width = width;
		post.height = height;
		post.fromTimestamp = fromTimestamp;
		post.toTimestamp = toTimestamp;
		allPosts[post.postId] = post;
		_right().mint(msg.sender, post.postId, metadata);
		emit NewPost(
			post.postId,
			post.owner,
			post.metadata,
			post.width,
			post.height,
			post.fromTimestamp,
			post.toTimestamp
		);
	}

	/// @inheritdoc IAdManager
	function bid(
		uint256 postId,
		string memory metadata,
		string memory originalLink
	) public payable override {
		require(allPosts[postId].successfulBidId == 0, "AD102");
		_bid(postId, metadata, originalLink);
	}

	/// @inheritdoc IAdManager
	function reserve(uint256 postId) public payable override {
		require(allPosts[postId].successfulBidId == 0, "AD102");
		_bid(postId, "", "");
	}

	/// @inheritdoc IAdManager
	function close(uint256 bidId) public override {
		Bidder memory bidder = bidderInfo[bidId];
		require(bidder.bidId != 0, "AD103");
		require(allPosts[bidder.postId].owner == msg.sender, "AD102");

		allPosts[bidder.postId].successfulBidId = bidId;
		bidder.status = DraftStatus.ACCEPTED;
		payable(msg.sender).transfer((bidder.price * 9) / 10);
		payable(_vault()).transfer((bidder.price * 1) / 10);
		_right().transferByAllowedContract(
			msg.sender,
			bidder.sender,
			bidder.postId
		);
		emit Close(
			bidder.bidId,
			bidder.postId,
			bidder.sender,
			bidder.price,
			bidder.metadata
		);
	}

	/// @inheritdoc IAdManager
	function refund(uint256 bidId) public override {
		require(bidderInfo[bidId].sender == msg.sender, "AD104");

		payable(msg.sender).transfer(bidderInfo[bidId].price);
		bidderInfo[bidId].status = DraftStatus.REFUNDED;
		emit Refund(
			bidId,
			bidderInfo[bidId].postId,
			msg.sender,
			bidderInfo[bidId].price
		);
	}

	/// @inheritdoc IAdManager
	function call(uint256 bidId) public override {
		Bidder memory bidder = bidderInfo[bidId];
		require(bidder.bidId != 0, "AD103");
		require(allPosts[bidder.postId].owner == msg.sender, "AD102");

		reservedBidIds[bidder.postId] = bidId;
		bidder.status = DraftStatus.CALLED;
		_right().transferByAllowedContract(
			msg.sender,
			adPoolAddress(),
			bidder.postId
		);
		payable(adPoolAddress()).transfer(bidder.price);
		emit Call(bidId, bidder.postId, bidder.sender, bidder.price);
	}

	/// @inheritdoc IAdManager
	function propose(
		uint256 postId,
		string memory metadata,
		string memory originalLink
	) public override {
		uint256 bidId = reservedBidIds[postId];
		require(bidderInfo[bidId].sender == msg.sender, "AD105");

		bidderInfo[bidId].metadata = metadata;
		bidderInfo[bidId].originalLink = originalLink;
		bidderInfo[bidId].status = DraftStatus.PROPOSED;
		emit Propose(bidId, postId, metadata, originalLink);
	}

	/// @inheritdoc IAdManager
	function deny(uint256 postId) public override {
		uint256 bidId = reservedBidIds[postId];
		require(bidderInfo[bidId].status == DraftStatus.PROPOSED, "AD106");

		bidderInfo[bidId].status = DraftStatus.CALLED;
		emit Deny(bidId, postId);
	}

	/// @inheritdoc IAdManager
	function recall(uint256 postId, uint256 toBidId) public override {
		require(allPosts[postId].owner == msg.sender, "AD105");

		uint256 fromBidId = reservedBidIds[postId];
		Bidder memory currentBidder = bidderInfo[fromBidId];
		Bidder memory nextBidder = bidderInfo[toBidId];
		require(currentBidder.price < nextBidder.price, "AD107");
		require(currentBidder.status == DraftStatus.CALLED, "AD108");

		bidderInfo[fromBidId].status = DraftStatus.DENIED;
		bidderInfo[toBidId].status = DraftStatus.CALLED;
		reservedBidIds[postId] = toBidId;

		_pool().receivePooledAmount(currentBidder.sender, currentBidder.price);
		payable(adPoolAddress()).transfer((nextBidder.price * 99) / 100);
		payable(currentBidder.sender).transfer(currentBidder.price / 100);
		emit Recall(postId, fromBidId, toBidId);
	}

	/// @inheritdoc IAdManager
	function accept(uint256 postId) public override {
		require(allPosts[postId].owner == msg.sender, "AD105");

		_right().transferByAllowedContract(adPoolAddress(), msg.sender, postId);
		uint256 bidId = reservedBidIds[postId];
		_pool().receivePooledAmount(msg.sender, bidderInfo[bidId].price);
		bidderInfo[bidId].status = DraftStatus.ACCEPTED;
		allPosts[postId].successfulBidId = bidId;
		emit Accept(postId, bidId);
	}

	/// @inheritdoc IAdManager
	function updateMetadata(uint256 postId, string memory metadata)
		public
		override
	{
		uint256 bidId = reservedBidIds[postId];
		bidderInfo[bidId].metadata = metadata;
	}

	/// @inheritdoc IAdManager
	function display(
		address account,
		uint256 fromPostIdIndex,
		uint256 toPostIdIndex
	) public view override returns (string memory) {
		for (uint256 i = fromPostIdIndex; i < toPostIdIndex; i++) {
			if (
				allPosts[i].owner == account &&
				allPosts[i].fromTimestamp < block.timestamp &&
				allPosts[i].toTimestamp > block.timestamp
			) {
				return bidderInfo[allPosts[i].successfulBidId].metadata;
			}
		}
		revert("AD");
	}

	function _bid(
		uint256 postId,
		string memory metadata,
		string memory originalLink
	) public payable {
		Bidder memory bidder;
		bidder.bidId = nextBidId++;
		bidder.postId = postId;
		bidder.sender = msg.sender;
		bidder.price = msg.value;
		bidder.metadata = metadata;
		bidder.originalLink = originalLink;
		bidder.status = DraftStatus.LISTED;
		bidderInfo[bidder.bidId] = bidder;
		bidders[postId].push(bidder.bidId);
		emit Bid(
			bidder.bidId,
			bidder.postId,
			bidder.sender,
			bidder.price,
			bidder.metadata,
			bidder.originalLink
		);
	}

	function bidderList(uint256 postId) public view returns (uint256[] memory) {
		return bidders[postId];
	}

	function _right() internal view returns (DistributionRight) {
		return DistributionRight(distributionRightAddress());
	}

	function _vault() internal view returns (Vault) {
		return Vault(payable(vaultAddress()));
	}

	function _pool() internal view returns (AdPool) {
		return AdPool(payable(adPoolAddress()));
	}
}
