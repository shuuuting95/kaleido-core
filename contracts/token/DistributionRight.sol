// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./ERC721Base.sol";
import "../accessors/NameAccessor.sol";

/// @title DistributionRight - represents advertising distribution rights.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract DistributionRight is ERC721Base {
	/// @dev Initializes NFT
	/// @param name_ string of the token name
	/// @param symbol_ string of the token symbol
	/// @param baseURI_ string of the base URI
	/// @param nameRegistry address of NameRegistry
	constructor(
		string memory name_,
		string memory symbol_,
		string memory baseURI_,
		address nameRegistry
	) ERC721Base(name_, symbol_, baseURI_, nameRegistry) {}

	/// @dev Mints a new NFT.
	/// @param account address of the token owner
	/// @param tokenId uint256 of the token ID
	function mint(
		address account,
		uint256 tokenId,
		string memory metadata
	) public onlyAllowedContract {
		_mint(account, tokenId);
		_tokenURIs[tokenId] = metadata;
	}

	/// @dev Burns the NFT.
	/// @param tokenId uint256 of the token ID
	function burn(uint256 tokenId) public onlyAllowedContract {
		_burn(tokenId);
	}

	/// @dev Transfers the NFT.
	/// @param from address of the current owner
	/// @param to address of the next owner
	/// @param tokenId uint256 of the token ID
	function transferByAllowedContract(
		address from,
		address to,
		uint256 tokenId
	) public onlyAllowedContract {
		_transfer(from, to, tokenId);
	}
}
