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
		string accountMetadata,
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
	event ReceiveToken(
		uint256 tokenId,
		uint256 price,
		address buyer,
		uint256 timestamp
	);
	event OfferPeriod(
		string spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		address sender,
		uint256 price
	);
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
	event DenyProposal(uint256 tokenId, string metadata, string reason);
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
		address msgSender
	) external onlyProxies {
		emit Buy(tokenId, msgValue, msgSender, _blockTimestamp());
	}

	function emitBid(
		uint256 tokenId,
		uint256 msgValue,
		address msgSender
	) external onlyProxies {
		emit Bid(tokenId, msgValue, msgSender, _blockTimestamp());
	}

	function emitReceiveToken(
		uint256 tokenId,
		uint256 price,
		address buyer
	) external onlyProxies {
		emit ReceiveToken(tokenId, price, buyer, _blockTimestamp());
	}

	function emitOfferPeriod(
		string memory spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		address sender,
		uint256 price
	) external onlyProxies {
		emit OfferPeriod(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp,
			sender,
			price
		);
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
		string memory reason
	) external onlyProxies {
		emit DenyProposal(tokenId, metadata, reason);
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
		string memory accountMetadata,
		uint256 saltNonce
	) external onlyFactory {
		emit NewMedia(proxy, mediaEOA, accountMetadata, saltNonce);
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
