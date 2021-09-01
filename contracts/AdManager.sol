// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./accessors/NameAccessor.sol";
import "./token/DistributionRight.sol";
import "./interfaces/IAdManager.sol";
import "./base/Vault.sol";
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
		uint8 metadataIndex;
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

	// postId => booked bidId
	mapping(uint256 => uint256) public bookedBidIds;

	// bidId => Bidder
	mapping(uint256 => Bidder) public bidderInfo;

	// EOA => metadata[]
	mapping(address => string[]) public mediaMetadata;

	// EOA => metadata => registered
	mapping(address => mapping(string => bool)) public registered;

	uint256 public nextPostId = 1;

	uint256 public nextBidId = 1;

	string private _baseURI = "https://kaleido.io/";

	constructor(address nameRegistry) NameAccessor(nameRegistry) {}

	/// @inheritdoc IAdManager
	function newPost(
		string memory metadata,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) public override {
		require(fromTimestamp < toTimestamp, "AD101");
		PostContent memory post;
		post.postId = nextPostId++;
		post.owner = msg.sender;
		post.metadata = metadata;
		post.fromTimestamp = fromTimestamp;
		post.toTimestamp = toTimestamp;
		if (!registered[msg.sender][metadata]) {
			registered[msg.sender][metadata] = true;
			mediaMetadata[msg.sender].push(metadata);
		}
		post.metadataIndex = uint8(mediaMetadata[msg.sender].length);
		allPosts[post.postId] = post;
		emit NewPost(
			post.postId,
			post.owner,
			post.metadata,
			post.metadataIndex,
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
	function book(uint256 postId) public payable override {
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

		bookedBidIds[bidder.postId] = bidId;
		bidder.status = DraftStatus.CALLED;
		payable(msg.sender).transfer(bidder.price);
		_right().mint(
			bidder.sender,
			bidder.postId,
			allPosts[bidder.postId].metadata
		);
		emit Call(bidId, bidder.postId, bidder.sender, bidder.price);
	}

	/// @inheritdoc IAdManager
	function propose(
		uint256 postId,
		string memory metadata,
		string memory originalLink
	) public override {
		uint256 bidId = bookedBidIds[postId];
		require(bidderInfo[bidId].sender == msg.sender, "AD105");

		bidderInfo[bidId].metadata = metadata;
		bidderInfo[bidId].originalLink = originalLink;
		bidderInfo[bidId].status = DraftStatus.PROPOSED;
		emit Propose(bidId, postId, metadata, originalLink);
	}

	/// @inheritdoc IAdManager
	function deny(uint256 postId) public override {
		uint256 bidId = bookedBidIds[postId];
		require(bidderInfo[bidId].status == DraftStatus.PROPOSED, "AD106");

		bidderInfo[bidId].status = DraftStatus.CALLED;
		emit Deny(bidId, postId);
	}

	/// @inheritdoc IAdManager
	function accept(uint256 postId) public override {
		require(allPosts[postId].owner == msg.sender, "AD105");

		uint256 bidId = bookedBidIds[postId];
		bidderInfo[bidId].status = DraftStatus.ACCEPTED;
		allPosts[postId].successfulBidId = bidId;
		emit Accept(postId, bidId);
	}

	/// @inheritdoc IAdManager
	function display(address account)
		public
		view
		override
		returns (string memory)
	{
		return displayBetween(account, 1, 0, nextPostId);
	}

	/// @inheritdoc IAdManager
	function displayByIndex(address account, uint8 metadataIndex)
		public
		view
		override
		returns (string memory)
	{
		return displayBetween(account, metadataIndex, 0, nextPostId);
	}

	function displayBetween(
		address account,
		uint8 metadataIndex,
		uint256 fromPostIdIndex,
		uint256 toPostIdIndex
	) public view returns (string memory) {
		for (uint256 i = fromPostIdIndex; i < toPostIdIndex; i++) {
			if (
				allPosts[i].owner == account &&
				allPosts[i].metadataIndex == metadataIndex &&
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
}
