// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Form {
    mapping(address => uint8) public v;

    function s(uint8 b) public {
        v[msg.sender] = b;
    }

    function g(address o) public view returns (uint8) {
        return v[o] != 0 ? v[o] : uint8(uint256(keccak256(abi.encodePacked(o))));
    }
}
