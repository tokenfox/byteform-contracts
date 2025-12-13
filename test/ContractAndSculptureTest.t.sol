// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Byte} from "../src/Byte.sol";
import {Form} from "../src/Form.sol";
import {ByteformRenderer} from "../src/ByteformRenderer.sol";
import {Byteform} from "../src/Byteform.sol";
import {MockFileStore} from "./mocks/MockFileStore.sol";
import {
    IERC721Enumerable
} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {
    IERC721Metadata
} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC5313} from "@openzeppelin/contracts/interfaces/IERC5313.sol";
import {IERC7572} from "../src/IERC7572.sol";

contract ContractAndSculptureTest is Test {
    address public constant FILE_STORE =
        0xFe1411d6864592549AdE050215482e4385dFa0FB;

    Byte public byteContract;
    Form public formContract;
    ByteformRenderer public renderer;
    Byteform public byteform;
    address public deployer;

    /// @notice Deploy mock FileStore to the expected address using vm.etch
    function _deployMockFileStore() internal {
        MockFileStore mockFileStore = new MockFileStore();
        vm.etch(FILE_STORE, address(mockFileStore).code);
    }

    function setUp() public {
        deployer = address(this);
        _deployMockFileStore();

        // Deploy Byte and Form contracts
        byteContract = new Byte();
        formContract = new Form();

        // Deploy ByteformRenderer (uses mock FileStore)
        renderer = new ByteformRenderer(FILE_STORE);

        // Deploy Byteform that connects everything
        byteform = new Byteform(
            deployer,
            address(byteContract),
            address(formContract),
            address(renderer)
        );

        // Set up some test data - "Byteform" in hex: 42 79 74 65 66 6f 72 6d
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
            address wallet = address(uint160(i + 1));

            vm.prank(wallet);
            // forge-lint: disable-next-line(unsafe-typecast)
            byteContract.c(uint8(i));

            vm.prank(wallet);
            formContract.s(formValues[i]);
        }

        // Claim remaining bytes with null address
        for (uint256 i = 8; i < 256; i++) {
            vm.prank(address(0));
            // forge-lint: disable-next-line(unsafe-typecast)
            byteContract.c(uint8(i));
        }
    }

    function testContractURI() public {
        string memory uri = byteform.contractURI();

        // Verify not empty
        bytes memory uriBytes = bytes(uri);
        assertGt(uriBytes.length, 0, "contractURI should not be empty");

        // Verify starts with data:application/json;base64,
        string memory prefix = "data:application/json;base64,";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            uriBytes.length,
            prefixBytes.length,
            "contractURI should be long enough"
        );

        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                uriBytes[i],
                prefixBytes[i],
                "contractURI should start with data:application/json;base64,"
            );
        }

        // Write to file
        vm.writeFile("generated/contract-uri.txt", uri);
    }

    function testIndex() public {
        string memory indexHtml = byteform.index();

        // Verify not empty
        bytes memory htmlBytes = bytes(indexHtml);
        assertGt(htmlBytes.length, 0, "index should not be empty");

        // Verify starts with <!DOCTYPE html>
        string memory prefix = "<!DOCTYPE html>";
        bytes memory prefixBytes = bytes(prefix);
        assertGe(
            htmlBytes.length,
            prefixBytes.length,
            "index should be long enough"
        );

        for (uint256 i = 0; i < prefixBytes.length; i++) {
            assertEq(
                htmlBytes[i],
                prefixBytes[i],
                "index should start with <!DOCTYPE html>"
            );
        }

        // Write to file
        vm.writeFile("generated/index.txt", indexHtml);
    }

    function testTitle() public {
        string memory titleStr = byteform.title();

        // Verify title is "Byteform"
        assertEq(titleStr, "Byteform", "title should be 'Byteform'");

        // Write to file
        vm.writeFile("generated/title.txt", titleStr);
    }

    function testText() public {
        string memory textStr = byteform.text();

        // Verify not empty (should contain "Byteform" based on setup)
        bytes memory textBytes = bytes(textStr);
        assertGt(textBytes.length, 0, "text should not be empty");

        // Verify text is "Byteform" (from our setup)
        assertEq(
            textStr,
            "Byteform",
            "text should be 'Byteform' based on setup"
        );

        // Write to file
        vm.writeFile("generated/text.txt", textStr);
    }

    function testUrls() public {
        string[] memory urlsArr = byteform.urls();

        // Based on ByteformRenderer.getUrls(), it returns empty array
        assertEq(urlsArr.length, 0, "urls should be empty array");

        // Write to file - format as JSON array
        string memory urlsStr = "[";
        for (uint256 i = 0; i < urlsArr.length; i++) {
            if (i > 0) {
                urlsStr = string(abi.encodePacked(urlsStr, ","));
            }
            urlsStr = string(abi.encodePacked(urlsStr, '"', urlsArr[i], '"'));
        }
        urlsStr = string(abi.encodePacked(urlsStr, "]"));

        vm.writeFile("generated/urls.txt", urlsStr);
    }

    function testAddresses() public {
        address[] memory addressesArr = byteform.addresses();

        // Verify array has 3 elements: byteContract, formContract, renderer
        assertEq(addressesArr.length, 3, "addresses should have 3 elements");
        assertEq(
            addressesArr[0],
            address(byteContract),
            "addresses[0] should be byteContract"
        );
        assertEq(
            addressesArr[1],
            address(formContract),
            "addresses[1] should be formContract"
        );
        assertEq(
            addressesArr[2],
            address(renderer),
            "addresses[2] should be renderer"
        );

        // Write to file - format as JSON array with hex addresses
        string memory addressesStr = "[";
        for (uint256 i = 0; i < addressesArr.length; i++) {
            if (i > 0) {
                addressesStr = string(abi.encodePacked(addressesStr, ","));
            }
            addressesStr = string(
                abi.encodePacked(
                    addressesStr,
                    '"',
                    vm.toString(addressesArr[i]),
                    '"'
                )
            );
        }
        addressesStr = string(abi.encodePacked(addressesStr, "]"));

        vm.writeFile("generated/addresses.txt", addressesStr);
    }

    function testAuthors() public {
        string[] memory authorsArr = byteform.authors();

        // Verify array has 1 element: "tokenfox"
        assertEq(authorsArr.length, 1, "authors should have 1 element");
        assertEq(authorsArr[0], "tokenfox", "authors[0] should be 'tokenfox'");

        // Write to file - format as JSON array
        string memory authorsStr = "[";
        for (uint256 i = 0; i < authorsArr.length; i++) {
            if (i > 0) {
                authorsStr = string(abi.encodePacked(authorsStr, ","));
            }
            authorsStr = string(
                abi.encodePacked(authorsStr, '"', authorsArr[i], '"')
            );
        }
        authorsStr = string(abi.encodePacked(authorsStr, "]"));

        vm.writeFile("generated/authors.txt", authorsStr);
    }

    function testByteOwners() public {
        address[256] memory owners = byteform.byteOwners();

        // Verify first 8 bytes are owned by wallets 1-8
        for (uint256 i = 0; i < 8; i++) {
            address expectedOwner = address(uint160(i + 1));
            assertEq(
                owners[i],
                expectedOwner,
                "byteOwners should return correct owner for claimed bytes"
            );
        }

        // Verify remaining bytes (8-255) are owned by address(0) since we pranked as address(0)
        for (uint256 i = 8; i < 256; i++) {
            assertEq(
                owners[i],
                address(0),
                "byteOwners should return address(0) for bytes claimed by address(0)"
            );
        }
    }

    function testByteOwnersReturnsAll256() public view {
        address[256] memory owners = byteform.byteOwners();

        // Verify we get exactly 256 addresses (fixed array size guarantees this)
        // This test mainly ensures the function executes without reverting
        uint256 count = 0;
        for (uint256 i = 0; i < 256; i++) {
            // Count non-zero addresses
            if (owners[i] != address(0)) {
                count++;
            }
        }

        // Based on setUp, we should have 8 non-zero owners
        assertEq(count, 8, "should have 8 non-zero owners from setUp");
    }

    // ============ Byteform supportsInterface tests ============

    function testByteformSupportsERC721Interface() public view {
        assertTrue(byteform.supportsInterface(type(IERC721).interfaceId));
    }

    function testByteformSupportsERC721EnumerableInterface() public view {
        assertTrue(
            byteform.supportsInterface(type(IERC721Enumerable).interfaceId)
        );
    }

    function testByteformSupportsERC721MetadataInterface() public view {
        assertTrue(
            byteform.supportsInterface(type(IERC721Metadata).interfaceId)
        );
    }

    function testByteformSupportsOwnableInterface() public view {
        // Byteform implements Ownable and declares support for IERC5313
        assertTrue(byteform.supportsInterface(type(IERC5313).interfaceId));
    }

    function testByteformSupportsERC165Interface() public view {
        assertTrue(byteform.supportsInterface(type(IERC165).interfaceId));
    }

    function testByteformDoesNotSupportRandomInterface() public view {
        assertFalse(byteform.supportsInterface(0xdeadbeef));
    }

    function testByteformSupportsERC7572Interface() public view {
        // ERC-7572: Contract-level metadata (contractURI)
        assertTrue(byteform.supportsInterface(type(IERC7572).interfaceId));
    }

    function testByteformSupportsERC4906Interface() public view {
        // ERC-4906: Metadata Update Extension (0x49064906)
        assertTrue(byteform.supportsInterface(bytes4(0x49064906)));
    }
}
