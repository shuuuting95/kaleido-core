// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./accessors/NameAccessor.sol";
import "./base/MediaRegistry.sol";
import "./base/AdPool.sol";
import "./base/PeriodManager.sol";
import "./base/DistributionRight.sol";
import "./base/BlockTimestamp.sol";
import "hardhat/console.sol";

/// @title AdManager - manages ad spaces and its periods to sell them to users.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdManager is DistributionRight, PeriodManager, BlockTimestamp {
	event Buy(uint256 tokenId, uint256 price, address buyer, uint256 timestamp);
	event Bid(uint256 tokenId, uint256 price, address buyer, uint256 timestamp);
	event ReceiveToken(
		uint256 tokenId,
		uint256 price,
		address buyer,
		uint256 timestamp
	);
	event Propose(uint256 tokenId, string metadata);
	event Accept(uint256 tokenId);
	event Deny(uint256 tokenId, string reason);
	event Withdraw(uint256 amount);

	struct Bidding {
		uint256 tokenId;
		address bidder;
		uint256 price;
	}

	/// @dev Maps tokenId with bidding info
	mapping(uint256 => Bidding) public bidding;

	modifier onlyMedia() {
		require(_mediaRegistry().ownerOf(address(this)) == msg.sender, "KD012");
		_;
	}

	/// @dev Creates a new space for the media account.
	/// @param spaceMetadata string of the space metadata
	function newSpace(string memory spaceMetadata) external onlyMedia {
		_newSpace(spaceMetadata);
	}

	/// @dev Updates metadata.
	/// @param oldMetadata string of the old space metadata
	/// @param newMetadata string of the new space metadata
	function updateSpace(string memory oldMetadata, string memory newMetadata)
		external
		onlyMedia
	{
		bytes32 spaceId = _deleteSpace(oldMetadata);
		_link(newMetadata, spaceId);
	}

	/// @dev Deletes a space.
	/// @param spaceMetadata string of the space metadata
	function deleteSpace(string memory spaceMetadata) external onlyMedia {
		_checkNowOnSale(spaceMetadata);
		_deleteSpace(spaceMetadata);
	}

	function _checkNowOnSale(string memory spaceMetadata) internal view {
		for (uint256 i = 0; i < periodKeys[spaceId[spaceMetadata]].length; i++) {
			if (!allPeriods[periodKeys[spaceId[spaceMetadata]][i]].sold) {
				revert("now on sale");
			}
		}
	}

	/// @dev Create a new period for a space. This function requires some params
	///      to decide which kinds of pricing way and how much price to get started.
	/// @param spaceMetadata string of the space metadata
	/// @param tokenMetadata string of the token metadata
	/// @param fromTimestamp uint256 of the start timestamp for the display
	/// @param toTimestamp uint256 of the end timestamp for the display
	/// @param pricing uint256 of the pricing way
	/// @param minPrice uint256 of the minimum price to sell it out
	function newPeriod(
		string memory spaceMetadata,
		string memory tokenMetadata,
		uint256 fromTimestamp,
		uint256 toTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	) external onlyMedia {
		require(fromTimestamp < toTimestamp, "KD103");
		require(toTimestamp > _blockTimestamp(), "KD104");
		if (spaceId[spaceMetadata] == 0) {
			_newSpace(spaceMetadata);
		}
		_checkOverlapping(spaceMetadata, fromTimestamp, toTimestamp);
		uint256 tokenId = Ad.id(spaceMetadata, fromTimestamp, toTimestamp);
		periodKeys[spaceId[spaceMetadata]].push(tokenId);
		Ad.Period memory period = Ad.Period(
			address(this),
			spaceMetadata,
			tokenMetadata,
			_blockTimestamp(),
			fromTimestamp,
			toTimestamp,
			pricing,
			minPrice,
			0,
			false
		);
		period.startPrice = _startPrice(period);
		allPeriods[tokenId] = period;
		_mintRight(tokenId, tokenMetadata);
		_adPool().addPeriod(tokenId, period);
		emit NewPeriod(
			tokenId,
			spaceMetadata,
			tokenMetadata,
			fromTimestamp,
			toTimestamp,
			pricing,
			minPrice
		);
	}

	function buy(uint256 tokenId) external payable {
		require(allPeriods[tokenId].pricing == Ad.Pricing.RRP, "not RRP");
		require(!allPeriods[tokenId].sold, "has already sold");
		require(
			_mediaRegistry().ownerOf(address(this)) != msg.sender,
			"is the owner"
		);
		require(allPeriods[tokenId].minPrice == msg.value, "inappropriate amount");
		allPeriods[tokenId].sold = true;
		_soldRight(tokenId);
		payable(vaultAddress()).transfer(msg.value / 10);
		emit Buy(tokenId, msg.value, msg.sender, _blockTimestamp());
	}

	function buyBasedOnTime(uint256 tokenId) external payable {
		require(allPeriods[tokenId].pricing == Ad.Pricing.DPBT, "not DPBT");
		require(!allPeriods[tokenId].sold, "has already sold");
		require(
			_mediaRegistry().ownerOf(address(this)) != msg.sender,
			"is the owner"
		);
		require(currentPrice(tokenId) <= msg.value, "low price");
		allPeriods[tokenId].sold = true;
		_soldRight(tokenId);
		payable(vaultAddress()).transfer(msg.value / 10);
		emit Buy(tokenId, msg.value, msg.sender, _blockTimestamp());
	}

	function bid(uint256 tokenId) external payable {
		require(allPeriods[tokenId].pricing == Ad.Pricing.BIDDING, "not BIDDING");
		require(!allPeriods[tokenId].sold, "has already sold");
		require(
			_mediaRegistry().ownerOf(address(this)) != msg.sender,
			"is the owner"
		);
		require(currentPrice(tokenId) <= msg.value, "low price");
		// TODO: avoid reentrancy
		payable(bidding[tokenId].bidder).transfer(bidding[tokenId].price);
		bidding[tokenId] = Bidding(tokenId, msg.sender, msg.value);
		// TODO: save history on AdPool
		emit Bid(tokenId, msg.value, msg.sender, _blockTimestamp());
	}

	modifier onlySuccessfulBidder(uint256 tokenId) {
		require(bidding[tokenId].bidder == msg.sender, "is not successful bidder");
		_;
	}

	function receiveToken(uint256 tokenId)
		external
		payable
		onlySuccessfulBidder(tokenId)
	{
		require(allPeriods[tokenId].pricing == Ad.Pricing.BIDDING, "not BIDDING");
		require(!allPeriods[tokenId].sold, "has already sold");

		allPeriods[tokenId].sold = true;
		_soldRight(tokenId);
		payable(vaultAddress()).transfer(bidding[tokenId].price / 10);
		emit ReceiveToken(
			tokenId,
			bidding[tokenId].price,
			msg.sender,
			_blockTimestamp()
		);
	}

	function currentPrice(uint256 tokenId) public view returns (uint256) {
		Ad.Period memory period = allPeriods[tokenId];
		if (period.pricing == Ad.Pricing.RRP) {
			return period.minPrice;
		}
		if (period.pricing == Ad.Pricing.DPBT) {
			return
				period.startPrice -
				((period.startPrice - period.minPrice) *
					(_blockTimestamp() - period.salesStartTimestamp)) /
				(period.fromTimestamp - period.salesStartTimestamp);
		}
		if (period.pricing == Ad.Pricing.BIDDING) {
			return bidding[tokenId].price;
		}
		revert("not exist");
	}

	function withdraw() external onlyMedia {
		uint256 remained = address(this).balance;
		payable(msg.sender).transfer(remained);
		emit Withdraw(remained);
	}

	function propose(uint256 tokenId, string memory metadata) external {
		_proposeToRight(tokenId, metadata);
		emit Propose(tokenId, metadata);
	}

	function accept(uint256 tokenId) external {
		_burnRight(tokenId);
		emit Accept(tokenId);
	}

	function deny(uint256 tokenId, string memory reason) external {
		deniedReason[tokenId] = reason;
		emit Deny(tokenId, reason);
	}

	function adId(
		string memory metadata,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) public pure returns (uint256) {
		return Ad.id(metadata, fromTimestamp, toTimestamp);
	}

	function balance() public view returns (uint256) {
		return address(this).balance;
	}

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view returns (MediaRegistry) {
		return MediaRegistry(mediaRegistryAddress());
	}

	function _adPool() internal view returns (AdPool) {
		return AdPool(adPoolAddress());
	}
}

