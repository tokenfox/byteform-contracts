// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from "forge-std/Vm.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

/// @notice Mock FileStore for testing - returns font file from assets (base64 encoded)
contract MockFileStore {
    Vm private constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    // Make sure to add read access to allowlisted asset path in `foundry.toml`
    string public constant ASSET_PATH = "assets/";

    function readFile(
        string memory filename
    ) external view returns (string memory) {
        bytes memory fileData = vm.readFileBinary(
            string.concat(ASSET_PATH, filename)
        );
        return Base64.encode(fileData);
    }
}
