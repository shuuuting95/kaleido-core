// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./base/PrimarySales.sol";
import "./base/DistributionRight.sol";
import "hardhat/console.sol";

/// @title AdManager - manages ad spaces and its periods to sell them to users.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdManager is DistributionRight, PrimarySales, ReentrancyGuard {
	/// @dev Can call it by only the media
	modifier onlyMedia() {
		require(_mediaRegistry().ownerOf(address(this)) == msg.sender, "KD012");
		_;
	}

	/// @dev Prevents the media from calling by yourself
	modifier exceptYourself() {
		require(
			_mediaRegistry().ownerOf(address(this)) != msg.sender,
			"is the owner"
		);
		_;
	}

	/// @dev Called by the successful bidder
	modifier onlySuccessfulBidder(uint256 tokenId) {
		require(bidding[tokenId].bidder == msg.sender, "KD126");
		_;
	}

	/// @dev Can call it only once
	modifier initializer() {
		require(address(_nameRegistry) == address(0x0), "AR000");
		_;
	}

	/// @dev Initialize the instance.
	/// @param title string of the title of the instance
	/// @param baseURI string of the base URI
	/// @param nameRegistry address of NameRegistry
	function initialize(
		string memory title,
		string memory baseURI,
		address nameRegistry
	) external {
		_name = title;
		_symbol = string(abi.encodePacked("Kaleido_", title));
		_baseURI = baseURI;
		initialize(nameRegistry);
	}

	/// @dev Creates a new space for the media account.
	/// @param spaceMetadata string of the space metadata
	function newSpace(string memory spaceMetadata) external onlyMedia {
		_newSpace(spaceMetadata);
	}

	/// @dev Create a new period for a space. This function requires some params
	///      to decide which kinds of pricing way and how much price to get started.
	/// @param spaceMetadata string of the space metadata
	/// @param tokenMetadata string of the token metadata
	/// @param saleEndTimestamp uint256 of the end timestamp for the sale
	/// @param displayStartTimestamp uint256 of the start timestamp for the display
	/// @param displayEndTimestamp uint256 of the end timestamp for the display
	/// @param pricing uint256 of the pricing way
	/// @param minPrice uint256 of the minimum price to sell it out
	function newPeriod(
		string memory spaceMetadata,
		string memory tokenMetadata,
		uint256 saleEndTimestamp,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp,
		Ad.Pricing pricing,
		uint256 minPrice
	) external onlyMedia {
		require(saleEndTimestamp > _blockTimestamp(), "KD111");
		require(saleEndTimestamp < displayStartTimestamp, "KD112");
		require(displayStartTimestamp < displayEndTimestamp, "KD113");

		if (!spaced[spaceMetadata]) {
			_newSpace(spaceMetadata);
		}
		_checkOverlapping(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp
		);
		uint256 tokenId = Ad.id(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp
		);
		_periodKeys[spaceMetadata].push(tokenId);
		Ad.Period memory period = Ad.Period(
			address(this),
			spaceMetadata,
			tokenMetadata,
			_blockTimestamp(),
			saleEndTimestamp,
			displayStartTimestamp,
			displayEndTimestamp,
			pricing,
			minPrice,
			0,
			false
		);
		period.startPrice = _startPrice(period);
		allPeriods[tokenId] = period;
		_mintRight(tokenId, tokenMetadata);
		_adPool().addPeriod(tokenId, period);
		_eventEmitter().emitNewPeriod(
			tokenId,
			spaceMetadata,
			tokenMetadata,
			_blockTimestamp(),
			saleEndTimestamp,
			displayStartTimestamp,
			displayEndTimestamp,
			pricing,
			minPrice
		);
		_eventEmitter().emitTransferCustom(address(0), address(this), tokenId);
	}

	/// @dev Deletes a period and its token.
	///      If there is any users locking the fund for the sale, the amount would be transfered
	///      to the user when deleting the period.
	/// @param tokenId uint256 of the token ID
	function deletePeriod(uint256 tokenId) external onlyMedia {
		require(allPeriods[tokenId].mediaProxy != address(0), "KD114");
		require(ownerOf(tokenId) == address(this), "KD121");
		_refundLockedAmount(tokenId);
		delete allPeriods[tokenId];
		_burnRight(tokenId);
		_adPool().deletePeriod(tokenId);
		_eventEmitter().emitDeletePeriod(tokenId);
		_eventEmitter().emitTransferCustom(address(this), address(0), tokenId);
	}

	/// @dev Buys the token that is defined as the specific period on an ad space.
	///      The price of the token is fixed.
	/// @param tokenId uint256 of the token ID
	function buy(uint256 tokenId) external payable exceptYourself {
		_checkBeforeBuy(tokenId);
		allPeriods[tokenId].sold = true;
		_dropRight(tokenId);
		_collectFees();
		_eventEmitter().emitBuy(tokenId, msg.value, msg.sender);
		_eventEmitter().emitTransferCustom(address(this), msg.sender, tokenId);
	}

	/// @dev Buys the token that is defined as the specific period on an ad space.
	///      The price is decreasing as time goes by.
	/// @param tokenId uint256 of the token ID
	function buyBasedOnTime(uint256 tokenId) external payable exceptYourself {
		_checkBeforeBuyBasedOnTime(tokenId);
		allPeriods[tokenId].sold = true;
		_dropRight(tokenId);
		_collectFees();
		_eventEmitter().emitBuy(tokenId, msg.value, msg.sender);
		_eventEmitter().emitTransferCustom(address(this), msg.sender, tokenId);
	}

	/// @dev Bids to participate in an auction.
	/// @param tokenId uint256 of the token ID
	function bid(uint256 tokenId) external payable exceptYourself nonReentrant {
		_checkBeforeBid(tokenId);
		_refundLockedAmount(tokenId);
		// TODO: save history on AdPool
		bidding[tokenId] = Bidding(tokenId, msg.sender, msg.value);
		_eventEmitter().emitBid(tokenId, msg.value, msg.sender);
	}

	/// @dev Receives the token you bidded if you are the successful bidder.
	/// @param tokenId uint256 of the token ID
	function receiveToken(uint256 tokenId)
		external
		payable
		onlySuccessfulBidder(tokenId)
	{
		_checkBeforeReceiveToken(tokenId);
		allPeriods[tokenId].sold = true;
		_dropRight(tokenId);
		_collectFees();
		_eventEmitter().emitReceiveToken(
			tokenId,
			bidding[tokenId].price,
			msg.sender
		);
		_eventEmitter().emitTransferCustom(address(this), msg.sender, tokenId);
	}

	/// @dev Offers to buy a period that the sender requests.
	/// @param spaceMetadata string of the space metadata
	/// @param displayStartTimestamp uint256 of the start timestamp for the display
	/// @param displayEndTimestamp uint256 of the end timestamp for the display
	function offerPeriod(
		string memory spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp
	) external payable exceptYourself {
		require(spaced[spaceMetadata], "KD101");
		require(displayStartTimestamp < displayEndTimestamp, "KD113");
		uint256 tokenId = Ad.id(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp
		);
		offered[tokenId] = Offer(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp,
			msg.sender,
			msg.value
		);
		_eventEmitter().emitOfferPeriod(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp,
			msg.sender,
			msg.value
		);
	}

	/// @dev Accepts an offer by the Media.
	/// @param tokenId uint256 of the token ID
	/// @param tokenMetadata string of the NFT token metadata
	function acceptOffer(uint256 tokenId, string memory tokenMetadata)
		external
		onlyMedia
	{
		Offer memory offer = offered[tokenId];
		require(offer.sender != address(0), "KD115");
		_checkOverlapping(
			offer.spaceMetadata,
			offer.displayStartTimestamp,
			offer.displayEndTimestamp
		);
		Ad.Period memory period = Ad.Period(
			address(this),
			offer.spaceMetadata,
			tokenMetadata,
			_blockTimestamp(),
			_blockTimestamp(),
			offer.displayStartTimestamp,
			offer.displayEndTimestamp,
			Ad.Pricing.OFFER,
			offer.price,
			offer.price,
			true
		);
		allPeriods[tokenId] = period;
		_mintRight(tokenId, tokenMetadata);
		_collectFees();
		_eventEmitter().emitAcceptOffer(
			tokenId,
			offer.spaceMetadata,
			tokenMetadata,
			offer.displayStartTimestamp,
			offer.displayEndTimestamp,
			offer.price
		);
		_eventEmitter().emitTransferCustom(address(0), address(this), tokenId);
	}

	// TODO: denyOffer

	/// @dev Withdraws the fund deposited to the proxy contract.
	function withdraw() external onlyMedia {
		uint256 remained = address(this).balance;
		payable(msg.sender).transfer(remained);
		_eventEmitter().emitWithdraw(remained);
	}

	/// @dev Proposes the metadata to the token you bought.
	///      Users can propose many times as long as it is accepted.
	/// @param tokenId uint256 of the token ID
	/// @param metadata string of the proposal metadata
	function propose(uint256 tokenId, string memory metadata) external {
		require(ownerOf(tokenId) == msg.sender, "KD012");
		_proposeToRight(tokenId, metadata);
		_eventEmitter().emitPropose(tokenId, metadata);
	}

	/// @dev Accepts the proposal.
	/// @param tokenId uint256 of the token ID
	function accept(uint256 tokenId) external onlyMedia {
		string memory metadata = proposed[tokenId];
		require(bytes(metadata).length != 0, "KD130");
		address currentOwner = ownerOf(tokenId);
		_burnRight(tokenId);
		_acceptProposal(tokenId, metadata);
		_eventEmitter().emitAcceptProposal(tokenId, metadata);
		_eventEmitter().emitTransferCustom(currentOwner, address(0), tokenId);
	}

	/// @dev Denies the submitted proposal, mentioning what is the problem.
	/// @param tokenId uint256 of the token ID
	/// @param reason string of the reason why it is rejected
	function deny(uint256 tokenId, string memory reason) external onlyMedia {
		string memory metadata = proposed[tokenId];
		require(bytes(metadata).length != 0, "KD130");
		deniedReason[tokenId] = reason;
		_eventEmitter().emitDenyProposal(tokenId, metadata, reason);
	}

	/// @dev Returns ID based on the space metadata, display start timestamp, and
	///      display end timestamp. These three makes it the unique.
	/// @param spaceMetadata uint256 of the space metadata
	/// @param displayStartTimestamp uint256 of the start timestamp for the display
	/// @param displayEndTimestamp uint256 of the end timestamp for the display
	function adId(
		string memory spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp
	) public pure returns (uint256) {
		return Ad.id(spaceMetadata, displayStartTimestamp, displayEndTimestamp);
	}

	/// @dev Returns the balacne deposited on the proxy contract.
	function balance() public view returns (uint256) {
		return address(this).balance;
	}

	/// @dev Displays the ad content that is approved by the media owner.
	/// @param spaceMetadata string of the space metadata
	function display(string memory spaceMetadata)
		external
		view
		returns (string memory)
	{
		uint256[] memory tokenIds = tokenIdsOf(spaceMetadata);
		for (uint256 i = 0; i < tokenIds.length; i++) {
			Ad.Period memory period = allPeriods[tokenIds[i]];
			if (
				period.displayStartTimestamp <= _blockTimestamp() &&
				period.displayEndTimestamp >= _blockTimestamp()
			) {
				return accepted[tokenIds[i]];
			}
		}
		return "";
	}

	function _checkBeforeReceiveToken(uint256 tokenId) internal view {
		require(allPeriods[tokenId].pricing == Ad.Pricing.BIDDING, "KD124");
		require(!allPeriods[tokenId].sold, "KD121");
		require(allPeriods[tokenId].saleEndTimestamp < _blockTimestamp(), "KD125");
	}

	function _collectFees() internal {
		payable(vaultAddress()).transfer(msg.value / 10);
	}
}
