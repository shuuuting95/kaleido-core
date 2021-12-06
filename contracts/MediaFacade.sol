// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./base/ERC721.sol";
import "./base/Storage.sol";
import "./libraries/Sale.sol";
import "./common/BlockTimestamp.sol";
import "./accessors/NameAccessor.sol";
import "./interfaces/IMediaRegistry.sol";
import "./interfaces/IAdPool.sol";
import "./interfaces/IEnglishAuction.sol";
import "./interfaces/IEventEmitter.sol";
import "./interfaces/IOpenBid.sol";
import "./interfaces/IOfferBid.sol";
import "./interfaces/IProposalReview.sol";

/// @title MediaFacade - A root contract that calls the processes of each media.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract MediaFacade is
	ERC721,
	ReentrancyGuard,
	NameAccessor,
	BlockTimestamp,
	Storage
{
	/// @dev Can call it by only the media
	modifier onlyMedia() {
		require(_mediaRegistry().ownerOf(address(this)) == msg.sender, "KD012");
		_;
	}

	/// @dev Prevents the media from calling by yourself
	modifier exceptMedia() {
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
	/// @param tokenMetadata string of the token metadata
	/// @param mediaEOA address of the media owner
	/// @param nameRegistry address of NameRegistry
	function initialize(
		string memory title,
		string memory baseURI,
		string memory tokenMetadata,
		address mediaEOA,
		address nameRegistry
	) external virtual initializer {
		_name = title;
		_symbol = string(abi.encodePacked("Kaleido_", title));
		_baseURI = baseURI;
		_mintRight(mediaEOA, 0, tokenMetadata);
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
	}

	/// @dev Creates a new space for the media account.
	/// @param spaceMetadata string of the space metadata
	function newSpace(string memory spaceMetadata) external virtual onlyMedia {
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
	}

	/// @dev Deletes a period and its token.
	///      If there is any users locking the fund for the sale, the amount would be transfered
	///      to the user when deleting the period.
	/// @param tokenId uint256 of the token ID
	function deletePeriod(uint256 tokenId) external virtual onlyMedia {
		require(ownerOf(tokenId) == address(this), "KD121");
		_adPool().deletePeriod(tokenId);
		_burnRight(tokenId);
	}

	/// @dev Buys the token that is defined as the specific period on an ad space.
	///      The price of the token is fixed.
	/// @param tokenId uint256 of the token ID
	function buy(uint256 tokenId) external payable virtual exceptMedia {
		_adPool().soldByFixedPrice(tokenId, msg.value);
		_dropRight(msg.sender, tokenId);
		_collectFees(msg.value / 10);
		_event().emitBuy(tokenId, msg.value, msg.sender, _blockTimestamp());
	}

	/// @dev Buys the token that is defined as the specific period on an ad space.
	///      The price is decreasing as time goes by, that is defined as an Dutch Auction.
	/// @param tokenId uint256 of the token ID
	function buyBasedOnTime(uint256 tokenId)
		external
		payable
		virtual
		exceptMedia
	{
		_adPool().soldByDutchAuction(tokenId, msg.value);
		_dropRight(msg.sender, tokenId);
		_collectFees(msg.value / 10);
		_event().emitBuy(tokenId, msg.value, msg.sender, _blockTimestamp());
	}

	/// @dev Bids to participate in an auction.
	///      It is defined as an English Auction.
	/// @param tokenId uint256 of the token ID
	function bid(uint256 tokenId)
		external
		payable
		virtual
		exceptMedia
		nonReentrant
	{
		Sale.Bidding memory prev = _adPool().bidByEnglishAuction(
			tokenId,
			msg.sender,
			msg.value
		);
		_refundBiddingAmount(prev);
		_processingTotal += (msg.value - prev.price);
	}

	/// @dev Bids to participate in an auction.
	///      It is defined as an Open Bid.
	/// @param tokenId uint256 of the token ID
	/// @param proposalMetadata string of the metadata hash
	function bidWithProposal(uint256 tokenId, string memory proposalMetadata)
		external
		payable
		virtual
		exceptMedia
	{
		_adPool().bidWithProposal(tokenId, proposalMetadata, msg.sender, msg.value);
		_processingTotal += msg.value;
	}

	/// @dev Selects the best proposal bidded with.
	/// @param tokenId uint256 of the token ID
	/// @param index uint256 of the index number
	function selectProposal(uint256 tokenId, uint256 index)
		external
		virtual
		onlyMedia
		nonReentrant
	{
		(
			Sale.OpenBid memory selected,
			Sale.OpenBid[] memory nonSelected
		) = _openBid().selectProposal(tokenId, index);
		_dropRight(selected.sender, tokenId);
		_processingTotal -= selected.price;
		_collectFees(selected.price / 10);
		_refundToProposers(nonSelected);
	}

	/// @dev Receives the token you bidded if you are the successful bidder.
	/// @param tokenId uint256 of the token ID
	function receiveToken(uint256 tokenId)
		external
		virtual
		onlySuccessfulBidder(tokenId)
	{
		_toSuccessfulBidder(tokenId, msg.sender);
	}

	/// @dev Receives the token you bidded if you are the successful bidder.
	/// @param tokenId uint256 of the token ID
	function pushToSuccessfulBidder(uint256 tokenId) external virtual onlyMedia {
		_toSuccessfulBidder(tokenId, _english().bidding(tokenId).bidder);
	}

	/// @dev Offers to buy a period that the sender requests.
	/// @param spaceMetadata string of the space metadata
	/// @param displayStartTimestamp uint256 of the start timestamp for the display
	/// @param displayEndTimestamp uint256 of the end timestamp for the display
	function offerPeriod(
		string memory spaceMetadata,
		uint256 displayStartTimestamp,
		uint256 displayEndTimestamp
	) external payable virtual exceptMedia {
		_offerBid().offer(
			spaceMetadata,
			displayStartTimestamp,
			displayEndTimestamp,
			msg.sender,
			msg.value
		);
		_processingTotal += msg.value;
	}

	/// @dev Cancels an offer.
	/// @param tokenId uint256 of the token ID
	function cancelOffer(uint256 tokenId)
		external
		virtual
		exceptMedia
		nonReentrant
	{
		Sale.Offer memory prev = _offerBid().cancel(tokenId, msg.sender);
		_refundOfferedAmount(prev);
		_processingTotal -= prev.price;
	}

	/// @dev Accepts an offer by the Media.
	/// @param tokenId uint256 of the token ID
	/// @param tokenMetadata string of the NFT token metadata
	function acceptOffer(uint256 tokenId, string memory tokenMetadata)
		external
		virtual
		onlyMedia
	{
		Sale.Offer memory target = _offerBid().accept(tokenId);
		_adPool().acceptOffer(tokenId, tokenMetadata, target);
		_mintRight(target.sender, tokenId, tokenMetadata);
		_collectFees(target.price / 10);
		_processingTotal -= target.price;
	}

	/// @dev Withdraws the fund deposited to the proxy contract.
	///      If you put 0 as the amount, you can withdraw as much as possible.
	function withdraw() external virtual onlyMedia {
		uint256 withdrawal = withdrawalAmount();
		bool success = _pay(msg.sender, withdrawal);
		if (success) _event().emitWithdraw(withdrawal);
	}

	/// @dev Proposes the metadata to the token you bought.
	///      Users can propose many times as long as it is accepted.
	/// @param tokenId uint256 of the token ID
	/// @param metadata string of the proposal metadata
	function propose(uint256 tokenId, string memory metadata) external virtual {
		require(ownerOf(tokenId) == msg.sender, "KD012");
		_review().propose(tokenId, metadata, msg.sender);
	}

	/// @dev Accepts the proposal.
	/// @param tokenId uint256 of the token ID
	function acceptProposal(uint256 tokenId) external virtual onlyMedia {
		require(ownerOf(tokenId) == _review().proposer(tokenId), "KD131");
		_review().accept(tokenId);
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
		_review().denyProposal(tokenId, reason, offensive);
	}

	/// @dev Overrides transferFrom to emit an event from the common emitter.
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		super.transferFrom(from, to, tokenId);
		_event().emitTransferCustom(from, to, tokenId);
	}

	/// @dev Overrides transferFrom to emit an event from the common emitter.
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		super.safeTransferFrom(from, to, tokenId);
		_event().emitTransferCustom(from, to, tokenId);
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
		return address(this).balance - _processingTotal;
	}

	function _mintRight(
		address reciever,
		uint256 tokenId,
		string memory metadata
	) internal virtual {
		_mint(reciever, tokenId);
		_tokenURIs[tokenId] = metadata;
		if (tokenId != 0)
			_event().emitTransferCustom(address(0), reciever, tokenId);
	}

	function _burnRight(uint256 tokenId) internal virtual {
		_burn(tokenId);
		_tokenURIs[tokenId] = "";
		_event().emitTransferCustom(address(this), address(0), tokenId);
	}

	function _dropRight(address receiver, uint256 tokenId) internal virtual {
		_transfer(address(this), receiver, tokenId);
		_event().emitTransferCustom(address(this), receiver, tokenId);
	}

	function _refundBiddingAmount(Sale.Bidding memory prev) internal virtual {
		_pay(prev.bidder, prev.price);
	}

	function _refundOfferedAmount(Sale.Offer memory prev) internal virtual {
		_pay(prev.sender, prev.price);
	}

	function _refundToProposers(Sale.OpenBid[] memory nonSelected)
		internal
		virtual
	{
		for (uint256 i = 0; i < nonSelected.length; i++) {
			Sale.OpenBid memory target = nonSelected[i];
			_processingTotal -= target.price;
			_pay(target.sender, target.price);
		}
	}

	function _pay(address receiver, uint256 price)
		internal
		virtual
		returns (bool success)
	{
		(success, ) = payable(receiver).call{ value: price, gas: 10000 }("");
		if (!success) {
			_event().emitPaymentFailure(receiver, price);
		}
	}

	function _toSuccessfulBidder(uint256 tokenId, address receiver)
		internal
		virtual
	{
		(, uint256 price) = _adPool().soldByEnglishAuction(tokenId);
		_processingTotal -= price;
		_dropRight(receiver, tokenId);
		_collectFees(price / 10);
	}

	function _collectFees(uint256 value) internal virtual {
		_pay(vaultAddress(), value);
	}

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view virtual returns (IMediaRegistry) {
		return IMediaRegistry(mediaRegistryAddress());
	}

	function _adPool() internal view virtual returns (IAdPool) {
		return IAdPool(adPoolAddress());
	}

	function _event() internal view virtual returns (IEventEmitter) {
		return IEventEmitter(eventEmitterAddress());
	}

	function _english() internal view virtual returns (IEnglishAuction) {
		return IEnglishAuction(englishAuctionAddress());
	}

	function _openBid() internal view virtual returns (IOpenBid) {
		return IOpenBid(openBidAddress());
	}

	function _offerBid() internal view virtual returns (IOfferBid) {
		return IOfferBid(offerBidAddress());
	}

	function _review() internal view virtual returns (IProposalReview) {
		return IProposalReview(proposalReviewAddress());
	}
}
