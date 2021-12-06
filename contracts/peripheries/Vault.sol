// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/EtherPaymentFallback.sol";

/// @title Vault - collects fees as the system usage.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract Vault is Ownable, EtherPaymentFallback {
	event Withdraw(address sender, uint256 value);
	event PaymentFailure(address receiver, uint256 price);

	function balance() public view returns (uint256) {
		return address(this).balance;
	}

	/// @dev Withdraws the fund from the vault contract.
	/// @param amount uint256 of the amount the owner wants to withdraw
	function withdraw(uint256 amount) external onlyOwner {
		require(amount <= balance(), "KD140");
		(bool success, ) = payable(msg.sender).call{ value: amount, gas: 10000 }(
			""
		);
		if (success) {
			emit Withdraw(msg.sender, amount);
		} else {
			emit PaymentFailure(msg.sender, amount);
		}
	}
}
