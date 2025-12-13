// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DynamicBufferLib} from "solady/utils/DynamicBufferLib.sol";
import {Byte} from "./Byte.sol";
import {Form} from "./Form.sol";
import {IFileStore} from "./IFileStore.sol";
import {console} from "forge-std/console.sol";

contract ByteformRenderer {
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    address public immutable FILE_STORE;

    constructor(address fileStore_) {
        FILE_STORE = fileStore_;
    }

    uint256 private constant MARGIN_SIZE = 16;
    uint256 private constant CELL_SIZE = 16;
    uint256 private constant FULL_SIZE = 256 + MARGIN_SIZE * 2;

    string private constant NL = "\\n";
    string private constant SVG_OPEN =
        '<svg viewBox="0 0 288 288" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">';
    string private constant SVG_CLOSE = "</svg>";

    function getAuthors() external pure returns (string[] memory) {
        string[] memory result = new string[](1);
        result[0] = "tokenfox";
        return result;
    }

    function getUrls() external pure returns (string[] memory) {
        return new string[](0);
    }

    function getAddresses(
        address byteContract,
        address formContract
    ) external view returns (address[] memory) {
        address[] memory result = new address[](3);
        result[0] = byteContract;
        result[1] = formContract;
        result[2] = address(this);
        return result;
    }

    function renderContractURI() external pure returns (string memory) {
        string memory json = '{"name":"Byteform"}';
        string memory base64Json = Base64.encode(bytes(json));
        return string.concat("data:application/json;base64,", base64Json);
    }

    function renderTokenURI(
        address byteContract,
        address formContract
    ) external view returns (string memory) {
        string memory json = _generateMetadata(byteContract, formContract);
        string memory base64Json = Base64.encode(bytes(json));
        return string.concat("data:application/json;base64,", base64Json);
    }

    function renderTokenImageURI(
        address byteContract,
        address formContract
    ) external view returns (string memory) {
        string memory base64Image = Base64.encode(
            _generateImage(byteContract, formContract)
        );
        return string.concat("data:image/svg+xml;base64,", base64Image);
    }

    function renderTokenImage(
        address byteContract,
        address formContract
    ) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<?xml version="1.0" encoding="UTF-8"?>\n',
                    _generateImage(byteContract, formContract)
                )
            );
    }

    function renderTokenHTML(
        address byteContract,
        address formContract
    ) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Byteform</title>',
                    "<style>*{margin:0;padding:0;box-sizing:border-box}html,body{width:100%;height:100%;background:transparent}body{display:flex;align-items:center;justify-content:center;user-select:none}svg{max-width:100%;max-height:100%;width:auto;height:auto;cursor:pointer}</style></head><body>",
                    _generateImage(byteContract, formContract),
                    "<script>document.body.onclick=()=>{document.querySelector('.text').classList.toggle('hidden');document.querySelector('.traces').classList.toggle('hidden')}</script>",
                    "</body></html>"
                )
            );
    }

    function renderTokenText(
        address byteContract,
        address formContract
    ) external view returns (string memory) {
        uint8[256] memory forms = _fetchOwnersAndForms(
            Byte(byteContract),
            Form(formContract)
        );
        return _getText(forms);
    }

    function _generateMetadata(
        address byteContract,
        address formContract
    ) internal view returns (string memory) {
        return
            string.concat(
                '{"name":"Byteform","description":"',
                _generateDescription(byteContract, formContract),
                '","image":"data:image/svg+xml;base64,',
                Base64.encode(_generateImage(byteContract, formContract)),
                '"}'
            );
    }

    function _generateImage(
        address byteContract,
        address formContract
    ) internal view returns (bytes memory) {
        if (byteContract == address(0) || formContract == address(0)) {
            return abi.encodePacked(SVG_OPEN, _generateCanvas(), SVG_CLOSE);
        }

        uint8[256] memory forms = _fetchOwnersAndForms(
            Byte(byteContract),
            Form(formContract)
        );

        return
            abi.encodePacked(
                SVG_OPEN,
                "<!-- ",
                _getText(forms),
                " -->",
                "<style>.hidden{display:none}.ps{stroke:#333333;stroke-width:1.1;fill:none;stroke-linecap:round;stroke-linejoin:round}",
                '@font-face {font-family:IBMPlexMono;src:url("',
                _getFontURI(),
                '") format("woff2");}</style>',
                _generateCanvas(),
                _generateLines(),
                _generateTextOverlay(forms),
                _generateTraces(forms),
                SVG_CLOSE
            );
    }

    function _fetchOwnersAndForms(
        Byte byte_,
        Form form
    ) internal view returns (uint8[256] memory forms) {
        for (uint256 i = 0; i < 256; ++i) {
            address owner = byte_.o(uint8(i));
            if (owner != address(0)) {
                forms[i] = form.g(owner);
            }
        }
    }

    function _generateTraces(
        uint8[256] memory forms
    ) internal pure returns (bytes memory) {
        DynamicBufferLib.DynamicBuffer memory buffer;
        DynamicBufferLib.DynamicBuffer memory pathBuffer;

        buffer.p('<g class="traces">');
        uint256 currentRow = type(uint256).max;

        for (uint256 value = 0; value < 256; ++value) {
            uint8 byteForm = forms[value];

            if (byteForm == 0) {
                if (pathBuffer.length() > 0) {
                    buffer.p(pathBuffer.data, '" />');
                    pathBuffer.clear();
                }
                continue;
            }

            uint256 x = value % 16;
            uint256 y = value / 16;
            uint256 xPos = x * 16 + MARGIN_SIZE;
            uint256 yPos = y * 16 + MARGIN_SIZE;

            uint256 symbolValue = _calculateSymbolValue(byteForm);
            int256[5] memory points = _calculateControlPointsAndCutValue(
                symbolValue
            );
            int256 endX = points[4];

            if (endX < 2 || (endX > 5 && endX < 9) || endX > 13) {
                endX = 16;
            }

            if (pathBuffer.length() > 0 && y != currentRow) {
                buffer.p(pathBuffer.data, '" />');
                pathBuffer.clear();
            }

            if (pathBuffer.length() == 0) {
                pathBuffer.p(_renderFirstSegment(xPos, yPos, points, endX));
                currentRow = y;
            } else {
                pathBuffer.p(_renderContinuationSegment(points, endX));
            }

            if (endX < 16) {
                buffer.p(pathBuffer.data, '" />');
                pathBuffer.clear();
            }
        }

        if (pathBuffer.length() > 0) {
            buffer.p(pathBuffer.data, '" />');
        }

        buffer.p("</g>");
        return buffer.data;
    }

    function _generateTextOverlay(
        uint8[256] memory forms
    ) internal pure returns (string memory) {
        DynamicBufferLib.DynamicBuffer memory buffer;

        buffer.p(
            "<style>.m{width:256px;height:256px}",
            ".g{box-sizing:border-box;width:256px;height:256px;line-height:16px;",
            "display:grid;grid-template-columns:repeat(16,16px);grid-template-rows:repeat(16,16px)}",
            ".g p{margin:0;text-align:center;color:#000;font-family:IBMPlexMono,serif,monospace;font-weight:400;font-size:16px;line-height:16px;}</style>"
        );

        bytes memory offset = bytes(Strings.toString(MARGIN_SIZE));
        buffer.p(
            '<g class="text hidden"><foreignObject x="',
            offset,
            '" y="',
            offset
        );
        buffer.p(
            '" width="256" height="256"><div class="m" xmlns="http://www.w3.org/1999/xhtml"><div class="g">'
        );

        for (uint256 value = 0; value < 256; ++value) {
            uint8 byteForm = forms[value];
            if (_isPrintable(byteForm)) {
                buffer.p("<p>", _toHtmlEntity(byteForm), "</p>");
            } else {
                buffer.p("<p></p>");
            }
        }

        return buffer.p("</div></div></foreignObject></g>").s();
    }

    function _getFontURI() internal view returns (string memory) {
        return
            string.concat(
                "data:font/woff2;base64,",
                IFileStore(FILE_STORE).readFile("Byteform.woff2")
            );
    }

    function _getText(
        uint8[256] memory forms
    ) internal pure returns (string memory result) {
        for (uint256 value = 0; value < 256; ++value) {
            uint8 byteForm = forms[value];
            if (_isPrintable(byteForm)) {
                bytes memory char = new bytes(1);
                char[0] = bytes1(byteForm);
                result = string.concat(result, string(char));
            }
        }

        return result;
    }

    function _generateDescription(
        address byteContract,
        address formContract
    ) internal pure returns (string memory) {
        return
            string.concat(
                "BYTE",
                NL,
                Strings.toHexString(uint256(uint160(byteContract))),
                NL,
                NL,
                "FORM",
                NL,
                Strings.toHexString(uint256(uint160(formContract)))
            );
    }

    function _renderFirstSegment(
        uint256 xPos,
        uint256 yPos,
        int256[5] memory points,
        int256 endX
    ) internal pure returns (bytes memory) {
        string memory yMid = Strings.toString(yPos + 8);
        return
            abi.encodePacked(
                '<path class="ps" d="M',
                Strings.toString(xPos),
                ",",
                yMid,
                " C ",
                Strings.toStringSigned(int256(xPos) + points[0]),
                ",",
                Strings.toStringSigned(int256(yPos) + points[1]),
                " ",
                Strings.toStringSigned(int256(xPos) + points[2]),
                ",",
                Strings.toStringSigned(int256(yPos) + points[3]),
                " ",
                Strings.toStringSigned(int256(xPos) + endX),
                ",",
                yMid
            );
    }

    function _renderContinuationSegment(
        int256[5] memory points,
        int256 endX
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                " c ",
                Strings.toStringSigned(points[0]),
                ",",
                Strings.toStringSigned(points[1] - 8),
                " ",
                Strings.toStringSigned(points[2]),
                ",",
                Strings.toStringSigned(points[3] - 8),
                " ",
                Strings.toStringSigned(endX),
                ",0"
            );
    }

    function _calculateSymbolValue(
        uint8 byteForm
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(byteForm))) % 1048576;
    }

    function _isPrintable(uint8 byteForm) internal pure returns (bool) {
        return byteForm >= 32 && byteForm <= 126;
    }

    function _calculateControlPointsAndCutValue(
        uint256 symbolValue
    ) internal pure returns (int256[5] memory points) {
        points[0] = int256(symbolValue & 0xF);
        points[1] = int256((symbolValue >> 4) & 0xF);
        points[2] = int256((symbolValue >> 12) & 0xF);
        points[3] = int256((symbolValue >> 8) & 0xF);
        points[4] = int256((symbolValue >> 16) & 0xF);
    }

    function _toHtmlEntity(
        uint8 value
    ) internal pure returns (bytes memory result) {
        bytes memory hexChars = "0123456789ABCDEF";
        result = new bytes(6);
        result[0] = "&";
        result[1] = "#";
        result[2] = "x";
        result[3] = hexChars[value >> 4];
        result[4] = hexChars[value & 0xF];
        result[5] = ";";
    }

    function _generateCanvas() internal pure returns (string memory) {
        return
            string.concat(
                '<rect x="0" y="0" width="',
                Strings.toString(FULL_SIZE),
                '" height="',
                Strings.toString(FULL_SIZE),
                '" fill="#ffffff"/>'
            );
    }

    function _generateLines() internal pure returns (bytes memory) {
        DynamicBufferLib.DynamicBuffer memory buffer;

        bytes memory startPos = bytes(
            Strings.toString(MARGIN_SIZE - CELL_SIZE / 2)
        );
        bytes memory endPos = bytes(
            Strings.toString(256 + MARGIN_SIZE + CELL_SIZE / 2)
        );

        buffer.p(
            '<g class="lines hidden"><style>.tr{stroke:#e0e0e0;stroke-width:0.5}</style>'
        );

        for (uint256 i = 0; i < 16; ++i) {
            bytes memory pos = bytes(
                Strings.toString(i * 16 + MARGIN_SIZE + 8)
            );
            buffer.p('<line class="tr tr-v" x1="', pos, '" y1="', startPos);
            buffer.p('" x2="', pos, '" y2="', endPos);
            buffer.p('"/><line class="tr tr-h" x1="', startPos, '" y1="', pos);
            buffer.p('" x2="', endPos, '" y2="', pos, '"/>');
        }

        buffer.p("</g>");
        return buffer.data;
    }
}
