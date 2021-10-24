// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../base/BlockTimestamp.sol";
import "../accessors/NameAccessor.sol";
import "hardhat/console.sol";

/// @title MediaRegistry - registers a list of media accounts.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract MediaRegistry is BlockTimestamp, NameAccessor {
	struct Account {
		address proxy;
		address owner;
		string metadata;
	}
	mapping(address => Account) public allAccounts;

	/// Constructor
	/// @dev _nameRegistry address of the NameRegistry
	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	function addMedia(
		address proxy,
		string memory metadata,
		address owner /**onlyMediaFactory*/
	) external {
		allAccounts[proxy] = Account(proxy, owner, metadata);
	}

	/// @dev Returns whether the account has created or not.
	/// @param proxy address of the proxy contract that represents an account.
	function created(address proxy) public view returns (bool) {
		return allAccounts[proxy].proxy != address(0x0);
	}

	/// @dev Returns the owner of the account.
	/// @param proxy address of the proxy contract that represents an account.
	function ownerOf(address proxy) public view returns (address) {
		return allAccounts[proxy].owner;
	}
}
