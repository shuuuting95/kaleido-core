// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../interfaces/INameRegistry.sol";

/// @title NameAccessor - manages the endpoints.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract NameAccessor {
	INameRegistry internal _nameRegistry;

	/// @dev Sets the address of NameRegistry.
	/// @param nameRegistry address of the NameRegistry
	function initialize(address nameRegistry) internal {
		_nameRegistry = INameRegistry(nameRegistry);
	}

	/// @dev Prevents calling a function from anyone except the accepted contracts.
	modifier onlyAllowedContract() {
		require(_nameRegistry.allowedContracts(msg.sender), "KD013");
		_;
	}

	/// @dev Throws if not called by MediaFactory.
	modifier onlyFactory() {
		require(msg.sender == mediaFactoryAddress(), "KD010");
		_;
	}

	/// @dev Throws if called by any account other than the owner.
	modifier onlyOwner() {
		require(owner() == msg.sender, "KD012");
		_;
	}

	/// @dev Gets the address of NameRegistry
	function nameRegistryAddress() public view returns (address) {
		return address(_nameRegistry);
	}

	/// @dev Gets the address of AdPool.
	function adPoolAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("AdPool")));
	}

	/// @dev Gets the address of MediaFactory.
	function mediaFactoryAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("MediaFactory")));
	}

	/// @dev Gets the address of MediaRegistry.
	function mediaRegistryAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("MediaRegistry")));
	}

	/// @dev Gets the address of Vault.
	function vaultAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("Vault")));
	}

	/// @dev Gets the address of EventEmitter.
	function eventEmitterAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("EventEmitter")));
	}

	/// @dev Gets the address of EnglishAuction.
	function englishAuctionAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("EnglishAuction")));
	}

	/// @dev Gets the address of OpenBid.
	function openBidAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("OpenBid")));
	}

	/// @dev Gets the address of OfferBid.
	function offerBidAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("OfferBid")));
	}

	/// @dev Gets the address of ProposalReview.
	function proposalReviewAddress() public view returns (address) {
		return _nameRegistry.get(keccak256(abi.encodePacked("ProposalReview")));
	}

	/// @dev Gets the owner address.
	function owner() public view returns (address) {
		return _nameRegistry.deployer();
	}
}
