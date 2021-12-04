// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "../interfaces/IMediaRegistry.sol";
import "../interfaces/IAdPool.sol";
import "../interfaces/IEnglishAuction.sol";
import "../interfaces/IEventEmitter.sol";
import "../interfaces/IOpenBid.sol";
import "../interfaces/IOfferBid.sol";
import "./Storage.sol";

/// @title SpaceManager - manages ad spaces.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract SpaceManager is NameAccessor, Storage {
	// function _newSpace(string memory spaceMetadata) internal virtual {
	// 	require(!_adPool().spaced(spaceMetadata), "KD100");
	// 	_adPool().addSpace(spaceMetadata);
	// 	_eventEmitter().emitNewSpace(spaceMetadata);
	// }

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view virtual returns (IMediaRegistry) {
		return IMediaRegistry(mediaRegistryAddress());
	}

	function _adPool() internal view virtual returns (IAdPool) {
		return IAdPool(adPoolAddress());
	}

	function _eventEmitter() internal view virtual returns (IEventEmitter) {
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
}
