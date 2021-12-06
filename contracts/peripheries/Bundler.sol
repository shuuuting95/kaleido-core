// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../base/ERC721.sol";
import "../peripheries/AdPool.sol";
import "../peripheries/Vault.sol";
import "../libraries/Integers.sol";
import "../libraries/Substrings.sol";
import "../MediaFacade.sol";
import "hardhat/console.sol";

// TODO: needed to be updated for production
/// @title Bundler - makes some NFTs be one to easily .
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract Bundler is ERC721, NameAccessor {
	event BundleTokens(uint256 bundleId, string concatenated, string metadata);

	uint256 public nextBundleId;
	mapping(uint256 => string) tokenIds;

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
		nextBundleId = 10000001;
	}

	function bundleTokens(string memory concatenated, string memory metadata)
		external
	{
		require(bytes(concatenated).length % 32 == 0, "Inappropriate length");
		_checkValidTokenIds(concatenated);
		for (uint256 i = 0; i < bytes(concatenated).length / 32; i++) {
			string memory sliced = Substrings.substring(
				concatenated,
				32,
				int256(i * 32)
			);
			uint256 tokenId = Integers.parseInt(sliced);
			address payable proxy = payable(_adPool().mediaProxyOf(tokenId));
			MediaFacade manager = MediaFacade(proxy);
			// manager.transferToBundle(msg.sender, address(this), tokenId);
		}
		tokenIds[nextBundleId] = concatenated;
		_mint(address(this), nextBundleId);
		_tokenURIs[nextBundleId] = metadata;
		emit BundleTokens(nextBundleId, concatenated, metadata);
		nextBundleId++;
	}

	function _checkValidTokenIds(string memory concatenated) internal view {
		for (uint256 i = 0; i < bytes(concatenated).length / 32; i++) {
			string memory sliced = Substrings.substring(
				concatenated,
				32,
				int256(i * 32)
			);
			uint256 tokenId = Integers.parseInt(sliced);
			address proxy = _adPool().mediaProxyOf(tokenId);
			require(proxy != address(0), "not exist");
		}
	}

	/**
	 * Accessors
	 */
	function _adPool() internal view returns (AdPool) {
		return AdPool(adPoolAddress());
	}
}
