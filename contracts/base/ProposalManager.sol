// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @title ProposalManager - manages proposals.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract ProposalManager {
	struct Denied {
		string reason;
		bool offensive;
	}
	struct Proposal {
		string content;
		address proposer;
	}
	mapping(uint256 => Proposal) public proposed;
	mapping(uint256 => Denied[]) public deniedReasons;
	mapping(uint256 => string) public accepted;

	function _proposeToRight(uint256 tokenId, string memory metadata) internal {
		proposed[tokenId] = Proposal(metadata, msg.sender);
	}

	function _clearProposal(uint256 tokenId) internal {
		proposed[tokenId] = Proposal("", proposed[tokenId].proposer);
	}

	function _acceptProposal(uint256 tokenId, string memory metadata) internal {
		accepted[tokenId] = metadata;
		_clearProposal(tokenId);
	}
}
