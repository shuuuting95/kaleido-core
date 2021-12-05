// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @title IProposalReview
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
interface IProposalReview {
	struct Denied {
		string reason;
		bool offensive;
	}
	struct Proposal {
		string content;
		address proposer;
	}

	function propose(
		uint256 tokenId,
		string memory metadata,
		address msgSender
	) external;

	function accept(uint256 tokenId) external;

	function denyProposal(
		uint256 tokenId,
		string memory reason,
		bool offensive
	) external;

	function proposer(uint256 tokenId) external view returns (address);

	function acceptedContent(uint256 tokenId)
		external
		view
		returns (string memory);
}
