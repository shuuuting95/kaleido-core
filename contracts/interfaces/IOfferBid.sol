// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Sale.sol";

/// @title IOfferBid
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IOfferBid {
	function offer(
		string memory spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		address sender,
		uint256 value
	) external returns (uint256);

	function cancel(uint256 tokenId, address sender) external;

	function accept(uint256 tokenId, string memory tokenMetadata)
		external
		returns (address, uint256);

	function currentPrice(uint256 tokenId) external view returns (uint256);

	function offered(uint256 tokenId) external view returns (Sale.Offer memory);
}
