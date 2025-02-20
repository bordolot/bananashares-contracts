// SPDX-License-Identifier: BULS-1.1

pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";

contract Actors is Test {
    address addrFounder = makeAddr("Founder");
    address addrUser_1 = makeAddr("User_1");
    address addrUser_2 = makeAddr("User_2");
    address addrUser_3 = makeAddr("User_3");
    address addrUser_4 = makeAddr("User_4");

    uint256 startWalletBalance = 20 ether;

    address multipleAssetInstancesCreator =
        makeAddr("multipleAssetInstancesCreator");

    function _dealEtherToActors() internal {
        vm.deal(addrFounder, startWalletBalance);
        vm.deal(addrUser_1, startWalletBalance);
        vm.deal(addrUser_2, startWalletBalance);
        vm.deal(addrUser_3, startWalletBalance);
        vm.deal(addrUser_4, startWalletBalance);
        vm.deal(multipleAssetInstancesCreator, startWalletBalance * 5);
    }
}
