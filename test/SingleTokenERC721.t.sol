// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SingleTokenERC721} from "../src/SingleTokenERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC5313} from "@openzeppelin/contracts/interfaces/IERC5313.sol";
import {IERC7572} from "../src/IERC7572.sol";

// Concrete implementation for testing
contract TestSingleTokenERC721 is SingleTokenERC721 {
    constructor(address initialOwner) SingleTokenERC721("TestToken", "TEST") {
        _mint(initialOwner);
    }
}

contract SingleTokenERC721Test is Test {
    TestSingleTokenERC721 public token;
    address public owner = address(0x1);
    address public other = address(0x2);

    function setUp() public {
        token = new TestSingleTokenERC721(owner);
    }

    // ============ totalSupply tests ============

    function testTotalSupplyIsAlwaysOne() public view {
        assertEq(token.totalSupply(), 1);
    }

    function testTotalSupplyAfterTransfer() public {
        vm.prank(owner);
        token.transferFrom(owner, other, 0);
        assertEq(token.totalSupply(), 1);
    }

    // ============ tokenByIndex tests ============

    function testTokenByIndexZeroReturnsZero() public view {
        assertEq(token.tokenByIndex(0), 0);
    }

    function testTokenByIndexOneReverts() public {
        vm.expectRevert(abi.encodeWithSelector(SingleTokenERC721.ERC721OutOfBoundsIndex.selector, address(0), 1));
        token.tokenByIndex(1);
    }

    function testTokenByIndexLargeValueReverts() public {
        vm.expectRevert(abi.encodeWithSelector(SingleTokenERC721.ERC721OutOfBoundsIndex.selector, address(0), 999));
        token.tokenByIndex(999);
    }

    function testTokenByIndexMaxUint256Reverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(SingleTokenERC721.ERC721OutOfBoundsIndex.selector, address(0), type(uint256).max)
        );
        token.tokenByIndex(type(uint256).max);
    }

    // ============ tokenOfOwnerByIndex tests ============

    function testTokenOfOwnerByIndexReturnsZeroForOwner() public view {
        assertEq(token.tokenOfOwnerByIndex(owner, 0), 0);
    }

    function testTokenOfOwnerByIndexRevertsForNonOwner() public {
        vm.expectRevert(abi.encodeWithSelector(SingleTokenERC721.ERC721OutOfBoundsIndex.selector, other, 0));
        token.tokenOfOwnerByIndex(other, 0);
    }

    function testTokenOfOwnerByIndexRevertsForOwnerWithIndexOne() public {
        vm.expectRevert(abi.encodeWithSelector(SingleTokenERC721.ERC721OutOfBoundsIndex.selector, owner, 1));
        token.tokenOfOwnerByIndex(owner, 1);
    }

    function testTokenOfOwnerByIndexRevertsForNonOwnerWithIndexOne() public {
        vm.expectRevert(abi.encodeWithSelector(SingleTokenERC721.ERC721OutOfBoundsIndex.selector, other, 1));
        token.tokenOfOwnerByIndex(other, 1);
    }

    function testTokenOfOwnerByIndexAfterTransfer() public {
        vm.prank(owner);
        token.transferFrom(owner, other, 0);

        // New owner should be able to get token at index 0
        assertEq(token.tokenOfOwnerByIndex(other, 0), 0);

        // Old owner should revert
        vm.expectRevert(abi.encodeWithSelector(SingleTokenERC721.ERC721OutOfBoundsIndex.selector, owner, 0));
        token.tokenOfOwnerByIndex(owner, 0);
    }

    function testTokenOfOwnerByIndexRevertsForZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(SingleTokenERC721.ERC721OutOfBoundsIndex.selector, address(0), 0));
        token.tokenOfOwnerByIndex(address(0), 0);
    }

    // ============ supportsInterface tests ============

    function testSupportsERC721EnumerableInterface() public view {
        assertTrue(token.supportsInterface(type(IERC721Enumerable).interfaceId));
    }

    function testSupportsERC721Interface() public view {
        assertTrue(token.supportsInterface(type(IERC721).interfaceId));
    }

    function testSupportsERC721MetadataInterface() public view {
        // ERC721 from OpenZeppelin implements IERC721Metadata
        assertTrue(token.supportsInterface(type(IERC721Metadata).interfaceId));
    }

    function testSupportsERC165Interface() public view {
        assertTrue(token.supportsInterface(type(IERC165).interfaceId));
    }

    function testDoesNotSupportOwnableInterface() public view {
        // SingleTokenERC721 does not implement Ownable (IERC5313)
        assertFalse(token.supportsInterface(type(IERC5313).interfaceId));
    }

    function testDoesNotSupportRandomInterface() public view {
        assertFalse(token.supportsInterface(0xdeadbeef));
    }

    function testDoesNotSupportERC7572Interface() public view {
        // SingleTokenERC721 does not implement ERC-7572 (contractURI)
        assertFalse(token.supportsInterface(type(IERC7572).interfaceId));
    }

    function testDoesNotSupportERC4906Interface() public view {
        // SingleTokenERC721 does not implement ERC-4906 (MetadataUpdate)
        assertFalse(token.supportsInterface(bytes4(0x49064906)));
    }

    // ============ Integration tests ============

    function testEnumerateAllTokens() public view {
        // With totalSupply() we know there's 1 token
        uint256 supply = token.totalSupply();
        assertEq(supply, 1);

        // We can enumerate it with tokenByIndex
        uint256 tokenId = token.tokenByIndex(0);
        assertEq(tokenId, 0);

        // And get its owner
        address tokenOwner = token.ownerOf(tokenId);
        assertEq(tokenOwner, owner);
    }

    function testEnumerateOwnerTokens() public view {
        // Owner has balance of 1
        uint256 balance = token.balanceOf(owner);
        assertEq(balance, 1);

        // We can enumerate their token
        uint256 tokenId = token.tokenOfOwnerByIndex(owner, 0);
        assertEq(tokenId, 0);
    }

    function testEnumerateAfterMultipleTransfers() public {
        // Transfer to other
        vm.prank(owner);
        token.transferFrom(owner, other, 0);

        // Verify enumeration for new owner
        assertEq(token.balanceOf(other), 1);
        assertEq(token.tokenOfOwnerByIndex(other, 0), 0);

        // Transfer back
        vm.prank(other);
        token.transferFrom(other, owner, 0);

        // Verify enumeration for original owner
        assertEq(token.balanceOf(owner), 1);
        assertEq(token.tokenOfOwnerByIndex(owner, 0), 0);
    }
}

