// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Byte} from "../src/Byte.sol";

contract ByteTest is Test {
    Byte public byteContract;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    function setUp() public {
        byteContract = new Byte();
    }

    function testClaim() public {
        vm.prank(alice);
        byteContract.c(0x01);

        assertEq(byteContract.o(0x01), alice);
    }

    function testClaimMultiple() public {
        vm.startPrank(alice);
        byteContract.c(0x01);
        byteContract.c(0x02);
        byteContract.c(0xff);
        vm.stopPrank();

        assertEq(byteContract.o(0x01), alice);
        assertEq(byteContract.o(0x02), alice);
        assertEq(byteContract.o(0xff), alice);
    }

    function testClaimAlreadyClaimed() public {
        vm.prank(alice);
        byteContract.c(0x01);

        vm.prank(bob);
        vm.expectRevert();
        byteContract.c(0x01);
    }

    function testTransfer() public {
        vm.prank(alice);
        byteContract.c(0x01);

        vm.prank(alice);
        byteContract.t(0x01, bob);

        assertEq(byteContract.o(0x01), bob);
    }

    function testTransferNotOwner() public {
        vm.prank(alice);
        byteContract.c(0x01);

        vm.prank(bob);
        vm.expectRevert();
        byteContract.t(0x01, charlie);
    }

    function testTransferToZeroAddress() public {
        vm.prank(alice);
        byteContract.c(0x01);

        vm.prank(alice);
        byteContract.t(0x01, address(0));

        assertEq(byteContract.o(0x01), address(0));
    }

    function testTransferMultiple() public {
        vm.startPrank(alice);
        byteContract.c(0x01);
        byteContract.c(0x02);
        byteContract.c(0x03);
        vm.stopPrank();

        vm.startPrank(alice);
        byteContract.t(0x01, bob);
        byteContract.t(0x02, charlie);
        vm.stopPrank();

        assertEq(byteContract.o(0x01), bob);
        assertEq(byteContract.o(0x02), charlie);
        assertEq(byteContract.o(0x03), alice);
    }

    function testClaimAllBytes() public {
        vm.startPrank(alice);
        for (uint256 i = 0; i < 256; i++) {
            // casting to 'uint8' is safe because i is in range 0-255
            // forge-lint: disable-next-line(unsafe-typecast)
            byteContract.c(uint8(i));
        }
        vm.stopPrank();

        for (uint256 i = 0; i < 256; i++) {
            // casting to 'uint8' is safe because i is in range 0-255
            // forge-lint: disable-next-line(unsafe-typecast)
            assertEq(byteContract.o(uint8(i)), alice);
        }
    }

    function testTransferBackToSelf() public {
        vm.prank(alice);
        byteContract.c(0x01);

        vm.prank(alice);
        byteContract.t(0x01, alice);

        assertEq(byteContract.o(0x01), alice);
    }

    function testClaimZeroByte() public {
        vm.prank(alice);
        byteContract.c(0x00);

        assertEq(byteContract.o(0x00), alice);
    }

    function testClaimMaxByte() public {
        vm.prank(alice);
        byteContract.c(0xff);

        assertEq(byteContract.o(0xff), alice);
    }

    function testTransferToSelf() public {
        vm.prank(alice);
        byteContract.c(0x01);

        vm.prank(alice);
        byteContract.t(0x01, alice);

        assertEq(byteContract.o(0x01), alice);
    }
}
