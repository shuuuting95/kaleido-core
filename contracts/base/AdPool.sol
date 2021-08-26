// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../accessors/NameAccessor.sol";
import "../common/EtherPaymentFallback.sol";

/// @title AdPool - pools the assets before distribution.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract AdPool is EtherPaymentFallback, NameAccessor {
	constructor(address nameRegistry) NameAccessor(nameRegistry) {}

	function receivePooledAmount(address sender, uint256 amount)
		public
		onlyAllowedContract
	{
		payable(sender).transfer(amount);
	}
}
