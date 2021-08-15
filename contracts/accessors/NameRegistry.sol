// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title NameRegistry - saves a set of addresses.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract NameRegistry is Ownable {
	using Address for address;

	mapping(address => bool) public allowedContracts;
	mapping(bytes32 => address) private _addressStorage;

	constructor() Ownable() {}

	/// @dev Sets the address associated with the key name.
	///      If the address is the contract, not an EOA, it is
	///      saved as the allowed contract list.
	/// @param key bytes32 of the key
	/// @param value address of the value
	function set(bytes32 key, address value) public onlyOwner {
		_addressStorage[key] = value;
		if (value.isContract()) {
			allowedContracts[value] = true;
		}
	}

	/// @dev Gets the address associated with the key name.
	/// @param key bytes32 of the key
	function get(bytes32 key) public view returns (address) {
		return _addressStorage[key];
	}
}
