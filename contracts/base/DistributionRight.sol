// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./ERC721.sol";
import "../accessors/NameAccessor.sol";

import "hardhat/console.sol";

/// @title DistributionRight - represents NFTs based on ad spaces and periods.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract DistributionRight is ERC721 {
	mapping(uint256 => string) public proposed;
	mapping(uint256 => string) public deniedReason;
	mapping(uint256 => string) public accepted;

	function _mintRight(uint256 tokenId, string memory metadata) internal {
		_mint(address(this), tokenId);
		_tokenURIs[tokenId] = metadata;
	}

	function _burnRight(uint256 tokenId) internal {
		_burn(tokenId);
		_tokenURIs[tokenId] = "";
	}

	function _dropRight(uint256 tokenId) internal {
		_transfer(address(this), msg.sender, tokenId);
	}

	function _proposeToRight(uint256 tokenId, string memory metadata) internal {
		proposed[tokenId] = metadata;
	}

	function _clearProposal(uint256 tokenId) internal {
		proposed[tokenId] = "";
	}

	function _acceptProposal(uint256 tokenId, string memory metadata) internal {
		accepted[tokenId] = metadata;
		_clearProposal(tokenId);
	}

	// function transferToBundle(
	// 	address from,
	// 	address to,
	// 	uint256 tokenId
	// ) external {
	// 	// TODO: only from bundler
	// 	_transfer(from, to, tokenId);
	// }
}