// /// @title AdManager - allows anyone to create a post and bit to the post.
// /// @author Shumpei Koike - <shumpei.koike@bridges.inc>
// contract AdManager is IAdManager, NameAccessor {
// 	enum DraftStatus {
// 		BOOKED,
// 		LISTED,
// 		CALLED,
// 		PROPOSED,
// 		DENIED,
// 		ACCEPTED,
// 		REFUNDED
// 	}

// 	struct PostContent {
// 		uint256 postId;
// 		address owner;
// 		uint256 minPrice;
// 		string metadata;
// 		uint256 fromTimestamp;
// 		uint256 toTimestamp;
// 		uint256 successfulBidId;
// 	}
// 	struct Bidder {
// 		uint256 bidId;
// 		uint256 postId;
// 		address sender;
// 		uint256 price;
// 		string metadata;
// 		DraftStatus status;
// 	}

// 	// postId => PostContent
// 	mapping(uint256 => PostContent) public allPosts;

// 	// postContents
// 	mapping(address => mapping(string => uint256[])) public inventories;

// 	// postId => bidIds
// 	mapping(uint256 => uint256[]) public bidders;

// 	// postId => booked bidId
// 	mapping(uint256 => uint256) public bookedBidIds;

// 	// bidId => Bidder
// 	mapping(uint256 => Bidder) public bidderInfo;

