// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../peripheries/MediaRegistry.sol";
import "../libraries/Ad.sol";

/// @title EventEmitter - emits events on behalf of each proxy.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract EventEmitter is NameAccessor, BlockTimestamp {
	/// @dev Emitted when a new media is created.
	event NewMedia(
		address proxy,
		address mediaEOA,
		string applicationMetadata,
		string updatableMetadata,
		uint256 saltNonce
	);
	event UpdateMedia(address proxy, address mediaEOA, string accountMetadata);
	event NewSpace(string metadata);
	event DeleteSpace(string metadata);
	event NewPeriod(
		uint256 tokenId,
		string spaceMetadata,
		string tokenMetadata,
		uint256 saleStartTimestamp,
		uint256 saleEndTimestamp,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	);
	event DeletePeriod(uint256 tokenId);
	event Buy(uint256 tokenId, uint256 price, address buyer, uint256 timestamp);
	event Bid(uint256 tokenId, uint256 price, address buyer, uint256 timestamp);
	event BidWithProposal(
		uint256 tokenId,
		uint256 price,
		address sender,
		string metadata,
		uint256 timestamp
	);
	event SelectProposal(uint256 tokenId, address successfulBidder);
	event ReceiveToken(
		uint256 tokenId,
		uint256 price,
		address buyer,
		uint256 timestamp
	);
	event OfferPeriod(
		uint256 tokenId,
		string spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		address sender,
		uint256 price
	);
	event CancelOffer(uint256 tokenId);
	event AcceptOffer(
		uint256 tokenId,
		string spaceMetadata,
		string tokenMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		uint256 price
	);
	event Withdraw(uint256 amount);
	event Propose(uint256 tokenId, string metadata);
	event AcceptProposal(uint256 tokenId, string metadata);
	event DenyProposal(
		uint256 tokenId,
		string metadata,
		string reason,
		bool offensive
	);
	event TransferCustom(
		address indexed from,
		address indexed to,
		uint256 indexed tokenId
	);

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	modifier onlyProxies() {
		require(_mediaRegistry().ownerOf(msg.sender) != address(0x0), "KD011");
		_;
	}

	function emitNewSpace(string memory metadata) external onlyProxies {
		emit NewSpace(metadata);
	}

	function emitDeleteSpace(string memory metadata) external onlyProxies {
		emit DeleteSpace(metadata);
	}

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
	) external onlyProxies {
		emit NewPeriod(
			tokenId,
			spaceMetadata,
			tokenMetadata,
			saleStartTimestamp,
			saleEndTimestamp,
			displayStartTimestamp,
			displayEndTimestamp,
			pricing,
			minPrice
		);
	}

	function emitDeletePeriod(uint256 tokenId) external onlyProxies {
		emit DeletePeriod(tokenId);
	}

	function emitBuy(
		uint256 tokenId,
		uint256 msgValue,
		address msgSender,
		uint256 blockTimestamp
	) external onlyProxies {
		emit Buy(tokenId, msgValue, msgSender, blockTimestamp);
	}

	function emitBid(
		uint256 tokenId,
		uint256 msgValue,
		address msgSender,
		uint256 blockTimestamp
	) external onlyProxies {
		emit Bid(tokenId, msgValue, msgSender, blockTimestamp);
	}

	function emitBidWithProposal(
		uint256 tokenId,
		uint256 msgValue,
		address msgSender,
		string memory metadata,
		uint256 blockTimestamp
	) external onlyProxies {
		emit BidWithProposal(
			tokenId,
			msgValue,
			msgSender,
			metadata,
			blockTimestamp
		);
	}

	function emitSelectProposal(uint256 tokenId, address successfulBidder)
		external
		onlyProxies
	{
		emit SelectProposal(tokenId, successfulBidder);
	}

	function emitReceiveToken(
		uint256 tokenId,
		uint256 price,
		address buyer,
		uint256 blockTimestamp
	) external onlyProxies {
		emit ReceiveToken(tokenId, price, buyer, blockTimestamp);
	}

	function emitOfferPeriod(
		uint256 tokenId,
		string memory spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		address sender,
		uint256 price
	) external onlyProxies {
		emit OfferPeriod(
			tokenId,
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp,
			sender,
			price
		);
	}

	function emitCancelOffer(uint256 tokenId) external onlyProxies {
		emit CancelOffer(tokenId);
	}

	function emitAcceptOffer(
		uint256 tokenId,
		string memory spaceMetadata,
		string memory tokenMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		uint256 price
	) external onlyProxies {
		emit AcceptOffer(
			tokenId,
			spaceMetadata,
			tokenMetadata,
			displayStartTimestamp,
			displayEndTimestamp,
			price
		);
	}

	function emitWithdraw(uint256 amount) external onlyProxies {
		emit Withdraw(amount);
	}

	function emitPropose(uint256 tokenId, string memory metadata)
		external
		onlyProxies
	{
		emit Propose(tokenId, metadata);
	}

	function emitAcceptProposal(uint256 tokenId, string memory metadata)
		external
		onlyProxies
	{
		emit AcceptProposal(tokenId, metadata);
	}

	function emitDenyProposal(
		uint256 tokenId,
		string memory metadata,
		string memory reason,
		bool offensive
	) external onlyProxies {
		emit DenyProposal(tokenId, metadata, reason, offensive);
	}

	function emitTransferCustom(
		address from,
		address to,
		uint256 tokenId
	) external onlyProxies {
		emit TransferCustom(from, to, tokenId);
	}

	function emitNewMedia(
		address proxy,
		address mediaEOA,
		string memory applicationMetadata,
		string memory updatableMetadata,
		uint256 saltNonce
	) external onlyFactory {
		emit NewMedia(
			proxy,
			mediaEOA,
			applicationMetadata,
			updatableMetadata,
			saltNonce
		);
	}

	function emitUpdateMedia(
		address proxy,
		address mediaEOA,
		string memory accountMetadata
	) external onlyProxies {
		emit UpdateMedia(proxy, mediaEOA, accountMetadata);
	}

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view returns (MediaRegistry) {
		return MediaRegistry(mediaRegistryAddress());
	}
}
