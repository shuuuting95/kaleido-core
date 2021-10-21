// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/NameAccessor.sol";
import "./MediaRegistry.sol";
import "./BlockTimestamp.sol";

/// @title AdPool - stores all ads accorss every space.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdPool is BlockTimestamp, NameAccessor {
	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	function addPeriod() external {}

	/**
	 * Accessors
	 */
	function _mediaRegistry() internal view returns (MediaRegistry) {
		return MediaRegistry(mediaRegistryAddress());
	}
}
