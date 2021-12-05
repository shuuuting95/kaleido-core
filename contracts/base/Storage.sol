// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @title Storage - saves state values. Note that the order of the state values
///                  should not be reordered when upgrading because the slot would be shifted.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
abstract contract Storage {
	/// @dev Temporal amount that is deposited by bid or offered.
	uint256 internal _processingTotal;
}
