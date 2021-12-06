// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

library Ad {
	uint256 private constant _ID_LENGTH = 100000000000000000000000000000000;
	// 0.RRP     : Recommended Retail Price
	// 1.DUTCH   : Dutch Auction
	// 2.ENGLISH : English Acction
	// 3.OFFER   : Offered by Others
	// 4.OPEN    : Open Bid by revealing the content
	enum Pricing {
		RRP,
		DUTCH,
		ENGLISH,
		OFFER,
		OPEN
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
