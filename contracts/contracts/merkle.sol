// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestMerkle {
    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    function testMerkle_old(
        bytes32[] calldata proofElements,
        uint256[] calldata proofPath
    ) public returns (bytes32) {
        bytes32 currHash = bytes32(0);
        for (uint256 ii = 0; ii < proofElements.length; ii++) {
            if (proofPath[ii] == 0) {
                currHash = _efficientHash(currHash, proofElements[ii]);
            } else {
                currHash = _efficientHash(proofElements[ii], currHash);
            }
        }
        return currHash;
    }
    
    function testMerkle(
        bytes32[] calldata proofElements,
        uint256 proofPath
    ) public returns (bytes32) {
        bytes32 currHash = bytes32(0);
        uint256 shiftedPath = proofPath >> 1;
        for (uint256 ii = 0; ii < proofElements.length; ii++) {
            if (proofPath - (shiftedPath << 1) == 0) {
                currHash = _efficientHash(currHash, proofElements[ii]);
            } else {
                currHash = _efficientHash(proofElements[ii], currHash);
            }
            proofPath = shiftedPath;
            shiftedPath = proofPath >> 1;
        }
        return currHash;
    }
}
