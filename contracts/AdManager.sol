// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./base/PricingStrategy.sol";
import "./base/DistributionRight.sol";
import "hardhat/console.sol";

/// @title AdManager - manages ad spaces and its periods to sell them to users.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdManager is DistributionRight, PricingStrategy, ReentrancyGuard {
	/// @dev Can call it by only the media
	modifier onlyMedia() {
		require(_mediaRegistry().ownerOf(address(this)) == msg.sender, "KD012");
		_;
	}

	/// @dev Prevents the media from calling by yourself
	modifier notYourself() {
		require(
			_mediaRegistry().ownerOf(address(this)) != msg.sender,
			"is the owner"
		);
		_;
	}

	/// @dev Called by the successful bidder
	modifier onlySuccessfulBidder(uint256 tokenId) {
		require(bidding[tokenId].bidder == msg.sender, "is not successful bidder");
		_;
	}

	/// @dev Can call it only once
	modifier initializer() {
		require(address(_nameRegistry) == address(0x0), "AR000");
		_;
	}

	/// @dev Initialize the instance.
	/// @param title string of the title of the instance
	/// @param baseURI string of the base URI
	/// @param nameRegistry address of NameRegistry
	function initialize(
		string memory title,
		string memory baseURI,
		address nameRegistry
	) external {
		_name = title;
		_symbol = string(abi.encodePacked("Kaleido_", title));
		_baseURI = baseURI;
		initialize(nameRegistry);
	}

	/// @dev Creates a new space for the media account.
	/// @param spaceMetadata string of the space metadata
	function newSpace(string memory spaceMetadata) external onlyMedia {
		_newSpace(spaceMetadata);
	}

	/// @dev Create a new period for a space. This function requires some params
	///      to decide which kinds of pricing way and how much price to get started.
	/// @param spaceMetadata string of the space metadata
	/// @param tokenMetadata string of the token metadata
	/// @param saleEndTimestamp uint256 of the end timestamp for the sale
	/// @param displayStartTimestamp uint256 of the start timestamp for the display
	/// @param displayEndTimestamp uint256 of the end timestamp for the display
	/// @param pricing uint256 of the pricing way
	/// @param minPrice uint256 of the minimum price to sell it out
	function newPeriod(
		string memory spaceMetadata,
		string memory tokenMetadata,
		uint256 saleEndTimestamp,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	) external onlyMedia {
		require(saleEndTimestamp > _blockTimestamp(), "KD111");
		require(saleEndTimestamp < displayStartTimestamp, "KD112");
		require(displayStartTimestamp < displayEndTimestamp, "KD113");

		if (!spaced[spaceMetadata]) {
			_newSpace(spaceMetadata);
		}
		_checkOverlapping(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp
		);
		uint256 tokenId = Ad.id(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp
		);
		_periodKeys[spaceMetadata].push(tokenId);
		Ad.Period memory period = Ad.Period(
			address(this),
			spaceMetadata,
			tokenMetadata,
			_blockTimestamp(),
			saleEndTimestamp,
			displayStartTimestamp,
			displayEndTimestamp,
			pricing,
			minPrice,
			0,
			false
		);
		period.startPrice = _startPrice(period);
		allPeriods[tokenId] = period;
		_mintRight(tokenId, tokenMetadata);
		_adPool().addPeriod(tokenId, period);
		_eventEmitter().emitNewPeriod(
			tokenId,
			spaceMetadata,
			tokenMetadata,
			_blockTimestamp(),
			saleEndTimestamp,
			displayStartTimestamp,
			displayEndTimestamp,
			pricing,
			minPrice
		);
	}

	/// @dev Deletes a period and its token.
	///      If there is any users locking the fund for the sale, the amount would be transfered
	///      to the user when deleting the period.
	/// @param tokenId uint256 of the token ID
	function deletePeriod(uint256 tokenId) external onlyMedia {
		require(allPeriods[tokenId].mediaProxy != address(0), "KD114");
		_refundLockedAmount(tokenId);
		delete allPeriods[tokenId];
		_burnRight(tokenId);
		_adPool().deletePeriod(tokenId);
		_eventEmitter().emitDeletePeriod(tokenId);
	}

	/// @dev Buys the token that is defined as the specific period on an ad space.
	///      The price of the token is fixed.
	/// @param tokenId uint256 of the token ID
	function buy(uint256 tokenId) external payable notYourself {
		_checkBeforeBuy(tokenId);
		allPeriods[tokenId].sold = true;
		_dropToken(tokenId);
		_collectFees();
		_eventEmitter().emitBuy(tokenId, msg.value, msg.sender);
	}

	/// @dev Buys the token that is defined as the specific period on an ad space.
	///      The price is decreasing as time goes by.
	/// @param tokenId uint256 of the token ID
	function buyBasedOnTime(uint256 tokenId) external payable notYourself {
		_checkBeforeBuyBasedOnTime(tokenId);
		allPeriods[tokenId].sold = true;
		_dropToken(tokenId);
		_collectFees();
		_eventEmitter().emitBuy(tokenId, msg.value, msg.sender);
	}

	function bid(uint256 tokenId) external payable notYourself nonReentrant {
		_checkBeforeBid(tokenId);
		payable(bidding[tokenId].bidder).transfer(bidding[tokenId].price);
		bidding[tokenId] = Bidding(tokenId, msg.sender, msg.value);
		// TODO: save history on AdPool
		_eventEmitter().emitBid(tokenId, msg.value, msg.sender);
	}

	function receiveToken(uint256 tokenId)
		external
		payable
		onlySuccessfulBidder(tokenId)
	{
		_checkBeforeReceiveToken(tokenId);
		allPeriods[tokenId].sold = true;
		_dropToken(tokenId);
		_collectFees();
		_eventEmitter().emitReceiveToken(
			tokenId,
			bidding[tokenId].price,
			msg.sender
		);
	}

	/// @dev Withdraws the fund deposited to the proxy contract.
	function withdraw() external onlyMedia {
		uint256 remained = address(this).balance;
		payable(msg.sender).transfer(remained);
		_eventEmitter().emitWithdraw(remained);
	}

	/// @dev Proposes the metadata to the token you bought.
	///      Users can propose many times as long as it is accepted.
	/// @param tokenId uint256 of the token ID
	/// @param metadata string of the proposal metadata
	function propose(uint256 tokenId, string memory metadata) external {
		require(ownerOf(tokenId) == msg.sender, "KD012");
		_proposeToRight(tokenId, metadata);
		_eventEmitter().emitPropose(tokenId, metadata);
	}

	/// @dev Accepts the proposal.
	/// @param tokenId uint256 of the token ID
	function accept(uint256 tokenId) external onlyMedia {
		string memory metadata = proposed[tokenId];
		require(bytes(metadata).length != 0, "KD130");
		_burnRight(tokenId);
		_clearProposal(tokenId);
		_eventEmitter().emitAcceptProposal(tokenId, metadata);
	}

	/// @dev Denies the submitted proposal, mentioning what is the problem.
	/// @param tokenId uint256 of the token ID
	/// @param reason string of the reason why it is rejected
	function deny(uint256 tokenId, string memory reason) external {
		string memory metadata = proposed[tokenId];
		require(bytes(metadata).length != 0, "KD130");
		deniedReason[tokenId] = reason;
		_eventEmitter().emitDenyProposal(tokenId, metadata, reason);
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

	function _checkBeforeReceiveToken(uint256 tokenId) internal view {
		require(allPeriods[tokenId].pricing == Ad.Pricing.BIDDING, "not BIDDING");
		require(!allPeriods[tokenId].sold, "has already sold");
	}

	function _collectFees() internal {
		payable(vaultAddress()).transfer(msg.value / 10);
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
