// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IForm {
    function v(address) external view returns (uint8);
    function s(uint8 b) external;
    function g(address o) external view returns (uint8);
}

