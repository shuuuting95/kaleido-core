// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./ERC721.sol";
import "../accessors/NameAccessor.sol";

import "hardhat/console.sol";

/// @title DistributionRight - represents NFTs based on ad spaces and periods.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract DistributionRight is ERC721 {
	function _mintRight(
		address reciever,
		uint256 tokenId,
		string memory metadata
	) internal {
		_mint(reciever, tokenId);
		_tokenURIs[tokenId] = metadata;
	}

	function _burnRight(uint256 tokenId) internal {
		_burn(tokenId);
		_tokenURIs[tokenId] = "";
	}

	function _dropRight(address receiver, uint256 tokenId) internal {
		_transfer(address(this), receiver, tokenId);
	}
}
