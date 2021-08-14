// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./ERC721Base.sol";
import "../access/NameAccessor.sol";

/// @title DistributionRight - represents advertising distribution rights.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract DistributionRight is ERC721Base, NameAccessor {
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
	) ERC721Base(name_, symbol_, baseURI_) NameAccessor(nameRegistry) {}

	/// @dev Mints a new NFT.
	/// @param account address of the token owner
	/// @param tokenId uint256 of the token ID
	function mint(address account, uint256 tokenId) public onlyAllowedContract {
		_mint(account, tokenId);
	}

	/// @dev Burns the NFT.
	/// @param tokenId uint256 of the token ID
	function burn(uint256 tokenId) public onlyAllowedContract {
		_burn(tokenId);
	}
}