// 	// EOA => metadata[]
// 	mapping(address => string[]) public mediaMetadata;

// 	uint256 public nextPostId = 1;

// 	uint256 public nextBidId = 1;

// 	string private _baseURI = "https://kaleido.io/";

// 	/// @dev Throws if the post has been expired.
// 	modifier onlyModifiablePost(uint256 postId) {
// 		require(allPosts[postId].toTimestamp >= _blockTimestamp(), "AD108");
// 		_;
// 	}

// 	/// @dev Throws if the post has been expired.
// 	modifier onlyModifiablePostByBidId(uint256 bidId) {
// 		Bidder memory bidder = bidderInfo[bidId];
// 		require(allPosts[bidder.postId].toTimestamp >= _blockTimestamp(), "AD108");
// 		_;
// 	}

// 	constructor(address nameRegistry) NameAccessor(nameRegistry) {}

// 	/// @inheritdoc IAdManager
// 	function newPost(
// 		uint256 minPrice,
// 		string memory metadata,
// 		uint256 fromTimestamp,
// 		uint256 toTimestamp
// 	) public override {
// 		require(fromTimestamp < toTimestamp, "AD101");
// 		require(toTimestamp > _blockTimestamp(), "AD114");
// 		PostContent memory post;
// 		post.postId = nextPostId++;
// 		post.owner = msg.sender;
// 		post.minPrice = minPrice;
// 		post.metadata = metadata;
// 		post.fromTimestamp = fromTimestamp;
// 		post.toTimestamp = toTimestamp;

// 		for (
// 			uint256 i = 0;
// 			i < inventories[msg.sender][post.metadata].length;
// 			i++
// 		) {
// 			PostContent memory another = allPosts[
// 				inventories[msg.sender][post.metadata][i]
// 			];
// 			if (
// 				_isOverlapped(
// 					fromTimestamp,
// 					toTimestamp,
// 					another.fromTimestamp,
// 					another.toTimestamp
// 				)
// 			) {
// 				revert("AD101");
// 			}
// 		}

// 		mediaMetadata[msg.sender].push(metadata);
// 		allPosts[post.postId] = post;
// 		inventories[msg.sender][post.metadata].push(post.postId);
// 		_postOwnerPool().addPost(post.postId, post.owner);
// 		emit NewPost(
// 			post.postId,
// 			post.owner,
// 			post.minPrice,
// 			post.metadata,
// 			post.fromTimestamp,
// 			post.toTimestamp
// 		);
// 	}

