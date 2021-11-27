// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

library Ad {
	uint256 private constant _ID_LENGTH = 100000000000000000000000000000000;
	// 0.RBP     : Recommended Retail Price
	// 1.DPBT    : Dynamic Pricing Based on Time
	// 2.BIDDING : Auction, Bidding Price
	// 3.OFFER   : Offered by others
	// 4.APPEAL  : Bidding Price and Submission data
	enum Pricing {
		RRP,
		DPBT,
		BIDDING,
		OFFER,
		APPEAL
	}
	struct Period {
		address mediaProxy;
		string spaceMetadata;
		string tokenMetadata;
		uint256 saleStartTimestamp;
		uint256 saleEndTimestamp;
		uint256 displayStartTimestamp;
		uint256 displayEndTimestamp;
		Pricing pricing;
		uint256 minPrice;
		uint256 startPrice;
		bool sold;
	}

	function id(
		string memory metadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp
	) public pure returns (uint256) {
		return
			uint256(
				keccak256(
					abi.encodePacked(metadata, displayStartTimestamp, displayEndTimestamp)
				)
			) % _ID_LENGTH;
	}
}
