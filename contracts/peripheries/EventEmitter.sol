// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../peripheries/MediaRegistry.sol";
import "../libraries/Ad.sol";

/// @title EventEmitter - emits events on behalf of each proxy.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract EventEmitter is NameAccessor {
	event NewPeriod(
		uint256 tokenId,
		string spaceMetadata,
		string tokenMetadata,
		uint256 fromTimestamp,
		uint256 toTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	);

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	modifier onlyProxies() {
		require(_mediaRegistry().ownerOf(msg.sender) != address(0x0), "AR011");
		_;
	}

	function emitNewPeriod(
		uint256 tokenId,
		string memory spaceMetadata,
		string memory tokenMetadata,
		uint256 fromTimestamp,
		uint256 toTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	) public onlyProxies {
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

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view returns (MediaRegistry) {
		return MediaRegistry(mediaRegistryAddress());
	}
}