// 	/// @inheritdoc IAdManager
// 	function suspendPost(uint256 postId) public override {
// 		require(allPosts[postId].owner == msg.sender, "AD111");
// 		require(allPosts[postId].successfulBidId == 0, "");
// 		allPosts[postId].fromTimestamp = 0;
// 		allPosts[postId].toTimestamp = 0;
// 		emit SuspendPost(postId);
// 	}

// 	function _isOverlapped(
// 		uint256 fromTimestamp,
// 		uint256 toTimestamp,
// 		uint256 anotherFromTimestamp,
// 		uint256 anotherToTimestamp
// 	) internal pure returns (bool) {
// 		return
// 			anotherFromTimestamp <= toTimestamp &&
// 			anotherToTimestamp >= fromTimestamp;
// 	}

// 	/// @inheritdoc IAdManager
// 	function bid(uint256 postId, string memory metadata) public payable override {
// 		_bid(postId, metadata);
// 	}

// 	/// @inheritdoc IAdManager
// 	function book(uint256 postId) public payable override {
// 		_book(postId);
// 	}

// 	/// @inheritdoc IAdManager
// 	function close(uint256 bidId)
// 		public
// 		override
// 		onlyModifiablePostByBidId(bidId)
// 	{
// 		Bidder memory bidder = bidderInfo[bidId];
// 		require(bidder.bidId != 0, "AD103");
// 		require(allPosts[bidder.postId].owner == msg.sender, "AD102");
// 		require(allPosts[bidder.postId].successfulBidId == 0, "AD102");
// 		require(bidder.status == DraftStatus.LISTED, "AD102");
// 		_success(bidder.postId, bidId);
// 		bidder.status = DraftStatus.ACCEPTED;
// 		payable(msg.sender).transfer((bidder.price * 9) / 10);
// 		payable(_vault()).transfer((bidder.price * 1) / 10);
// 		emit Close(
// 			bidder.bidId,
// 			bidder.postId,
// 			bidder.sender,
// 			bidder.price,
// 			bidder.metadata
// 		);
// 	}

// 	/// @inheritdoc IAdManager
// 	function refund(uint256 bidId) public override {
// 		Bidder memory bidder = bidderInfo[bidId];
// 		require(bidder.sender == msg.sender, "AD104");
// 		require(allPosts[bidder.postId].successfulBidId != bidId, "AD107");
// 		require(bidderInfo[bidId].status != DraftStatus.REFUNDED, "AD119");

// 		payable(msg.sender).transfer(bidderInfo[bidId].price);
// 		bidderInfo[bidId].status = DraftStatus.REFUNDED;
// 		emit Refund(
// 			bidId,
// 			bidderInfo[bidId].postId,
// 			msg.sender,
// 			bidderInfo[bidId].price
// 		);
// 	}

// 	/// @inheritdoc IAdManager
// 	function call(uint256 bidId)
// 		public
// 		override
// 		onlyModifiablePostByBidId(bidId)
// 	{
// 		Bidder memory bidder = bidderInfo[bidId];
// 		require(bidder.bidId != 0, "AD103");
// 		require(allPosts[bidder.postId].owner == msg.sender, "AD102");
// 		require(allPosts[bidder.postId].successfulBidId == 0, "AD113");
// 		require(bidder.status == DraftStatus.BOOKED, "AD102");
// 		bookedBidIds[bidder.postId] = bidId;
// 		bidder.status = DraftStatus.CALLED;
// 		_success(bidder.postId, bidId);
// 		payable(msg.sender).transfer(bidder.price);
// 		_right().mint(
// 			bidder.sender,
// 			bidder.postId,
// 			allPosts[bidder.postId].metadata
// 		);
// 		emit Call(bidId, bidder.postId, bidder.sender, bidder.price);
// 	}

// 	/// @inheritdoc IAdManager
// 	function propose(uint256 postId, string memory metadata)
// 		public
// 		override
// 		onlyModifiablePost(postId)
// 	{
// 		require(_right().ownerOf(postId) == msg.sender, "AD105");
// 		uint256 bidId = bookedBidIds[postId];
// 		require(bidderInfo[bidId].status != DraftStatus.PROPOSED, "AD112");
// 		bidderInfo[bidId].metadata = metadata;
// 		bidderInfo[bidId].status = DraftStatus.PROPOSED;
// 		emit Propose(bidId, postId, metadata);
// 	}

