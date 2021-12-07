// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../libraries/Ad.sol";

/// @title IEventEmitter - emits events.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IEventEmitter {
	function emitNewSpace(string memory metadata) external;

	function emitNewPeriod(
		uint256 tokenId,
		string memory spaceMetadata,
		string memory tokenMetadata,
		uint256 saleStartTimestamp,
		uint256 saleEndTimestamp,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	) external;

	function emitDeletePeriod(uint256 tokenId) external;

	function emitBuy(
		uint256 tokenId,
		uint256 msgValue,
		address msgSender,
		uint256 blockTimestamp
	) external;

	function emitBid(
		uint256 tokenId,
		uint256 msgValue,
		address msgSender,
		uint256 blockTimestamp
	) external;

	function emitBidWithProposal(
		uint256 tokenId,
		uint256 msgValue,
		address msgSender,
		string memory metadata,
		uint256 blockTimestamp
	) external;

	function emitSelectProposal(
		uint256 tokenId,
		address successfulBidder,
		string memory reason
	) external;

	function emitReceiveToken(
		uint256 tokenId,
		uint256 price,
		address buyer,
		uint256 blockTimestamp
	) external;

	function emitOfferPeriod(
		uint256 tokenId,
		string memory spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		address sender,
		uint256 price
	) external;

	function emitCancelOffer(uint256 tokenId) external;

	function emitAcceptOffer(
		uint256 tokenId,
		string memory spaceMetadata,
		string memory tokenMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		uint256 price
	) external;

	function emitWithdraw(uint256 amount) external;

	function emitPropose(uint256 tokenId, string memory metadata) external;

	function emitAcceptProposal(uint256 tokenId, string memory metadata) external;

	function emitDenyProposal(
		uint256 tokenId,
		string memory metadata,
		string memory reason,
		bool offensive
	) external;

	function emitTransferCustom(
		address from,
		address to,
		uint256 tokenId
	) external;

	function emitNewMedia(
		address proxy,
		address mediaEOA,
		string memory applicationMetadata,
		string memory updatableMetadata,
		uint256 saltNonce
	) external;

	function emitUpdateMedia(
		address proxy,
		address mediaEOA,
		string memory accountMetadata
	) external;

	function emitPaymentFailure(address receiver, uint256 price) external;

	function emitReceived(address receiver, uint256 price) external;
}
