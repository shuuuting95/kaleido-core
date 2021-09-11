// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

/// @title IAdManager - Interface on top of AdManager base class.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IAdManager {
	/// @dev Emitted when a new post is created.
	event NewPost(
		uint256 postId,
		address owner,
		uint256 minPrice,
		string metadata,
		uint256 fromTimestamp,
		uint256 toTimestamp
	);

	/// @dev Emitted when a post is updated.
	event UpdatePost(
		uint256 postId,
		address owner,
		uint256 minPrice,
		string metadata,
		uint256 fromTimestamp,
		uint256 toTimestamp
	);

	/// @dev Emitted when a post is suspended.
	event SuspendPost(uint256 postId);

	/// @dev Emitted when a new bid is listed.
	event Bid(
		uint256 bidId,
		uint256 postId,
		address sender,
		uint256 price,
		string metadata
	);

	/// @dev Emitted when a new book is listed.
	event Book(uint256 bidId, uint256 postId, address sender, uint256 price);

	/// @dev Emitted when a post owner decides which one is the successful bidder.
	event Close(
		uint256 bitId,
		uint256 postId,
		address successfulBidder,
		uint256 price,
		string metadata
	);

	/// @dev Emitted when a post owner withdraws the deposited amount.
	event Withdraw(uint256 postId, uint256 achievedPercent, uint256 amount);

	/// @dev Emitted when a bidder refunds.
	event Refund(uint256 bitId, uint256 postId, address sender, uint256 price);

	/// @dev Emitted when a reservation is temporarily approved.
	event Call(uint256 bidId, uint256 postId, address sender, uint256 price);

	/// @dev Emitted when a proposed content is submitted.
	event Propose(uint256 bidId, uint256 postId, string metadata);

	/// @dev Emitted when a proposal is denied.
	event Deny(uint256 bidId, uint256 postId);

	/// @dev Emitted when a proposal is accepted.
	event Accept(uint256 postId, uint256 bidId);

	/// @dev Emitted when a bidder claims the redemption.
	event ClaimRedemption(
		uint256 postId,
		uint256 redemptionPercent,
		uint256 amount
	);

	/// @dev Creates a new post where the owner who has the advertising area
	/// can public the space. The basic infomation of the area is described
	/// on the storage, which is accessed by the metadata hash.
	/// @param minPrice uint256 of the minimum price to bid or book
	/// @param metadata string of the hashed path to the storage
	/// @param fromTimestamp uint256 of the timestamp to display the ad
	/// @param toTimestamp uint256 of the timestamp to display the ad
	function newPost(
		uint256 minPrice,
		string memory metadata,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) external;

	/// @dev Updates a post. This function is only called when no one
	/// bits or books to the post. You can choose suspendPost if it has
	/// already been bidded.
	/// @param postId uint256 of the post ID
	/// @param minPrice uint256 of the minimum price to bid or book
	/// @param metadata string of the hashed path to the storage
	/// @param fromTimestamp uint256 of the timestamp to display the ad
	/// @param toTimestamp uint256 of the timestamp to display the ad
	function updatePost(
		uint256 postId,
		uint256 minPrice,
		string memory metadata,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) external;

	/// @dev Suspends a post.
	/// @param postId uint256 of the post ID
	function suspendPost(uint256 postId) external;

	/// @dev Bids to the post, sharing what kind of Ads would be public.
	/// The owner of the Ad space can select the one according to not only
	/// the price but also the preference inside the metadata.
	/// @param postId uint256 of the post ID
	/// @param metadata string of the hashed path to the storage
	function bid(uint256 postId, string memory metadata) external payable;

	/// @dev Books to the post without any specific metadata.
	/// @param postId uint256 of the post ID
	function book(uint256 postId) external payable;

	/// @dev Closes the offering and mints the NFT to the successful bidder.
	/// The amount would be paid to the post owner.
	/// @param bidId uint256 of the bid ID
	function close(uint256 bidId) external;

	/// @dev Withdraws the deposited amount by the successful bidder.
	/// @param postId uint256 of the post ID
	function withdraw(uint256 postId) external;

	/// @dev Claims a redemption if the accept is behind the shcedule.
	/// @param postId uint256 of the post ID
	function claimRedemption(uint256 postId) external;

	/// @dev Can refund the amount if you want to cancel or
	/// the other is determinted as the successful bidder.
	/// @param bidId uint256 of the bid ID
	function refund(uint256 bidId) external;

	/// @dev Calls the book related with the bidId. The NFT representing a right to propose
	/// is sent to the bidder in this function.
	/// @param bidId uint256 of the bid ID
	function call(uint256 bidId) external;

	/// @dev Proposes metadata to the book.
	/// @param postId uint256 of the post ID
	/// @param metadata string of the hashed path to the storage
	function propose(uint256 postId, string memory metadata) external;

	/// @dev Denies the proposal if you dislike the content.
	/// @param postId uint256 of the post ID
	function deny(uint256 postId) external;

	/// @dev Accepts the proposal if you like the content.
	/// @param postId uint256 of the post ID
	function accept(uint256 postId) external;

	/// @dev Returns metadata hash that the account is supposed to deliver.
	/// @param account address of the post owner
	/// @param metadata string of the media metadata
	function displayByMetadata(address account, string memory metadata)
		external
		view
		returns (string memory);
}
