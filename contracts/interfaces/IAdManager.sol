// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

/// @title IAdManager - Interface on top of AdManager base class.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IAdManager {
	/// @dev Emitted when a new post is created.
	event NewPost(
		uint256 postId,
		address owner,
		string metadata,
		uint256 width,
		uint256 height,
		uint256 fromTimestamp,
		uint256 toTimestamp
	);

	/// @dev Emitted when a new bid is listed.
	event Bid(
		uint256 bidId,
		uint256 postId,
		address sender,
		uint256 price,
		string metadata,
		string originalLink
	);

	/// @dev Emitted when the post owner decides which one is the successful bidder.
	event Close(
		uint256 bitId,
		uint256 postId,
		address successfulBidder,
		uint256 price,
		string metadata
	);

	/// @dev Emitted when the bidder execute refunding.
	event Refund(uint256 bitId, uint256 postId, address sender, uint256 price);

	/// @dev Emitted when a reservation is approved temporarily.
	event Call(uint256 bidId, uint256 postId, address sender, uint256 price);

	/// @dev Emitted when a proposed content is submitted.
	event Propose(
		uint256 bidId,
		uint256 postId,
		string metadata,
		string originalLink
	);

	/// @dev Emitted when a proposal is denied and a new bidder is selected.
	event Recall(uint256 postId, uint256 fromBidId, uint256 toBidId);

	/// @dev Emitted when a proposal is accepted.
	event Accept(uint256 postId, uint256 bidId);

	/// @dev Creates a new post where the owner who has the advertising area
	/// can public the space. The basic infomation of the area is described
	/// on the storage, which is accessed by the metadata hash.
	/// @param metadata string of the hashed path to the storage
	/// @param width uint256 of the display width for the Ad space
	/// @param height uint256 of the display height for the Ad space
	/// @param fromTimestamp uint256 of the timestamp to display the ad
	/// @param toTimestamp uint256 of the timestamp to display the ad
	function newPost(
		string memory metadata,
		uint256 width,
		uint256 height,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) external;

	/// @dev Bids to the post, sharing what kind of Ads would be public.
	/// The owner of the Ad space can select the one according to not only
	/// the price but also the preference inside the metadata.
	/// @param postId uint256 of the post ID
	/// @param metadata string of the hashed path to the storage
	function bid(
		uint256 postId,
		string memory metadata,
		string memory originalLink
	) external payable;

	function reserve(uint256 postId) external payable;

	/// @dev Closes the offering and mints the NFT to the successful bidder.
	/// The amount would be paid to the post owner.
	/// @param bidId uint256 of the bid ID
	function close(uint256 bidId) external;

	/// @dev Can refund the amount if you want to cancel or
	/// the other is determinted as the successful bidder.
	/// @param bidId uint256 of the bid ID
	function refund(uint256 bidId) external;

	function call(uint256 bidId) external;

	function propose(
		uint256 postId,
		string memory metadata,
		string memory originalLink
	) external;

	function recall(uint256 postId, uint256 toBidId) external;

	function deny(uint256 postId) external;

	function accept(uint256 postId) external;

	function updateMetadata(uint256 postId, string memory metadata) external;

	function display(
		address account,
		uint256 fromPostIdIndex,
		uint256 toPostIdIndex
	) external view returns (string memory);
}
