// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC5313} from "@openzeppelin/contracts/interfaces/IERC5313.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SingleTokenERC721} from "./SingleTokenERC721.sol";
import {ByteformRenderer} from "./ByteformRenderer.sol";
import {Sculpture} from "./Sculpture.sol";
import {Byte} from "./Byte.sol";
import {IERC7572} from "./IERC7572.sol";
import {IERC4906} from "./IERC4906.sol";

contract Byteform is SingleTokenERC721, Ownable, Sculpture, IERC7572, IERC4906 {
    address public byteContract;
    address public formContract;
    ByteformRenderer public renderer;
    bool public byteFrozen;
    bool public formFrozen;
    bool public rendererFrozen;

    error ByteFrozen();
    error FormFrozen();
    error RendererFrozen();

    modifier byteNotFrozen() {
        if (byteFrozen) {
            revert ByteFrozen();
        }
        _;
    }

    modifier formNotFrozen() {
        if (formFrozen) {
            revert FormFrozen();
        }
        _;
    }

    modifier rendererNotFrozen() {
        if (rendererFrozen) {
            revert RendererFrozen();
        }
        _;
    }

    constructor(address initialOwner, address byteContract_, address formContract_, address renderer_)
        SingleTokenERC721("Byteform", "BYTEFORM")
        Ownable(initialOwner)
    {
        byteContract = byteContract_;
        formContract = formContract_;
        renderer = ByteformRenderer(renderer_);
        _mint(initialOwner);
    }

    function setByte(address byteContract_) external onlyOwner byteNotFrozen {
        byteContract = byteContract_;
        emit MetadataUpdate(0);
    }

    function freezeByte() external onlyOwner byteNotFrozen {
        byteFrozen = true;
    }

    function setForm(address formContract_) external onlyOwner formNotFrozen {
        formContract = formContract_;
        emit MetadataUpdate(0);
    }

    function freezeForm() external onlyOwner formNotFrozen {
        formFrozen = true;
    }

    function setRenderer(address renderer_) external onlyOwner rendererNotFrozen {
        renderer = ByteformRenderer(renderer_);
        emit ContractURIUpdated();
        emit MetadataUpdate(0);
    }

    function freezeRenderer() external onlyOwner rendererNotFrozen {
        rendererFrozen = true;
    }

    function authors() external view returns (string[] memory) {
        return renderer.getAuthors();
    }

    function addresses() external view returns (address[] memory) {
        return renderer.getAddresses(byteContract, formContract);
    }

    function urls() external view returns (string[] memory) {
        return renderer.getUrls();
    }

    function text() external view returns (string memory) {
        return renderer.renderTokenText(byteContract, formContract);
    }

    function title() external pure returns (string memory) {
        return "Byteform";
    }

    function byteOwners() external view returns (address[256] memory owners) {
        Byte byte_ = Byte(byteContract);
        for (uint256 i = 0; i < 256; ++i) {
            owners[i] = byte_.o(uint8(i));
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override onlyTokenZero(tokenId) returns (string memory) {
        return renderer.renderTokenURI(byteContract, formContract);
    }

    function tokenImageURI(uint256 tokenId) public view onlyTokenZero(tokenId) returns (string memory) {
        return renderer.renderTokenImageURI(byteContract, formContract);
    }

    function tokenImage(uint256 tokenId) public view onlyTokenZero(tokenId) returns (string memory) {
        return renderer.renderTokenImage(byteContract, formContract);
    }

    function tokenHTML(uint256 tokenId) public view onlyTokenZero(tokenId) returns (string memory) {
        return renderer.renderTokenHTML(byteContract, formContract);
    }

    function index() public view returns (string memory) {
        return renderer.renderTokenHTML(byteContract, formContract);
    }

    function contractURI() public view returns (string memory) {
        return renderer.renderContractURI();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC5313).interfaceId || interfaceId == type(IERC7572).interfaceId
            || interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}
