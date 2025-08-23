// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from "forge-std/Vm.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

/// @notice Mock FileStore for testing - returns font file from assets (base64 encoded)
contract MockFileStore {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function readFile(string memory filename) external view returns (string memory) {
        if (keccak256(bytes(filename)) == keccak256(bytes("IBMPlexMono-Regular.woff2"))) {
            bytes memory fileData = vm.readFileBinary("assets/IBMPlexMono-Regular.woff2");
            return Base64.encode(fileData);
        }
        return "";
    }
}

