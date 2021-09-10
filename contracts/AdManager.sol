// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./accessors/NameAccessor.sol";
import "./base/PostOwnerPool.sol";
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
		uint256 minPrice;
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
	mapping(address => mapping(string => uint256[])) public inventories;

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
		uint256 minPrice,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) public override {
		require(fromTimestamp < toTimestamp, "AD101");
		require(toTimestamp > block.timestamp, "AD114");
		PostContent memory post;
		post.postId = nextPostId++;
		post.minPrice = minPrice;
		post.owner = msg.sender;
		post.metadata = metadata;
		post.fromTimestamp = fromTimestamp;
		post.toTimestamp = toTimestamp;

		for (
			uint256 i = 0;
			i < inventories[msg.sender][post.metadata].length;
			i++
		) {
			PostContent memory another = allPosts[
				inventories[msg.sender][post.metadata][i]
			];
			if (
				_isOverlapped(
					fromTimestamp,
					toTimestamp,
					another.fromTimestamp,
					another.toTimestamp
				)
			) {
				revert("AD101");
			}
		}

		mediaMetadata[msg.sender].push(metadata);
		allPosts[post.postId] = post;
		inventories[msg.sender][post.metadata].push(post.postId);
		_postOwnerPool().addPost(post.postId, post.owner);
		emit NewPost(
			post.postId,
			post.minPrice,
			post.owner,
			post.metadata,
			post.fromTimestamp,
			post.toTimestamp
		);
	}

	function updatePost() public {}

	function _isOverlapped(
		uint256 fromTimestamp,
		uint256 toTimestamp,
		uint256 anotherFromTimestamp,
		uint256 anotherToTimestamp
	) internal pure returns (bool) {
		return
			anotherFromTimestamp <= toTimestamp &&
			anotherToTimestamp >= fromTimestamp;
	}

	function isHigherThanMinPrice(uint256 postId, uint256 price)
		public
		view
		returns (bool)
	{
		return allPosts[postId].minPrice < price;
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
		_success(bidder.postId, bidId);
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
		require(allPosts[bidder.postId].successfulBidId == 0, "AD113");
		require(bidder.status == DraftStatus.BOOKED, "AD102");
		bookedBidIds[bidder.postId] = bidId;
		bidder.status = DraftStatus.CALLED;
		_success(bidder.postId, bidId);
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
		_right().burn(postId);
		emit Accept(postId, bidId);
	}

	function _success(uint256 postId, uint256 bidId) internal {
		allPosts[postId].successfulBidId = bidId;
	}

	function displayByMetadata(address account, string memory metadata)
		public
		view
		override
		returns (string memory)
	{
		for (uint256 i = 0; i < inventories[account][metadata].length; i++) {
			if (
				withinTheDurationOfOnDisplay(
					allPosts[inventories[account][metadata][i]]
				)
			) {
				return
					bidderInfo[
						allPosts[inventories[account][metadata][i]].successfulBidId
					].metadata;
			}
		}
		revert("AD110");
	}

	function withinTheDurationOfOnDisplay(PostContent memory post)
		internal
		view
		returns (bool)
	{
		return
			post.fromTimestamp < block.timestamp &&
			post.toTimestamp > block.timestamp;
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
		require(isHigherThanMinPrice(postId, msg.value), "AD115");
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

	function _postOwnerPool() internal view returns (PostOwnerPool) {
		return PostOwnerPool(postOwnerPoolAddress());
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
