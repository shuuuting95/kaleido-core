// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

library Draft {
	struct Denied {
		string reason;
		bool offensive;
	}
	struct Proposal {
		string content;
		address proposer;
	}
}
