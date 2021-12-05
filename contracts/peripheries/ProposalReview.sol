// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Ad.sol";
import "../libraries/Purchase.sol";
import "../accessors/NameAccessor.sol";
import "../common/BlockTimestamp.sol";
import "../interfaces/IProposalReview.sol";
import "../interfaces/IEventEmitter.sol";
import "../interfaces/IEnglishAuction.sol";
import "../interfaces/IMediaRegistry.sol";
import "hardhat/console.sol";

contract ProposalReview is IProposalReview, BlockTimestamp, NameAccessor {
	/// @dev Maps a tokenId with the proposal content.
	mapping(uint256 => Proposal) public proposed;

	/// @dev Maps a tokenId with denied reasons.
	mapping(uint256 => Denied[]) public deniedReasons;

	/// @dev Maps a tokenId with the content metadata.
	mapping(uint256 => string) public accepted;

	modifier onlyProxies() {
		require(_mediaRegistry().ownerOf(msg.sender) != address(0x0), "KD011");
		_;
	}

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	/// @dev Proposes the metadata to the token you bought.
	///      Users can propose many times as long as it is accepted.
	/// @param tokenId uint256 of the token ID
	/// @param metadata string of the proposal metadata
	function propose(
		uint256 tokenId,
		string memory metadata,
		address msgSender
	) external virtual onlyProxies {
		proposed[tokenId] = Proposal(metadata, msgSender);
		_eventEmitter().emitPropose(tokenId, metadata);
	}

	/// @dev Accepts the proposal.
	/// @param tokenId uint256 of the token ID
	function accept(uint256 tokenId) external virtual onlyProxies {
		string memory metadata = proposed[tokenId].content;
		require(bytes(metadata).length != 0, "KD130");
		accepted[tokenId] = metadata;
		proposed[tokenId] = Proposal("", proposed[tokenId].proposer);
		_eventEmitter().emitAcceptProposal(tokenId, metadata);
	}

	/// @dev Denies the submitted proposal, mentioning what is the problem.
	/// @param tokenId uint256 of the token ID
	/// @param reason string of the reason why it is rejected
	/// @param offensive bool if the content would offend somebody
	function denyProposal(
		uint256 tokenId,
		string memory reason,
		bool offensive
	) external virtual onlyProxies {
		string memory metadata = proposed[tokenId].content;
		require(bytes(metadata).length != 0, "KD130");
		deniedReasons[tokenId].push(Denied(reason, offensive));
		_eventEmitter().emitDenyProposal(tokenId, metadata, reason, offensive);
	}

	function proposer(uint256 tokenId) external view returns (address) {
		return proposed[tokenId].proposer;
	}

	function acceptedContent(uint256 tokenId)
		external
		view
		returns (string memory)
	{
		return accepted[tokenId];
	}

	function _eventEmitter() internal view virtual returns (IEventEmitter) {
		return IEventEmitter(eventEmitterAddress());
	}

	function _mediaRegistry() internal view returns (IMediaRegistry) {
		return IMediaRegistry(mediaRegistryAddress());
	}
}
