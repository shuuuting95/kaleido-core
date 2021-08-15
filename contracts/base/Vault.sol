// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "../access/Ownable.sol";
import "../common/EtherPaymentFallback.sol";

contract Vault is Ownable, EtherPaymentFallback {
	function balance() public view returns (uint256) {
		return address(this).balance;
	}

	function withdraw(uint256 amount) public onlyOwner {
		require(amount > balance(), "AD109");
		payable(msg.sender).transfer(amount);
	}
}
