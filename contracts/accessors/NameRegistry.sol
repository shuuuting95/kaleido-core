// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./Ownable.sol";
import "../interfaces/INameRegistry.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title NameRegistry - saves a set of addresses.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract NameRegistry is INameRegistry, Ownable {
	using Address for address;

	/// @inheritdoc INameRegistry
	mapping(address => bool) public allowedContracts;
	mapping(bytes32 => address) private _addressStorage;

	constructor() Ownable() {}

	/// @inheritdoc INameRegistry
	function set(bytes32 key, address value) public onlyOwner {
		_addressStorage[key] = value;
		if (value.isContract()) {
			allowedContracts[value] = true;
		}
	}

	/// @inheritdoc INameRegistry
	function get(bytes32 key) public view returns (address) {
		return _addressStorage[key];
	}

	/// @inheritdoc INameRegistry
	function deployer() public view returns (address) {
		return owner();
	}
}
