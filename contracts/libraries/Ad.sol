// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

library Ad {
	uint256 private constant _ID_LENGTH = 10000000000000000000000000000000;
	// RBP : Recommended Retail Price
	// DPBT: Dynamic Pricing Based on Time
	// BID : Auction, Bidding Price
	enum Pricing {
		RRP,
		DPBT,
		BID
	}
	struct Period {
		address mediaProxy;
		string spaceMetadata;
		string tokenMetadata;
		uint256 fromTimestamp;
		uint256 toTimestamp;
		Pricing pricing;
		uint256 minPrice;
		bool sold;
	}

	function id(
		string memory metadata,
		uint256 fromTimestamp,
		uint256 toTimestamp
	) public pure returns (uint256) {
		return
			uint256(
				keccak256(abi.encodePacked(metadata, fromTimestamp, toTimestamp))
			) % _ID_LENGTH;
	}
}
