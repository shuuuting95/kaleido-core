// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
import "../accessors/NameAccessor.sol";

/// @title PostOwnerPool - pool of post owners.
/// @author Yushi Masui - <yushi.masui@bridges.inc>
contract PostOwnerPool is NameAccessor {
	constructor(address nameRegistry) NameAccessor(nameRegistry) {}

	mapping(uint256 => address) public owners;

	function addPost(uint256 postId, address owner) public onlyAllowedContract {
		owners[postId] = owner;
	}

	function ownerOf(uint256 postId) public view returns (address) {
		return owners[postId];
	}
}
