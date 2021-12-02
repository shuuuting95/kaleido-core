// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Ad.sol";

/// @title MediaRegistry - registers a list of media accounts.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IMediaRegistry {
	struct Account {
		address proxy;
		address mediaEOA;
		string applicationMetadata;
		string updatableMetadata;
	}

	function allAccounts(address proxy)
		external
		view
		returns (
			address,
			address,
			string memory,
			string memory
		);

	/// @dev Adds media account.
	/// @param proxy address of the proxy contract
	/// @param applicationMetadata string of constant metadata for the defailts of the account
	/// @param updatableMetadata string of constant metadata for the defailts of the account
	/// @param mediaEOA address of the media account
	function addMedia(
		address proxy,
		string memory applicationMetadata,
		string memory updatableMetadata,
		address mediaEOA
	) external;

	/// @dev Updates media account.
	/// @param metadata string of the account metadata
	/// @param mediaEOA address of the media account
	function updateMedia(address mediaEOA, string memory metadata) external;

	function updateApplicationMetadata(address proxy, string memory metadata)
		external;

	/// @dev Returns whether the account has created or not.
	/// @param proxy address of the proxy contract that represents an account.
	function created(address proxy) external view returns (bool);

	/// @dev Returns the owner of the account.
	/// @param proxy address of the proxy contract that represents an account.
	function ownerOf(address proxy) external view returns (address);
}
