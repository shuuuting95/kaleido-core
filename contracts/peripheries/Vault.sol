// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../accessors/Ownable.sol";
import "../common/EtherPaymentFallback.sol";

/// @title Vault - collects fees as the system usage.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract Vault is Ownable, EtherPaymentFallback {
	event Withdraw(address sender, uint256 value);

	function balance() public view returns (uint256) {
		return address(this).balance;
	}

	/// @dev Withdraws the fund from the vault contract.
	/// @param amount uint256 of the amount the owner wants to withdraw
	function withdraw(uint256 amount) public onlyOwner {
		require(amount <= balance(), "KD140");
		payable(msg.sender).transfer(amount);
		emit Withdraw(msg.sender, amount);
	}
}
