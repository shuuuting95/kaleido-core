// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../peripheries/MediaRegistry.sol";
import "../libraries/Ad.sol";

/// @title EventEmitter - emits events on behalf of each proxy.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract EventEmitter is NameAccessor, BlockTimestamp {
	event NewSpace(string metadata);
	event DeleteSpace(string metadata);

	event NewPeriod(
		uint256 tokenId,
		string spaceMetadata,
		string tokenMetadata,
		uint256 fromTimestamp,
		uint256 toTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	);
	event Buy(uint256 tokenId, uint256 price, address buyer, uint256 timestamp);
	event Bid(uint256 tokenId, uint256 price, address buyer, uint256 timestamp);

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	modifier onlyProxies() {
		require(_mediaRegistry().ownerOf(msg.sender) != address(0x0), "AR011");
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
		uint256 fromTimestamp,
		uint256 toTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	) external onlyProxies {
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

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view returns (MediaRegistry) {
		return MediaRegistry(mediaRegistryAddress());
	}
}
