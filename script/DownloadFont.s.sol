// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IFileStore} from "../src/IFileStore.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DownloadFontScript is Script {
    address public constant FILE_STORE =
        0xFe1411d6864592549AdE050215482e4385dFa0FB;

    function run() external {
        // Read the font file from EthFS (returns base64-encoded string)
        string memory base64Font = IFileStore(FILE_STORE).readFile(
            "IBMPlexMono-Regular.woff2"
        );

        // Decode the base64 string to get the binary data
        bytes memory fontData = Base64.decode(base64Font);

        // Write the binary data to the assets directory
        vm.writeFileBinary("assets/IBMPlexMono-Regular.woff2", fontData);

        console.log(
            "Font file downloaded successfully to assets/IBMPlexMono-Regular.woff2"
        );
    }
}
