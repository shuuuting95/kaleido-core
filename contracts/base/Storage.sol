// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Ad.sol";
import "../libraries/Sale.sol";
import "../libraries/Draft.sol";

/// @title Storage - saves state values. Note that the order of the state values
///                  should not be reordered when upgrading because the slot would be shifted.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract Storage {
	/// @dev Returns spaceId that is tied with space metadata.
	mapping(string => bool) public spaced;

	/// @dev tokenId <- metadata * displayStartTimestamp * displayEndTimestamp
	mapping(uint256 => Ad.Period) public periods;

	/// @dev Maps the space metadata with tokenIds of ad periods.
	mapping(string => uint256[]) internal _periodKeys;

	/// @dev Maps a tokenId with bidding info
	mapping(uint256 => Sale.Bidding) public bidding;

	/// @dev Maps a tokenId with offer info
	mapping(uint256 => Sale.Offer) public offered;

	/// @dev Maps a tokenId with appeal info
	mapping(uint256 => Sale.Appeal[]) public appealed;

	/// @dev The total bidding value
	uint256 internal _biddingTotal;

	/// @dev The total value offered by users
	uint256 internal _offeredTotal;

	/// @dev Maps a tokenId with the proposal content.
	mapping(uint256 => Draft.Proposal) public proposed;

	/// @dev Maps a tokenId with denied reasons.
	mapping(uint256 => Draft.Denied[]) public deniedReasons;

	/// @dev Maps a tokenId with the content metadata.
	mapping(uint256 => string) public accepted;
}
