// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../base/ERC721.sol";
import "../accessors/NameAccessor.sol";

/// @title DistributionRight - represents advertising distribution rights.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract DistributionRight is ERC721, NameAccessor {
	modifier initializer() {
		require(address(_nameRegistry) == address(0x0), "AR000");
		_;
	}

	modifier initialized() {
		require(address(_nameRegistry) != address(0x0), "AR001");
		_;
	}

	/// @dev Initializes the contract
	/// @param title string of the project name
	/// @param baseURI string of the base URI
	/// @param nameRegistry address of NameRegistry
	function initialize(
		string memory title,
		string memory baseURI,
		address nameRegistry
	) external initializer {
		_name = title;
		_symbol = string(abi.encodePacked("Aurora_", title));
		_baseURI = baseURI;
		initialize(nameRegistry);
	}

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
