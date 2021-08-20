// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../accessors/NameAccessor.sol";

/// @title DistributionRight - represents advertising distribution rights.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdPool is NameAccessor {
	constructor(address nameRegistry) NameAccessor(nameRegistry) {}

	function call() public {}
}
