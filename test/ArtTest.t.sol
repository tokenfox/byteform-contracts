// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {Byte} from "../src/Byte.sol";
import {Form} from "../src/Form.sol";
import {ByteformRenderer} from "../src/ByteformRenderer.sol";
import {Byteform} from "../src/Byteform.sol";
import {MockFileStore} from "./mocks/MockFileStore.sol";

contract ArtTest is Test {
    address public constant FILE_STORE =
        0xFe1411d6864592549AdE050215482e4385dFa0FB;

    /// @notice Deploy mock FileStore to the expected address using vm.etch
    function _deployMockFileStore() internal {
        MockFileStore mockFileStore = new MockFileStore();
        vm.etch(FILE_STORE, address(mockFileStore).code);
    }
    Byte public byteContract;
    Form public formContract;
    ByteformRenderer public renderer;
    Byteform public byteform;
    address public deployer;

    function _getNumNullWallets(
        uint256 numWallets
    ) internal pure returns (uint256) {
        if (numWallets == 2 || numWallets == 5 || numWallets == 25) {
            return 5;
        } else if (numWallets == 50) {
            return 2;
        } else if (numWallets == 80) {
            return 0;
        }
        return 0;
    }

    function _setupForWalletCount(uint256 numWallets) internal {
        deployer = address(this);
        _deployMockFileStore();

        // Deploy Byte and ByteformRenderer first
        byteContract = new Byte();
        formContract = new Form();
        renderer = new ByteformRenderer();

        // Deploy Byteform that connects to Byte and ByteformRenderer
        byteform = new Byteform(
            deployer,
            address(byteContract),
            address(formContract),
            address(renderer)
        );

        // Get number of null wallets for this test case
        uint256 numNullWallets = _getNumNullWallets(numWallets);
        uint256 totalWallets = numWallets + numNullWallets;

        // Create array to store all wallets (unique + null)
        address[] memory allWallets = new address[](totalWallets);

        // Add unique wallets to the array
        for (uint256 i = 0; i < numWallets; i++) {
            // Generate a deterministic unique address for each wallet
            address wallet = address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked("ArtTestWallet", numWallets, i)
                        )
                    )
                )
            );
            allWallets[i] = wallet;
        }

        // Add null addresses to the array
        for (uint256 i = 0; i < numNullWallets; i++) {
            allWallets[numWallets + i] = address(0);
        }

        // Claim bytes to random wallets from the combined array (unique + null)
        // Using deterministic selection based on hash for reproducibility
        for (uint256 i = 0; i < 256; i++) {
            // Use hash to determine which wallet index to use
            bytes32 hash = keccak256(
                abi.encodePacked("ArtTest", numWallets, i)
            );
            uint256 walletIndex = uint256(hash) % totalWallets;

            // Get the wallet address from the array
            address mockAddress = allWallets[walletIndex];

            // Claim the byte using the mock address
            vm.prank(mockAddress);

            // casting to 'uint8' is safe because i is in range 0-255
            // forge-lint: disable-next-line(unsafe-typecast)
            byteContract.c(uint8(i));
        }
    }

    function _setupForAll() internal {
        deployer = address(this);
        _deployMockFileStore();

        // Deploy Byte and ByteformRenderer first
        byteContract = new Byte();
        formContract = new Form();
        renderer = new ByteformRenderer();

        // Deploy Byteform that connects to Byte and ByteformRenderer
        byteform = new Byteform(
            deployer,
            address(byteContract),
            address(formContract),
            address(renderer)
        );

        // Create 256 unique wallets, one for each byte value
        for (uint256 i = 0; i < 256; i++) {
            // Generate a deterministic unique address for each wallet
            address wallet = address(
                uint160(
                    uint256(keccak256(abi.encodePacked("ArtTestAllWallet", i)))
                )
            );

            // Claim byte i with wallet i
            vm.prank(wallet);
            // casting to 'uint8' is safe because i is in range 0-255
            // forge-lint: disable-next-line(unsafe-typecast)
            byteContract.c(uint8(i));

            // Set form value i for wallet i
            vm.prank(wallet);
            // casting to 'uint8' is safe because i is in range 0-255
            // forge-lint: disable-next-line(unsafe-typecast)
            formContract.s(uint8(i));
        }
    }

    function _setupForWorstCase() internal {
        deployer = address(this);
        _deployMockFileStore();

        // Deploy Byte and ByteformRenderer first
        byteContract = new Byte();
        formContract = new Form();
        renderer = new ByteformRenderer();

        // Deploy Byteform that connects to Byte and ByteformRenderer
        byteform = new Byteform(
            deployer,
            address(byteContract),
            address(formContract),
            address(renderer)
        );

        // Claim all bytes
        for (uint256 i = 0; i < 256; i++) {
            // casting to 'uint8' is safe because i is in range 0-255
            // forge-lint: disable-next-line(unsafe-typecast)
            byteContract.c(uint8(i));
        }

        // Set form to "A"
        formContract.s(65);
    }

    function _setupForByteform() internal {
        deployer = address(this);
        _deployMockFileStore();

        // Deploy Byte and ByteformRenderer first
        byteContract = new Byte();
        formContract = new Form();
        renderer = new ByteformRenderer();

        // Deploy Byteform that connects to Byte and ByteformRenderer
        byteform = new Byteform(
            deployer,
            address(byteContract),
            address(formContract),
            address(renderer)
        );

        // "Byteform" in hex: 42 79 74 65 66 6f 72 6d
        uint8[8] memory formValues = [
            uint8(0x42),
            0x79,
            0x74,
            0x65,
            0x66,
            0x6f,
            0x72,
            0x6d
        ];

        // Create 8 unique wallets for bytes 0-7, each with corresponding form value
        for (uint256 i = 0; i < 8; i++) {
            // Create mock wallet with address 1-8
            address wallet = address(uint160(i + 1));

            // Claim byte i with wallet
            vm.prank(wallet);
            // casting to 'uint8' is safe because i is in range 0-7
            // forge-lint: disable-next-line(unsafe-typecast)
            byteContract.c(uint8(i));

            // Set form value for wallet
            vm.prank(wallet);
            formContract.s(formValues[i]);
        }

        // Claim bytes 8-255 with null address
        for (uint256 i = 8; i < 256; i++) {
            vm.prank(address(0));
            // casting to 'uint8' is safe because i is in range 8-255
            // forge-lint: disable-next-line(unsafe-typecast)
            byteContract.c(uint8(i));
        }
    }

    function _setupForUnrevealed() internal {
        deployer = address(this);
        _deployMockFileStore();

        // Deploy only ByteformRenderer
        renderer = new ByteformRenderer();

        // Deploy Byteform with null byteContract and formContract
        byteform = new Byteform(
            deployer,
            address(0),
            address(0),
            address(renderer)
        );
    }

    function _testTokenURI(uint256 numWallets) internal {
        // Call tokenURI for tokenId 0
        string memory tokenURI = byteform.tokenURI(0);

        // Verify the tokenURI is valid (starts with data:application/json;base64,)
        bytes memory uriBytes = bytes(tokenURI);
        assertGt(uriBytes.length, 0, "tokenURI should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "data:application/json;base64,";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            uriBytes.length,
            prefixBytes.length,
            "tokenURI should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                uriBytes[i],
                prefixBytes[i],
                "tokenURI should start with data:application/json;base64,"
            );
        }

        // Write the result to generated/{numWallets}.txt
        string memory filename = string(
            abi.encodePacked("generated/", vm.toString(numWallets), ".txt")
        );
        vm.writeFile(filename, tokenURI);
    }

    function _testTokenImageURI(uint256 numWallets) internal {
        // Call tokenImageURI for tokenId 0
        string memory tokenImageURI = byteform.tokenImageURI(0);

        // Verify the tokenImageURI is valid (starts with data:image/svg+xml;base64,)
        bytes memory uriBytes = bytes(tokenImageURI);
        assertGt(uriBytes.length, 0, "tokenImageURI should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "data:image/svg+xml;base64,";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            uriBytes.length,
            prefixBytes.length,
            "tokenImageURI should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                uriBytes[i],
                prefixBytes[i],
                "tokenImageURI should start with data:image/svg+xml;base64,"
            );
        }

        // Write the result to generated/{numWallets}-image.txt
        string memory filename = string(
            abi.encodePacked(
                "generated/",
                vm.toString(numWallets),
                "-image.txt"
            )
        );
        vm.writeFile(filename, tokenImageURI);
    }

    function _testTokenHTML(uint256 numWallets) internal {
        // Call tokenHTML for tokenId 0
        string memory tokenHTML = byteform.tokenHTML(0);

        // Verify the tokenHTML is valid (starts with <!DOCTYPE html>)
        bytes memory htmlBytes = bytes(tokenHTML);
        assertGt(htmlBytes.length, 0, "tokenHTML should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "<!DOCTYPE html>";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            htmlBytes.length,
            prefixBytes.length,
            "tokenHTML should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                htmlBytes[i],
                prefixBytes[i],
                "tokenHTML should start with <!DOCTYPE html>"
            );
        }

        // Write the result to generated/{numWallets}.html
        string memory filename = string(
            abi.encodePacked("generated/", vm.toString(numWallets), ".html")
        );
        vm.writeFile(filename, tokenHTML);
    }

    // Test functions for 2 wallets
    function testTokenURI_2() public {
        _setupForWalletCount(2);
        _testTokenURI(2);
    }

    function testTokenImageURI_2() public {
        _setupForWalletCount(2);
        _testTokenImageURI(2);
    }

    function testTokenHTML_2() public {
        _setupForWalletCount(2);
        _testTokenHTML(2);
    }

    // Test functions for 5 wallets
    function testTokenURI_5() public {
        _setupForWalletCount(5);
        _testTokenURI(5);
    }

    function testTokenImageURI_5() public {
        _setupForWalletCount(5);
        _testTokenImageURI(5);
    }

    function testTokenHTML_5() public {
        _setupForWalletCount(5);
        _testTokenHTML(5);
    }

    // Test functions for 25 wallets
    function testTokenURI_25() public {
        _setupForWalletCount(25);
        _testTokenURI(25);
    }

    function testTokenImageURI_25() public {
        _setupForWalletCount(25);
        _testTokenImageURI(25);
    }

    function testTokenHTML_25() public {
        _setupForWalletCount(25);
        _testTokenHTML(25);
    }

    // Test functions for 50 wallets
    function testTokenURI_50() public {
        _setupForWalletCount(50);
        _testTokenURI(50);
    }

    function testTokenImageURI_50() public {
        _setupForWalletCount(50);
        _testTokenImageURI(50);
    }

    function testTokenHTML_50() public {
        _setupForWalletCount(50);
        _testTokenHTML(50);
    }

    // Test functions for 80 wallets
    function testTokenURI_80() public {
        _setupForWalletCount(80);
        _testTokenURI(80);
    }

    function testTokenImageURI_80() public {
        _setupForWalletCount(80);
        _testTokenImageURI(80);
    }

    function testTokenHTML_80() public {
        _setupForWalletCount(80);
        _testTokenHTML(80);
    }

    // Test function for all wallets (256 unique wallets, each owning one byte with matching form value)
    function testTokenURI_all() public {
        _setupForAll();

        // Call tokenURI for tokenId 0 and measure gas
        uint256 gasBefore = gasleft();
        string memory tokenURI = byteform.tokenURI(0);
        uint256 gasUsed = gasBefore - gasleft();

        // Assert gas usage does not exceed limit
        assertLe(
            gasUsed,
            29_000_000,
            "tokenURI gas usage should not exceed 30M"
        );

        // Verify the tokenURI is valid (starts with data:application/json;base64,)
        bytes memory uriBytes = bytes(tokenURI);

        console.log("uriBytes length:", uriBytes.length);
        assertGt(uriBytes.length, 0, "tokenURI should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "data:application/json;base64,";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            uriBytes.length,
            prefixBytes.length,
            "tokenURI should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                uriBytes[i],
                prefixBytes[i],
                "tokenURI should start with data:application/json;base64,"
            );
        }

        // Write the result to generated/all.txt
        vm.writeFile("generated/all.txt", tokenURI);
    }

    // Test function for worst case gas and size usage (byte values 32-126 in repeating pattern)
    function testTokenURI_worstCase() public {
        _setupForWorstCase();

        // Call tokenURI for tokenId 0 and measure gas
        uint256 gasBefore = gasleft();
        string memory tokenURI = byteform.tokenURI(0);
        uint256 gasUsed = gasBefore - gasleft();

        // Ensure gas usage does not exceed known limits
        assertLe(
            gasUsed,
            29_000_000,
            "tokenURI gas usage should not exceed 30M"
        );

        // tokenURI must remain below known size limits (etherscan, etc.)
        assertLe(
            bytes(tokenURI).length,
            90 * 1024,
            "tokenURI payload size must not exceed 90 kB"
        );

        // Write the result to generated/worst-case.txt
        vm.writeFile("generated/worst-case.txt", tokenURI);
    }

    function testTokenImageURI_all() public {
        _setupForAll();

        // Call tokenImageURI for tokenId 0
        string memory tokenImageURI = byteform.tokenImageURI(0);

        // Verify the tokenImageURI is valid (starts with data:image/svg+xml;base64,)
        bytes memory uriBytes = bytes(tokenImageURI);
        assertGt(uriBytes.length, 0, "tokenImageURI should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "data:image/svg+xml;base64,";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            uriBytes.length,
            prefixBytes.length,
            "tokenImageURI should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                uriBytes[i],
                prefixBytes[i],
                "tokenImageURI should start with data:image/svg+xml;base64,"
            );
        }

        // Write the result to generated/all-image.txt
        vm.writeFile("generated/all-image.txt", tokenImageURI);
    }

    function testTokenHTML_all() public {
        _setupForAll();

        // Call tokenHTML for tokenId 0 and measure gas
        uint256 gasBefore = gasleft();
        string memory tokenHTML = byteform.tokenHTML(0);
        uint256 gasUsed = gasBefore - gasleft();

        // Assert gas usage does not exceed limit
        assertLe(
            gasUsed,
            29_000_000,
            "tokenHTML gas usage should not exceed 30M"
        );

        // Verify the tokenHTML is valid (starts with <!DOCTYPE html>)
        bytes memory htmlBytes = bytes(tokenHTML);
        assertGt(htmlBytes.length, 0, "tokenHTML should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "<!DOCTYPE html>";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            htmlBytes.length,
            prefixBytes.length,
            "tokenHTML should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                htmlBytes[i],
                prefixBytes[i],
                "tokenHTML should start with <!DOCTYPE html>"
            );
        }

        // Write the result to generated/all.html
        vm.writeFile("generated/all.html", tokenHTML);
    }

    // Test functions for byteform (8 wallets spelling "BYTEFORM", rest null)
    function testTokenURI_byteform() public {
        _setupForByteform();

        // Call tokenURI for tokenId 0
        string memory tokenURI = byteform.tokenURI(0);

        // Verify the tokenURI is valid (starts with data:application/json;base64,)
        bytes memory uriBytes = bytes(tokenURI);
        assertGt(uriBytes.length, 0, "tokenURI should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "data:application/json;base64,";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            uriBytes.length,
            prefixBytes.length,
            "tokenURI should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                uriBytes[i],
                prefixBytes[i],
                "tokenURI should start with data:application/json;base64,"
            );
        }

        // Write the result to generated/byteform.txt
        vm.writeFile("generated/byteform.txt", tokenURI);
    }

    function testTokenImageURI_byteform() public {
        _setupForByteform();

        // Call tokenImageURI for tokenId 0
        string memory tokenImageURI = byteform.tokenImageURI(0);

        // Verify the tokenImageURI is valid (starts with data:image/svg+xml;base64,)
        bytes memory uriBytes = bytes(tokenImageURI);
        assertGt(uriBytes.length, 0, "tokenImageURI should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "data:image/svg+xml;base64,";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            uriBytes.length,
            prefixBytes.length,
            "tokenImageURI should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                uriBytes[i],
                prefixBytes[i],
                "tokenImageURI should start with data:image/svg+xml;base64,"
            );
        }

        // Write the result to generated/byteform-image.txt
        vm.writeFile("generated/byteform-image.txt", tokenImageURI);
    }

    function testTokenHTML_byteform() public {
        _setupForByteform();

        // Call tokenHTML for tokenId 0
        string memory tokenHTML = byteform.tokenHTML(0);

        // Verify the tokenHTML is valid (starts with <!DOCTYPE html>)
        bytes memory htmlBytes = bytes(tokenHTML);
        assertGt(htmlBytes.length, 0, "tokenHTML should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "<!DOCTYPE html>";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            htmlBytes.length,
            prefixBytes.length,
            "tokenHTML should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                htmlBytes[i],
                prefixBytes[i],
                "tokenHTML should start with <!DOCTYPE html>"
            );
        }

        // Write the result to generated/byteform.html
        vm.writeFile("generated/byteform.html", tokenHTML);
    }

    // Test functions for unrevealed (null byteContract and formContract)
    function testTokenURI_unrevealed() public {
        _setupForUnrevealed();

        // Call tokenURI for tokenId 0
        string memory tokenURI = byteform.tokenURI(0);

        // Verify the tokenURI is valid (starts with data:application/json;base64,)
        bytes memory uriBytes = bytes(tokenURI);
        assertGt(uriBytes.length, 0, "tokenURI should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "data:application/json;base64,";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            uriBytes.length,
            prefixBytes.length,
            "tokenURI should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                uriBytes[i],
                prefixBytes[i],
                "tokenURI should start with data:application/json;base64,"
            );
        }

        // Write the result to generated/unrevealed.txt
        vm.writeFile("generated/unrevealed.txt", tokenURI);
    }

    function testTokenImageURI_unrevealed() public {
        _setupForUnrevealed();

        // Call tokenImageURI for tokenId 0
        string memory tokenImageURI = byteform.tokenImageURI(0);

        // Verify the tokenImageURI is valid (starts with data:image/svg+xml;base64,)
        bytes memory uriBytes = bytes(tokenImageURI);
        assertGt(uriBytes.length, 0, "tokenImageURI should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "data:image/svg+xml;base64,";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            uriBytes.length,
            prefixBytes.length,
            "tokenImageURI should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                uriBytes[i],
                prefixBytes[i],
                "tokenImageURI should start with data:image/svg+xml;base64,"
            );
        }

        // Write the result to generated/unrevealed-image.txt
        vm.writeFile("generated/unrevealed-image.txt", tokenImageURI);
    }

    function testTokenHTML_unrevealed() public {
        _setupForUnrevealed();

        // Call tokenHTML for tokenId 0
        string memory tokenHTML = byteform.tokenHTML(0);

        // Verify the tokenHTML is valid (starts with <!DOCTYPE html>)
        bytes memory htmlBytes = bytes(tokenHTML);
        assertGt(htmlBytes.length, 0, "tokenHTML should not be empty");

        // Check that it starts with the expected prefix
        string memory prefix = "<!DOCTYPE html>";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            htmlBytes.length,
            prefixBytes.length,
            "tokenHTML should be long enough"
        );

        // Verify prefix matches
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                htmlBytes[i],
                prefixBytes[i],
                "tokenHTML should start with <!DOCTYPE html>"
            );
        }

        // Write the result to generated/unrevealed.html
        vm.writeFile("generated/unrevealed.html", tokenHTML);
    }
}
