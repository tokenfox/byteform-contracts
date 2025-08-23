// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IFileStore
 * @notice Minimal interface for EthFS FileStore contract
 */
interface IFileStore {
    function readFile(string memory filename) external view returns (string memory contents);
}
