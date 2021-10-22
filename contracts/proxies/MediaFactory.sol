// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../proxies/MediaProxy.sol";
import "../accessors/NameAccessor.sol";
import "../base/MediaRegistry.sol";
import "hardhat/console.sol";

/// @title MediaFactory - create a proxy contract according to a donation media.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
contract MediaFactory is NameAccessor {
	/// @dev Emitted when a new media is created.
	event CreateProxy(MediaProxy proxy, address singleton);

	constructor(address _nameRegistry) {
		initialize(_nameRegistry);
	}

	function newMedia(
		string memory metadata,
		bytes memory initializer,
		uint256 saltNonce
	) external returns (MediaProxy proxy) {
		proxy = createProxyWithNonce(nameRegistryAddress(), initializer, saltNonce);
		_registry().addMedia(address(proxy), metadata, msg.sender);
	}

	/// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
	/// @param accessor Address of accessor contract.
	/// @param initializer Payload for message call sent to new proxy contract.
	/// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
	function createProxyWithNonce(
		address accessor,
		bytes memory initializer,
		uint256 saltNonce
	) internal returns (MediaProxy proxy) {
		proxy = deployProxyWithNonce(accessor, initializer, saltNonce);
		if (initializer.length > 0)
			// solhint-disable-next-line no-inline-assembly
			assembly {
				if eq(
					call(
						gas(),
						proxy,
						0,
						add(initializer, 0x20),
						mload(initializer),
						0,
						0
					),
					0
				) {
					revert(0, 0)
				}
			}
		emit CreateProxy(proxy, accessor);
	}

	/// @dev Allows to create new proxy contact using CREATE2 but it doesn't run the initializer.
	///      This method is only meant as an utility to be called from other methods
	/// @param accessor Address of accessor contract.
	/// @param initializer Payload for message call sent to new proxy contract.
	/// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
	function deployProxyWithNonce(
		address accessor,
		bytes memory initializer,
		uint256 saltNonce
	) internal returns (MediaProxy proxy) {
		// If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
		bytes32 salt = keccak256(
			abi.encodePacked(keccak256(initializer), saltNonce)
		);
		bytes memory deploymentData = abi.encodePacked(
			type(MediaProxy).creationCode,
			uint256(uint160(accessor))
		);
		// solhint-disable-next-line no-inline-assembly
		assembly {
			proxy := create2(
				0x0,
				add(0x20, deploymentData),
				mload(deploymentData),
				salt
			)
		}
		require(address(proxy) != address(0), "Create2 call failed");
	}

	function _registry() internal view returns (MediaRegistry) {
		return MediaRegistry(mediaRegistryAddress());
	}
}
