// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @title IProxy - Helper interface to access masterCopy of the Proxy on-chain
interface IProxy {
	function masterCopy() external view returns (address);
}
