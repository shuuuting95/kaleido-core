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
		BOOKED,
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
		DraftStatus status;
	}

	// postId => PostContent
	mapping(uint256 => PostContent) public allPosts;

	// postContents
	mapping(address => PostContent[]) public postContents;

	// postId => bidIds
	mapping(uint256 => uint256[]) public bidders;

	// postId => booked bidId
	mapping(uint256 => uint256) public bookedBidIds;

	// bidId => Bidder
	mapping(uint256 => Bidder) public bidderInfo;

	// EOA => metadata[]
	mapping(address => string[]) public mediaMetadata;

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

		for (uint256 i = 0; i < postContents[msg.sender].length; i++) {
			if (
				postContents[msg.sender][i].fromTimestamp <= post.toTimestamp &&
				postContents[msg.sender][i].toTimestamp >= post.fromTimestamp
			) {
				revert("AD101");
			}
		}

		mediaMetadata[msg.sender].push(metadata);
		allPosts[post.postId] = post;
		postContents[msg.sender].push(post);
		emit NewPost(
			post.postId,
			post.owner,
			post.metadata,
			post.fromTimestamp,
			post.toTimestamp
		);
	}

	/// @inheritdoc IAdManager
	function bid(uint256 postId, string memory metadata) public payable override {
		_bid(postId, metadata);
	}

	/// @inheritdoc IAdManager
	function book(uint256 postId) public payable override {
		_book(postId);
	}

	/// @inheritdoc IAdManager
	function close(uint256 bidId)
		public
		override
		onlyModifiablePostByBidId(bidId)
	{
		Bidder memory bidder = bidderInfo[bidId];
		require(bidder.bidId != 0, "AD103");
		require(allPosts[bidder.postId].owner == msg.sender, "AD102");
		require(allPosts[bidder.postId].successfulBidId == 0, "AD102");
		require(bidder.status == DraftStatus.LISTED, "AD102");
		_success(msg.sender, bidder.postId, bidId);
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
		Bidder memory bidder = bidderInfo[bidId];
		require(bidder.sender == msg.sender, "AD104");
		require(allPosts[bidder.postId].successfulBidId != bidId, "AD107");
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
	function call(uint256 bidId)
		public
		override
		onlyModifiablePostByBidId(bidId)
	{
		Bidder memory bidder = bidderInfo[bidId];
		require(bidder.bidId != 0, "AD103");
		require(allPosts[bidder.postId].owner == msg.sender, "AD102");
		require(allPosts[bidder.postId].successfulBidId == 0, "AD102");
		/// metadataがないこと?(BOOKEDであること)
		bookedBidIds[bidder.postId] = bidId;
		bidder.status = DraftStatus.CALLED;
		_success(msg.sender, bidId, bidder.postId);
		payable(msg.sender).transfer(bidder.price);
		_right().mint(
			bidder.sender,
			bidder.postId,
			allPosts[bidder.postId].metadata
		);
		emit Call(bidId, bidder.postId, bidder.sender, bidder.price);
	}

	/// @inheritdoc IAdManager
	function propose(uint256 postId, string memory metadata)
		public
		override
		onlyModifiablePost(postId)
	{
		require(_right().ownerOf(postId) == msg.sender, "AD105");
		uint256 bidId = bookedBidIds[postId];
		require(bidderInfo[bidId].status != DraftStatus.PROPOSED, "AD112");
		bidderInfo[bidId].metadata = metadata;
		bidderInfo[bidId].status = DraftStatus.PROPOSED;
		emit Propose(bidId, postId, metadata);
	}

	/// @inheritdoc IAdManager
	function deny(uint256 postId) public override {
		uint256 bidId = bookedBidIds[postId];
		require(allPosts[postId].owner == msg.sender, "AD111");
		require(bidderInfo[bidId].status == DraftStatus.PROPOSED, "AD106");

		bidderInfo[bidId].status = DraftStatus.DENIED;
		emit Deny(bidId, postId);
	}

	/// @inheritdoc IAdManager
	function accept(uint256 postId) public override onlyModifiablePost(postId) {
		require(allPosts[postId].owner == msg.sender, "AD105");
		uint256 bidId = bookedBidIds[postId];
		require(bidderInfo[bidId].status == DraftStatus.PROPOSED, "AD102");
		bidderInfo[bidId].status = DraftStatus.ACCEPTED;
		_success(msg.sender, postId, bidId);
		_right().burn(postId);
		emit Accept(postId, bidId);
	}

	function _success(
		address account,
		uint256 postId,
		uint256 bidId
	) internal {
		allPosts[postId].successfulBidId = bidId;
		for (uint256 i = 0; i < postContents[account].length; i++) {
			if (postContents[account][i].postId == postId) {
				postContents[account][i].successfulBidId = bidId;
			}
		}
	}

	function displayByMetadata(address account, string memory metadata)
		public
		view
		override
		returns (string memory)
	{
		for (uint256 i = 0; i < postContents[account].length; i++) {
			if (
				keccak256(abi.encodePacked(postContents[account][i].metadata)) ==
				keccak256(abi.encodePacked(metadata)) &&
				postContents[account][i].fromTimestamp < block.timestamp &&
				postContents[account][i].toTimestamp > block.timestamp
			) {
				return bidderInfo[postContents[account][i].successfulBidId].metadata;
			}
		}
		revert("AD110");
	}

	function _book(uint256 postId) internal {
		uint256 bidId = nextBidId++;
		__bid(postId, bidId, "", DraftStatus.BOOKED);
		emit Book(bidId, postId, msg.sender, msg.value);
	}

	function _bid(uint256 postId, string memory metadata) internal {
		uint256 bidId = nextBidId++;
		__bid(postId, bidId, metadata, DraftStatus.LISTED);
		emit Bid(bidId, postId, msg.sender, msg.value, metadata);
	}

	function __bid(
		uint256 postId,
		uint256 bidId,
		string memory metadata,
		DraftStatus status
	) internal onlyModifiablePost(postId) {
		require(allPosts[postId].successfulBidId == 0, "AD102");
		Bidder memory bidder;
		bidder.bidId = bidId;
		bidder.postId = postId;
		bidder.sender = msg.sender;
		bidder.price = msg.value;
		bidder.metadata = metadata;
		bidder.status = status;
		bidderInfo[bidder.bidId] = bidder;
		bidders[postId].push(bidder.bidId);
	}

	function bidderList(uint256 postId) public view returns (uint256[] memory) {
		return bidders[postId];
	}

	function metadataList() public view returns (string[] memory) {
		return mediaMetadata[msg.sender];
	}

	function _right() internal view returns (DistributionRight) {
		return DistributionRight(distributionRightAddress());
	}

	function _vault() internal view returns (Vault) {
		return Vault(payable(vaultAddress()));
	}

	/// @dev Throws if the post has been expired.
	modifier onlyModifiablePost(uint256 postId) {
		require(allPosts[postId].toTimestamp >= block.timestamp, "AD108");
		_;
	}

	/// @dev Throws if the post has been expired.
	modifier onlyModifiablePostByBidId(uint256 bidId) {
		Bidder memory bidder = bidderInfo[bidId];
		require(allPosts[bidder.postId].toTimestamp >= block.timestamp, "AD108");
		_;
	}
}
