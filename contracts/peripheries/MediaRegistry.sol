// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../interfaces/IMediaRegistry.sol";
import "../interfaces/IEventEmitter.sol";

/// @title MediaRegistry - registers a list of media accounts.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract MediaRegistry is IMediaRegistry, BlockTimestamp, NameAccessor {
	/// @inheritdoc IMediaRegistry
	mapping(address => Account) public override allAccounts;

	/// @dev Throws if not called by MediaFacade proxies.
	modifier onlyProxies() {
		require(ownerOf(msg.sender) != address(0), "KD011");
		_;
	}

	/// @dev Throws if not called by MediaFactory.
	modifier onlyFactory() {
		require(msg.sender == mediaFactoryAddress(), "KD010");
		_;
	}

	/// Constructor
	/// @dev _nameRegistry address of the NameRegistry
	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

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
	) external onlyFactory {
		allAccounts[proxy] = Account(
			proxy,
			mediaEOA,
			applicationMetadata,
			updatableMetadata
		);
	}

	/// @dev Updates media account. It can be called by media proxies.
	/// @param metadata string of the account metadata
	/// @param mediaEOA address of the media account
	function updateMedia(address mediaEOA, string memory metadata)
		external
		onlyProxies
	{
		allAccounts[msg.sender].mediaEOA = mediaEOA;
		allAccounts[msg.sender].updatableMetadata = metadata;
		_event().emitUpdateMedia(msg.sender, mediaEOA, metadata);
	}

	/// @dev Updates media account. It can only be called by the deployer as it is an application info.
	/// @param proxy string of the account metadata
	/// @param metadata address of the media account
	function updateApplicationMetadata(address proxy, string memory metadata)
		external
		onlyOwner
	{
		allAccounts[proxy].applicationMetadata = metadata;
	}

	/// @dev Returns whether the account has created or not.
	/// @param proxy address of the proxy contract that represents an account.
	function created(address proxy) public view returns (bool) {
		return allAccounts[proxy].proxy != address(0x0);
	}

	/// @dev Returns the owner of the account.
	/// @param proxy address of the proxy contract that represents an account.
	function ownerOf(address proxy) public view returns (address) {
		return allAccounts[proxy].mediaEOA;
	}

	function _event() internal view virtual returns (IEventEmitter) {
		return IEventEmitter(eventEmitterAddress());
	}
}
