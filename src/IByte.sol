// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IByte {
    function o(uint8) external view returns (address);
    function c(uint8 b) external;
    function t(uint8 b, address r) external;
}

