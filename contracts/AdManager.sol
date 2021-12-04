// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./base/PrimarySales.sol";
import "./base/DistributionRight.sol";
import "./libraries/Purchase.sol";
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
		require(_mediaRegistry().ownerOf(address(this)) != msg.sender, "KD014");
		_;
	}

	/// @dev Called by the successful bidder
	modifier onlySuccessfulBidder(uint256 tokenId) {
		require(_english().bidding(tokenId).bidder == msg.sender, "KD126");
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
	) external virtual {
		_name = title;
		_symbol = string(abi.encodePacked("Kaleido_", title));
		_baseURI = baseURI;
		initialize(nameRegistry);
	}

	/// @dev Updates the media EOA and the metadata.
	/// @param newMediaEOA address of a new EOA
	/// @param newMetadata string of a new metadata
	function updateMedia(address newMediaEOA, string memory newMetadata)
		external
		virtual
		onlyMedia
	{
		_mediaRegistry().updateMedia(newMediaEOA, newMetadata);
		_eventEmitter().emitUpdateMedia(address(this), newMediaEOA, newMetadata);
	}

	/// @dev Creates a new space for the media account.
	/// @param spaceMetadata string of the space metadata
	function newSpace(string memory spaceMetadata) external virtual onlyMedia {
		// _newSpace(spaceMetadata);
		_adPool().addSpace(spaceMetadata);
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
	) external virtual onlyMedia {
		// require(saleEndTimestamp > _blockTimestamp(), "KD111");
		// require(saleEndTimestamp < displayStartTimestamp, "KD112");
		// require(displayStartTimestamp < displayEndTimestamp, "KD113");
		uint256 tokenId = _adPool().addPeriod(
			address(this),
			spaceMetadata,
			tokenMetadata,
			saleEndTimestamp,
			displayStartTimestamp,
			displayEndTimestamp,
			pricing,
			minPrice
		);
		_mintRight(address(this), tokenId, tokenMetadata);
		_eventEmitter().emitTransferCustom(address(0), address(this), tokenId);
	}

	/// @dev Deletes a period and its token.
	///      If there is any users locking the fund for the sale, the amount would be transfered
	///      to the user when deleting the period.
	/// @param tokenId uint256 of the token ID
	function deletePeriod(uint256 tokenId) external virtual onlyMedia {
		require(_adPool().allPeriods(tokenId).mediaProxy != address(0), "KD114");
		require(ownerOf(tokenId) == address(this), "KD121");
		require(!_alreadyBid(tokenId), "KD128");
		_burnRight(tokenId);
		_adPool().deletePeriod(tokenId);
		_eventEmitter().emitTransferCustom(address(this), address(0), tokenId);
	}

	/// @dev Buys the token that is defined as the specific period on an ad space.
	///      The price of the token is fixed.
	/// @param tokenId uint256 of the token ID
	function buy(uint256 tokenId) external payable virtual exceptYourself {
		Purchase.checkBeforeBuy(_adPool().allPeriods(tokenId));
		_adPool().sold(tokenId);
		_dropRight(msg.sender, tokenId);
		_collectFees(msg.value / 10);
		_eventEmitter().emitBuy(tokenId, msg.value, msg.sender, _blockTimestamp());
		_eventEmitter().emitTransferCustom(address(this), msg.sender, tokenId);
	}

	// /// @dev Buys the token that is defined as the specific period on an ad space.
	// ///      The price is decreasing as time goes by, that is defined as an Dutch Auction.
	// /// @param tokenId uint256 of the token ID
	// function buyBasedOnTime(uint256 tokenId)
	// 	external
	// 	payable
	// 	virtual
	// 	exceptYourself
	// {
	// 	_checkBeforeBuyBasedOnTime(tokenId);
	// 	periods[tokenId].sold = true;
	// 	_dropRight(msg.sender, tokenId);
	// 	_collectFees(msg.value / 10);
	// 	_eventEmitter().emitBuy(tokenId, msg.value, msg.sender, _blockTimestamp());
	// 	_eventEmitter().emitTransferCustom(address(this), msg.sender, tokenId);
	// }

	// /// @dev Bids to participate in an auction.
	// ///      It is defined as an English Auction.
	// /// @param tokenId uint256 of the token ID
	// function bid(uint256 tokenId)
	// 	external
	// 	payable
	// 	virtual
	// 	exceptYourself
	// 	nonReentrant
	// {
	// 	_checkBeforeBid(tokenId);
	// 	_refundBiddingAmount(tokenId);
	// 	_biddingTotal += (msg.value - bidding[tokenId].price);
	// 	bidding[tokenId] = Sale.Bidding(tokenId, msg.sender, msg.value);
	// 	_eventEmitter().emitBid(tokenId, msg.value, msg.sender, _blockTimestamp());
	// }
	/// @dev Buys the token that is defined as the specific period on an ad space.
	///      The price is decreasing as time goes by, that is defined as an Dutch Auction.
	/// @param tokenId uint256 of the token ID
	function buyBasedOnTime(uint256 tokenId)
		external
		payable
		virtual
		exceptYourself
	{
		Purchase.checkBeforeBuyBasedOnTime(
			_adPool().allPeriods(tokenId),
			currentPrice(tokenId)
		);
		_adPool().sold(tokenId);
		_dropRight(msg.sender, tokenId);
		_collectFees(msg.value / 10);
		_eventEmitter().emitBuy(tokenId, msg.value, msg.sender, _blockTimestamp());
		_eventEmitter().emitTransferCustom(address(this), msg.sender, tokenId);
	}

	/// @dev Bids to participate in an auction.
	///      It is defined as an English Auction.
	/// @param tokenId uint256 of the token ID
	function bid(uint256 tokenId)
		external
		payable
		virtual
		exceptYourself
		nonReentrant
	{
		Purchase.checkBeforeBid(
			_adPool().allPeriods(tokenId),
			currentPrice(tokenId),
			_blockTimestamp()
		);
		// _refundBiddingAmount(tokenId);
		// bidding[tokenId] = Sale.Bidding(tokenId, msg.sender, msg.value);
		_english().bid(tokenId, msg.sender, msg.value);
		// _biddingTotal += (msg.value - bidding[tokenId].price);
		_eventEmitter().emitBid(tokenId, msg.value, msg.sender, _blockTimestamp());
	}

	/// @dev Bids to participate in an auction.
	///      It is defined as an Open Bid.
	/// @param tokenId uint256 of the token ID
	/// @param proposalMetadata string of the metadata hash
	function bidWithProposal(uint256 tokenId, string memory proposalMetadata)
		external
		payable
		virtual
		exceptYourself
		nonReentrant
	{
		Purchase.checkBeforeBidWithProposal(
			_adPool().allPeriods(tokenId),
			_blockTimestamp()
		);
		_biddingTotal += msg.value;
		// appealed[tokenId].push(
		// 	Sale.Appeal(tokenId, msg.sender, msg.value, proposalMetadata)
		// );
		_openBid().bid(tokenId, proposalMetadata, msg.sender, msg.value);
		_eventEmitter().emitBidWithProposal(
			tokenId,
			msg.value,
			msg.sender,
			proposalMetadata,
			_blockTimestamp()
		);
	}

	/// @dev Selects the best proposal bidded with.
	/// @param tokenId uint256 of the token ID
	/// @param index uint256 of the index number
	function selectProposal(uint256 tokenId, uint256 index)
		external
		virtual
		onlyMedia
	{
		// require(
		// 	appealed[tokenId].length >= index &&
		// 		appealed[tokenId][index].sender != address(0),
		// 	"KD114"
		// );
		// require(
		// 	_adPool().allPeriods(tokenId).saleEndTimestamp < _blockTimestamp(),
		// 	"KD129"
		// );

		address successfulBidder = _openBid().selectProposal(tokenId, index);
		// Sale.Appeal memory appeal = appealed[tokenId][index];
		_dropRight(successfulBidder, tokenId);
		// _refundToProposers(tokenId, index);
		// delete appealed[tokenId];
		// _eventEmitter().emitSelectProposal(tokenId, appeal.sender);
		_eventEmitter().emitTransferCustom(
			address(this),
			successfulBidder,
			tokenId
		);
	}

	// /// @dev Receives the token you bidded if you are the successful bidder.
	// /// @param tokenId uint256 of the token ID
	// function receiveToken(uint256 tokenId)
	// 	external
	// 	virtual
	// 	onlySuccessfulBidder(tokenId)
	// {
	// 	_toSuccessfulBidder(tokenId, msg.sender);
	// }

	// /// @dev Receives the token you bidded if you are the successful bidder.
	// /// @param tokenId uint256 of the token ID
	// function pushToSuccessfulBidder(uint256 tokenId) external virtual onlyMedia {
	// 	_toSuccessfulBidder(tokenId, bidding[tokenId].bidder);
	// }

	// /// @dev Offers to buy a period that the sender requests.
	// /// @param spaceMetadata string of the space metadata
	// /// @param displayStartTimestamp uint256 of the start timestamp for the display
	// /// @param displayEndTimestamp uint256 of the end timestamp for the display
	// function offerPeriod(
	// 	string memory spaceMetadata,
	// 	uint256 displayStartTimestamp,
	// 	uint256 displayEndTimestamp
	// ) external payable virtual exceptYourself {
	// 	require(spaced[spaceMetadata], "KD101");
	// 	require(displayStartTimestamp < displayEndTimestamp, "KD113");
	// 	uint256 tokenId = Ad.id(
	// 		spaceMetadata,
	// 		displayStartTimestamp,
	// 		displayEndTimestamp
	// 	);
	// 	offered[tokenId] = Sale.Offer(
	// 		spaceMetadata,
	// 		displayStartTimestamp,
	// 		displayEndTimestamp,
	// 		msg.sender,
	// 		msg.value
	// 	);
	// 	_offeredTotal += msg.value;
	// 	_eventEmitter().emitOfferPeriod(
	// 		tokenId,
	// 		spaceMetadata,
	// 		displayStartTimestamp,
	// 		displayEndTimestamp,
	// 		msg.sender,
	// 		msg.value
	// 	);
	// }

	// /// @dev Cancels an offer.
	// /// @param tokenId uint256 of the token ID
	// function cancelOffer(uint256 tokenId) external virtual exceptYourself {
	// 	require(offered[tokenId].sender == msg.sender, "KD116");
	// 	_refundOfferedAmount(tokenId);
	// 	_offeredTotal -= offered[tokenId].price;
	// 	delete offered[tokenId];
	// 	_eventEmitter().emitCancelOffer(tokenId);
	// }

	// /// @dev Accepts an offer by the Media.
	// /// @param tokenId uint256 of the token ID
	// /// @param tokenMetadata string of the NFT token metadata
	// function acceptOffer(uint256 tokenId, string memory tokenMetadata)
	// 	external
	// 	virtual
	// 	onlyMedia
	// {
	// 	Sale.Offer memory offer = offered[tokenId];
	// 	require(offer.sender != address(0), "KD115");
	// 	_checkOverlapping(
	// 		offer.spaceMetadata,
	// 		offer.displayStartTimestamp,
	// 		offer.displayEndTimestamp
	// 	);
	// 	Ad.Period memory period = Ad.Period(
	// 		offer.sender,
	// 		offer.spaceMetadata,
	// 		tokenMetadata,
	// 		_blockTimestamp(),
	// 		_blockTimestamp(),
	// 		offer.displayStartTimestamp,
	// 		offer.displayEndTimestamp,
	// 		Ad.Pricing.OFFER,
	// 		offer.price,
	// 		offer.price,
	// 		true
	// 	);

	// 	_mintRight(offer.sender, tokenId, tokenMetadata);
	// 	_savePeriod(offer.spaceMetadata, tokenId, period);
	// 	_collectFees(offer.price / 10);

	// 	_offeredTotal -= offer.price;
	// 	delete offered[tokenId];

	// 	_eventEmitter().emitAcceptOffer(
	// 		tokenId,
	// 		offer.spaceMetadata,
	// 		tokenMetadata,
	// 		offer.displayStartTimestamp,
	// 		offer.displayEndTimestamp,
	// 		offer.price
	// 	);
	// 	_eventEmitter().emitTransferCustom(address(0), address(this), tokenId);
	// }

	/// @dev Receives the token you bidded if you are the successful bidder.
	/// @param tokenId uint256 of the token ID
	function receiveToken(uint256 tokenId)
		external
		virtual
		onlySuccessfulBidder(tokenId)
	{
		// _toSuccessfulBidder(tokenId, msg.sender);
	}

	/// @dev Receives the token you bidded if you are the successful bidder.
	/// @param tokenId uint256 of the token ID
	function pushToSuccessfulBidder(uint256 tokenId) external virtual onlyMedia {
		// _toSuccessfulBidder(tokenId, _english().bidding(tokenId).bidder);
	}

	/// @dev Offers to buy a period that the sender requests.
	/// @param spaceMetadata string of the space metadata
	/// @param displayStartTimestamp uint256 of the start timestamp for the display
	/// @param displayEndTimestamp uint256 of the end timestamp for the display
	function offerPeriod(
		string memory spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp
	) external payable virtual exceptYourself {
		// require(_adPool().spaced(spaceMetadata), "KD101");
		// require(displayStartTimestamp < displayEndTimestamp, "KD113");
		// uint256 tokenId = Ad.id(
		// 	spaceMetadata,
		// 	displayStartTimestamp,
		// 	displayEndTimestamp
		// );
		// offered[tokenId] = Sale.Offer(
		// 	spaceMetadata,
		// 	displayStartTimestamp,
		// 	displayEndTimestamp,
		// 	msg.sender,
		// 	msg.value
		// );
		uint256 tokenId = _offerBid().offer(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp,
			msg.sender,
			msg.value
		);
		_offeredTotal += msg.value;
		_eventEmitter().emitOfferPeriod(
			tokenId,
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp,
			msg.sender,
			msg.value
		);
	}

	/// @dev Cancels an offer.
	/// @param tokenId uint256 of the token ID
	function cancelOffer(uint256 tokenId) external virtual exceptYourself {
		// require(offered[tokenId].sender == msg.sender, "KD116");
		// _refundOfferedAmount(tokenId);
		_offerBid().cancel(tokenId);
		// TODO: _offeredTotal -= offered[tokenId].price;
		// delete offered[tokenId];
		_eventEmitter().emitCancelOffer(tokenId);
	}

	/// @dev Accepts an offer by the Media.
	/// @param tokenId uint256 of the token ID
	/// @param tokenMetadata string of the NFT token metadata
	function acceptOffer(uint256 tokenId, string memory tokenMetadata)
		external
		virtual
		onlyMedia
	{
		// Sale.Offer memory offer = offered[tokenId];
		// require(offer.sender != address(0), "KD115");
		// _adPool().acceptOffer(tokenId, tokenMetadata, offer);
		(address sender, uint256 price) = _offerBid().accept(
			tokenId,
			tokenMetadata
		);
		_mintRight(sender, tokenId, tokenMetadata);
		_collectFees(price / 10);

		_offeredTotal -= price;
		// delete offered[tokenId];
		_eventEmitter().emitTransferCustom(address(0), address(this), tokenId);
	}

	/// @dev Withdraws the fund deposited to the proxy contract.
	///      If you put 0 as the amount, you can withdraw as much as possible.
	function withdraw() external virtual onlyMedia {
		uint256 withdrawal = withdrawalAmount();
		(bool success, ) = payable(msg.sender).call{
			value: withdrawal,
			gas: 10000
		}("");
		if (success) {
			_eventEmitter().emitWithdraw(withdrawal);
		} else {
			_eventEmitter().emitPaymentFailure(msg.sender, withdrawal);
		}
	}

	/// @dev Proposes the metadata to the token you bought.
	///      Users can propose many times as long as it is accepted.
	/// @param tokenId uint256 of the token ID
	/// @param metadata string of the proposal metadata
	function propose(uint256 tokenId, string memory metadata) external virtual {
		require(ownerOf(tokenId) == msg.sender, "KD012");
		_proposeToRight(tokenId, metadata);
		_eventEmitter().emitPropose(tokenId, metadata);
	}

	/// @dev Accepts the proposal.
	/// @param tokenId uint256 of the token ID
	function acceptProposal(uint256 tokenId) external virtual onlyMedia {
		string memory metadata = proposed[tokenId].content;
		require(bytes(metadata).length != 0, "KD130");
		require(ownerOf(tokenId) == proposed[tokenId].proposer, "KD131");
		_acceptProposal(tokenId, metadata);
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
	) external virtual onlyMedia {
		string memory metadata = proposed[tokenId].content;
		require(bytes(metadata).length != 0, "KD130");
		deniedReasons[tokenId].push(Draft.Denied(reason, offensive));
		_eventEmitter().emitDenyProposal(tokenId, metadata, reason, offensive);
	}

	/// @dev Overrides transferFrom to emit an event from the common emitter.
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		super.transferFrom(from, to, tokenId);
		_eventEmitter().emitTransferCustom(from, to, tokenId);
	}

	/// @dev Overrides transferFrom to emit an event from the common emitter.
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		super.safeTransferFrom(from, to, tokenId);
		_eventEmitter().emitTransferCustom(from, to, tokenId);
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
	) public pure virtual returns (uint256) {
		return Ad.id(spaceMetadata, displayStartTimestamp, displayEndTimestamp);
	}

	/// @dev Returns the balacne deposited on the proxy contract.
	function balance() public view virtual returns (uint256) {
		return address(this).balance;
	}

	/// @dev Returns the withdrawal amount.
	function withdrawalAmount() public view virtual returns (uint256) {
		return address(this).balance - _biddingTotal - _offeredTotal;
	}

	/// @dev Displays the ad content that is approved by the media owner.
	/// @param spaceMetadata string of the space metadata
	function display(string memory spaceMetadata)
		external
		view
		virtual
		returns (string memory, uint256)
	{
		uint256[] memory tokenIds = _adPool().tokenIdsOf(spaceMetadata);
		for (uint256 i = 0; i < tokenIds.length; i++) {
			if (tokenIds[i] != 0) {
				Ad.Period memory period = _adPool().allPeriods(tokenIds[i]);
				if (
					period.displayStartTimestamp <= _blockTimestamp() &&
					period.displayEndTimestamp >= _blockTimestamp()
				) {
					return (accepted[tokenIds[i]], tokenIds[i]);
				}
			}
		}
		return ("", 0);
	}

	// function _checkBeforeReceiveToken(uint256 tokenId) internal view virtual {
	// 	require(periods[tokenId].pricing == Ad.Pricing.ENGLISH, "KD124");
	// 	require(!periods[tokenId].sold, "KD121");
	// 	require(periods[tokenId].saleEndTimestamp < _blockTimestamp(), "KD125");
	// }

	function _checkBeforeReceiveToken(uint256 tokenId) internal view virtual {
		Ad.Period memory period = _adPool().allPeriods(tokenId);
		require(period.pricing == Ad.Pricing.ENGLISH, "KD124");
		require(!period.sold, "KD121");
		require(period.saleEndTimestamp < _blockTimestamp(), "KD125");
	}

	// function _refundToProposers(uint256 tokenId, uint256 successfulBidderNo)
	// 	internal
	// 	virtual
	// {
	// 	for (uint256 i = 0; i < appealed[tokenId].length; i++) {
	// 		Sale.Appeal memory appeal = appealed[tokenId][i];
	// 		_biddingTotal -= appeal.price;
	// 		if (i == successfulBidderNo) {
	// 			_collectFees(appeal.price / 10);
	// 		} else {
	// 			(bool success, ) = payable(appeal.sender).call{
	// 				value: appeal.price,
	// 				gas: 10000
	// 			}("");
	// 			if (!success) {
	// 				_eventEmitter().emitPaymentFailure(appeal.sender, appeal.price);
	// 			}
	// 		}
	// 	}
	// }

	//TODO
	// function _toSuccessfulBidder(uint256 tokenId, address receiver)
	// 	internal
	// 	virtual
	// {
	// 	_checkBeforeReceiveToken(tokenId);
	// 	uint256 price = bidding[tokenId].price;
	// 	periods[tokenId].sold = true;
	// 	// period.sold = true;
	// 	_adPool().sold(tokenId);
	// 	_biddingTotal -= price;
	// 	_dropRight(receiver, tokenId);
	// 	_collectFees(price / 10);
	// 	delete bidding[tokenId];
	// 	_eventEmitter().emitReceiveToken(
	// 		tokenId,
	// 		price,
	// 		receiver,
	// 		_blockTimestamp()
	// 	);
	// 	_eventEmitter().emitTransferCustom(address(this), receiver, tokenId);
	// }

	function _collectFees(uint256 value) internal virtual {
		address vault = vaultAddress();
		(bool success, ) = payable(vault).call{ value: value, gas: 10000 }("");
		if (!success) {
			_eventEmitter().emitPaymentFailure(vault, value);
		}
	}
}
