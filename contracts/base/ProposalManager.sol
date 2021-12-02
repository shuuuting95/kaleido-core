// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Draft.sol";

/// @title ProposalManager - manages proposals.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract ProposalManager {
	mapping(uint256 => Draft.Proposal) public proposed;
	mapping(uint256 => Draft.Denied[]) public deniedReasons;
	mapping(uint256 => string) public accepted;

	function _proposeToRight(uint256 tokenId, string memory metadata) internal {
		proposed[tokenId] = Draft.Proposal(metadata, msg.sender);
	}

	function _clearProposal(uint256 tokenId) internal {
		proposed[tokenId] = Draft.Proposal("", proposed[tokenId].proposer);
	}

	function _acceptProposal(uint256 tokenId, string memory metadata) internal {
		accepted[tokenId] = metadata;
		_clearProposal(tokenId);
	}
}
