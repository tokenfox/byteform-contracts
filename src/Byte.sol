// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Byte {
    mapping(uint8 => address) public o;

    function c(uint8 b) public {
        if (o[b] != address(0)) revert();
        o[b] = msg.sender;
    }

    function t(uint8 b, address r) public {
        if (o[b] != msg.sender) revert();
        o[b] = r;
    }
}
