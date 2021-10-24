// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./ERC721.sol";
import "../accessors/NameAccessor.sol";

import "hardhat/console.sol";

/// @title DistributionRight - represents NFTs based on ad spaces and periods.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract DistributionRight is ERC721, NameAccessor {
	mapping(uint256 => string) public proposed;
	mapping(uint256 => string) public deniedReason;

	modifier initializer() {
		require(address(_nameRegistry) == address(0x0), "AR000");
		_;
	}

	modifier initialized() {
		require(address(_nameRegistry) != address(0x0), "AR001");
		_;
	}

	/// @dev Initialize the instance.
	/// @param title string of the title of the instance
	/// @param baseURI string of the base URI
	/// @param nameRegistry address of NameRegistry
	function initialize(
		string memory title,
		string memory baseURI,
		address nameRegistry
	) external {
		_name = title;
		_symbol = string(abi.encodePacked("Kaleido_", title));
		_baseURI = baseURI;
		initialize(nameRegistry);
	}

	function _mintRight(uint256 tokenId, string memory metadata) internal {
		_mint(address(this), tokenId);
		_tokenURIs[tokenId] = metadata;
	}

	function _burnRight(uint256 tokenId) internal {
		_burn(tokenId);
		_tokenURIs[tokenId] = "";
	}

	function _soldRight(uint256 tokenId) internal {
		_transfer(address(this), msg.sender, tokenId);
	}

	function _proposeToRight(uint256 tokenId, string memory metadata) internal {
		proposed[tokenId] = metadata;
	}

	function transferToBundle(
		address from,
		address to,
		uint256 tokenId
	) external {
		// TODO: only from bundler
		_transfer(from, to, tokenId);
	}
}
