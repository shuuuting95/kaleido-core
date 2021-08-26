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

	/// @dev Creates a new post where the owner who has the advertising area
	///      can public the space. The basic infomation of the area is described
	///      on the storage, which is accessed by the metadata hash.
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
	///      The owner of the Ad space can select the one according to not only
	///      the price but also the preference inside the metadata.
	/// @param postId uint256 of the post ID
	/// @param metadata string of the hashed path to the storage
	function bid(
		uint256 postId,
		string memory metadata,
		string memory originalLink
	) external payable;

	/// @dev Closes the offering and mints the NFT to the successful bidder.
	///      The amount would be paid to the post owner.
	/// @param bidId uint256 of the bid ID
	function close(uint256 bidId) external;

	/// @dev Can refund the amount if you want to cancel or
	///      the other is determinted as the successful bidder.
	/// @param bidId uint256 of the bid ID
	function refund(uint256 bidId) external;
}
