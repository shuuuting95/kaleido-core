// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/// @title Substrings - utilities for Substrings.
/// @author Shumpei Koike - <shumpei.koike@bridges.inc>
library Substrings {
	/**
	 * Sub String
	 *
	 * Extracts the beginning part of a string based on the desired length
	 *
	 * @param _base When being used for a data type this is the extended object
	 *              otherwise this is the string that will be used for
	 *              extracting the sub string from
	 * @param _length The length of the sub string to be extracted from the base
	 * @return string The extracted sub string
	 */
	function substring(string memory _base, int256 _length)
		public
		pure
		returns (string memory)
	{
		return substring(_base, _length, 0);
	}

	/**
	 * Sub String
	 *
	 * Extracts the part of a string based on the desired length and offset. The
	 * offset and length must not exceed the lenth of the base string.
	 *
	 * @param _base When being used for a data type this is the extended object
	 *              otherwise this is the string that will be used for
	 *              extracting the sub string from
	 * @param _length The length of the sub string to be extracted from the base
	 * @param _offset The starting point to extract the sub string from
	 * @return string The extracted sub string
	 */
	function substring(
		string memory _base,
		int256 _length,
		int256 _offset
	) public pure returns (string memory) {
		bytes memory _baseBytes = bytes(_base);

		assert(uint256(_offset + _length) <= _baseBytes.length);

		string memory _tmp = new string(uint256(_length));
		bytes memory _tmpBytes = bytes(_tmp);

		uint256 j = 0;
		for (uint256 i = uint256(_offset); i < uint256(_offset + _length); i++) {
			_tmpBytes[j++] = _baseBytes[i];
		}

		return string(_tmpBytes);
	}
}
