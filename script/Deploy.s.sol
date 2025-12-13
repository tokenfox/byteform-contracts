// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Byte} from "../src/Byte.sol";
import {Form} from "../src/Form.sol";
import {ByteformRenderer} from "../src/ByteformRenderer.sol";
import {Byteform} from "../src/Byteform.sol";

interface IByteform {
    function setByte(address byteContract_) external;
    function setForm(address formContract_) external;
    function setRenderer(address renderer_) external;
    function freezeByte() external;
    function freezeForm() external;
    function freezeRenderer() external;
}

contract DeployScript is Script {
    address public constant FILE_STORE =
        0xFe1411d6864592549AdE050215482e4385dFa0FB;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy ByteformRenderer
        ByteformRenderer renderer = new ByteformRenderer(FILE_STORE);

        // Deploy Byteform
        address deployer = vm.addr(deployerPrivateKey);
        Byteform byteform = new Byteform(
            deployer,
            address(0),
            address(0),
            address(renderer)
        );

        // Create byte
        Byte byteContract = new Byte();

        // Create form
        Form formContract = new Form();

        // Bind byte and form to byteform
        IByteform byteformInterface = IByteform(address(byteform));
        byteformInterface.setByte(address(byteContract));
        byteformInterface.setForm(address(formContract));

        /*
        // Optional: Upgrade renderer
        ByteformRenderer rendererV2 = new ByteformRenderer(FILE_STORE);
        byteformInterface.setRenderer(address(rendererV2));

        // Optional: freeze byte and form
        byteformInterface.freezeByte();
        byteformInterface.freezeForm();

        // Optional: freeze renderer
        byteformInterface.freezeRenderer();
        */

        vm.stopBroadcast();
    }
}
