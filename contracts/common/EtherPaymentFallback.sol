// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/// @title EtherPaymentFallback - A contract that has a fallback to accept ether payments.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract EtherPaymentFallback {
	event Received(address, uint256);

	/// @dev Fallback function accepts Ether transactions.
	receive() external payable virtual {
		emit Received(msg.sender, msg.value);
	}
}