// 	/// @inheritdoc IAdManager
// 	function deny(uint256 postId) public override {
// 		uint256 bidId = bookedBidIds[postId];
// 		require(allPosts[postId].owner == msg.sender, "AD111");
// 		require(bidderInfo[bidId].status == DraftStatus.PROPOSED, "AD106");

// 		bidderInfo[bidId].status = DraftStatus.DENIED;
// 		emit Deny(bidId, postId);
// 	}

// 	/// @inheritdoc IAdManager
// 	function accept(uint256 postId) public override onlyModifiablePost(postId) {
// 		require(allPosts[postId].owner == msg.sender, "AD105");
// 		uint256 bidId = bookedBidIds[postId];
// 		require(bidderInfo[bidId].status == DraftStatus.PROPOSED, "AD102");
// 		bidderInfo[bidId].status = DraftStatus.ACCEPTED;
// 		_right().burn(postId);
// 		emit Accept(postId, bidId);
// 	}

// 	function _success(uint256 postId, uint256 bidId) internal {
// 		allPosts[postId].successfulBidId = bidId;
// 	}

// 	function isGteMinPrice(uint256 postId, uint256 price)
// 		public
// 		view
// 		returns (bool)
// 	{
// 		return price >= allPosts[postId].minPrice;
// 	}

// 	function displayByMetadata(address account, string memory metadata)
// 		public
// 		view
// 		override
// 		returns (string memory)
// 	{
// 		for (uint256 i = 0; i < inventories[account][metadata].length; i++) {
// 			if (
// 				withinTheDurationOfOnDisplay(
// 					allPosts[inventories[account][metadata][i]]
// 				)
// 			) {
// 				return
// 					bidderInfo[
// 						allPosts[inventories[account][metadata][i]].successfulBidId
// 					].metadata;
// 			}
// 		}
// 		revert("AD110");
// 	}

// 	function withinTheDurationOfOnDisplay(PostContent memory post)
// 		internal
// 		view
// 		returns (bool)
// 	{
// 		return
// 			post.fromTimestamp < _blockTimestamp() &&
// 			post.toTimestamp > _blockTimestamp();
// 	}

// 	function bidderList(uint256 postId) public view returns (uint256[] memory) {
// 		return bidders[postId];
// 	}

// 	function metadataList() public view returns (string[] memory) {
// 		return mediaMetadata[msg.sender];
// 	}

// 	function _book(uint256 postId) internal {
// 		uint256 bidId = nextBidId++;
// 		__bid(postId, bidId, "", DraftStatus.BOOKED);
// 		emit Book(bidId, postId, msg.sender, msg.value);
// 	}

// 	function _bid(uint256 postId, string memory metadata) internal {
// 		uint256 bidId = nextBidId++;
// 		__bid(postId, bidId, metadata, DraftStatus.LISTED);
// 		emit Bid(bidId, postId, msg.sender, msg.value, metadata);
// 	}

// 	function __bid(
// 		uint256 postId,
// 		uint256 bidId,
// 		string memory metadata,
// 		DraftStatus status
// 	) internal onlyModifiablePost(postId) {
// 		require(allPosts[postId].successfulBidId == 0, "AD102");
// 		require(isGteMinPrice(postId, msg.value), "AD115");
// 		Bidder memory bidder;
// 		bidder.bidId = bidId;
// 		bidder.postId = postId;
// 		bidder.sender = msg.sender;
// 		bidder.price = msg.value;
// 		bidder.metadata = metadata;
// 		bidder.status = status;
// 		bidderInfo[bidder.bidId] = bidder;
// 		bidders[postId].push(bidder.bidId);
// 	}

// 	function _right() internal view returns (DistributionRight) {
// 		return DistributionRight(distributionRightAddress());
// 	}

// 	function _vault() internal view returns (Vault) {
// 		return Vault(payable(vaultAddress()));
// 	}

// 	function _postOwnerPool() internal view returns (PostOwnerPool) {
// 		return PostOwnerPool(postOwnerPoolAddress());
// 	}
// }
