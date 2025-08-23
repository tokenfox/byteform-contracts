// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title SingleTokenERC721
 * @dev An ERC721 implementation optimized for collections with exactly one token (token ID 0).
 * Implements ERC721Enumerable interface with hardcoded values for single-token collections.
 */
abstract contract SingleTokenERC721 is ERC721, IERC721Enumerable {
    error ERC721OutOfBoundsIndex(address owner, uint256 index);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    modifier onlyTokenZero(uint256 tokenId) {
        if (tokenId != 0) {
            revert ERC721NonexistentToken(tokenId);
        }
        _;
    }

    function _mint(address to) internal {
        _mint(to, 0);
    }

    function totalSupply() public pure returns (uint256) {
        return 1;
    }

    function tokenOfOwnerByIndex(address owner, uint256 idx) public view returns (uint256) {
        if (idx != 0 || ownerOf(0) != owner) {
            revert ERC721OutOfBoundsIndex(owner, idx);
        }
        return 0;
    }

    function tokenByIndex(uint256 idx) public pure returns (uint256) {
        if (idx != 0) {
            revert ERC721OutOfBoundsIndex(address(0), idx);
        }
        return 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
}
