// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;
//@TODO change inport to "/forge-std/Script.sol";
import {Script, console2} from "../lib/forge-std/src/Script.sol";

import {BananasharesDeployCore} from "./BananasharesDeployCore.sol";

contract AssetsFactoryScript is Script, BananasharesDeployCore {
    address god = address(uint160(vm.envUint("DEV_ADDRESS")));
    uint devPrivateKey = vm.envUint("DEV_PRIVATE_KEY");

    function setUp() public {}

    function run() public {
        deployProtocol(god, devPrivateKey);
    }
}
