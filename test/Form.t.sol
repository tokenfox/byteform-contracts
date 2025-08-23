// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Form} from "../src/Form.sol";

contract FormTest is Test {
    Form public form;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    function setUp() public {
        form = new Form();
    }

    function testDefaultValueReturnsKeccak256() public {
        uint8 expected = uint8(uint256(keccak256(abi.encodePacked(alice))));
        assertEq(form.g(alice), expected);
    }

    function testSetValueNonZero() public {
        vm.prank(alice);
        form.s(42);

        assertEq(form.g(alice), 42);
        assertEq(form.v(alice), 42);
    }

    function testSetValueZero() public {
        vm.prank(alice);
        form.s(0);

        uint8 expected = uint8(uint256(keccak256(abi.encodePacked(alice))));
        assertEq(form.g(alice), expected);
    }

    function testSetValueAndChange() public {
        vm.prank(alice);
        form.s(100);
        assertEq(form.g(alice), 100);

        vm.prank(alice);
        form.s(200);
        assertEq(form.g(alice), 200);
    }

    function testSetValueToZeroAfterNonZero() public {
        vm.prank(alice);
        form.s(50);
        assertEq(form.g(alice), 50);

        vm.prank(alice);
        form.s(0);
        uint8 expected = uint8(uint256(keccak256(abi.encodePacked(alice))));
        assertEq(form.g(alice), expected);
    }

    function testMultipleAddresses() public {
        vm.prank(alice);
        form.s(10);

        vm.prank(bob);
        form.s(20);

        assertEq(form.g(alice), 10);
        assertEq(form.g(bob), 20);

        uint8 charlieExpected = uint8(uint256(keccak256(abi.encodePacked(charlie))));
        assertEq(form.g(charlie), charlieExpected);
    }

    function testSetMaxValue() public {
        vm.prank(alice);
        form.s(255);

        assertEq(form.g(alice), 255);
    }

    function testSetMinValue() public {
        vm.prank(alice);
        form.s(1);

        assertEq(form.g(alice), 1);
    }

    function testDifferentAddressesReturnDifferentKeccak256() public {
        uint8 aliceHash = form.g(alice);
        uint8 bobHash = form.g(bob);
        uint8 charlieHash = form.g(charlie);

        // Very unlikely all three would be the same
        assertTrue(aliceHash != bobHash || bobHash != charlieHash || aliceHash != charlieHash);
    }
}

