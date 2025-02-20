// SPDX-License-Identifier: BULS-1.1

pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";

contract Actors is Test {
    address addrAdmin = makeAddr("Admin");
    address addrTimelockController = makeAddr("TimelockController");
    address addrUser_1 = makeAddr("User_1");

    address addressMike = makeAddr("Mike");
    address addressBilbo = makeAddr("Bilbo");

    address addressPrivileged_1 = makeAddr("Privileged_1");
    address addressPrivileged_2 = makeAddr("Privileged_2");
    address addressPrivileged_3 = makeAddr("Privileged_3");
    address addressPrivileged_4 = makeAddr("Privileged_4");
    address addressPrivileged_5 = makeAddr("Privileged_5");
    address addressPrivileged_6 = makeAddr("Privileged_6");
    address addressPrivileged_7 = makeAddr("Privileged_7");
    address addressPrivileged_8 = makeAddr("Privileged_8");
    address addressPrivileged_9 = makeAddr("Privileged_9");
    address addressPrivileged_10 = makeAddr("Privileged_10");
    address[] testPrivilegedAddresses = [
        addressPrivileged_1,
        addressPrivileged_2,
        addressPrivileged_3,
        addressPrivileged_4,
        addressPrivileged_5,
        addressPrivileged_6,
        addressPrivileged_7,
        addressPrivileged_8,
        addressPrivileged_9,
        addressPrivileged_10
    ];
    string[] testPrivilegedNames = [
        "Privileged_1",
        "Privileged_2",
        "Privileged_3",
        "Privileged_4",
        "Privileged_5",
        "Privileged_6",
        "Privileged_7",
        "Privileged_8",
        "Privileged_9",
        "Privileged_10"
    ];

    address InvestorMark = makeAddr("Mark");
    address InvestorBob = makeAddr("Bob");
    address InvestorJanice = makeAddr("Janice");

    uint256 startWalletBalance = 20 ether;

    function _dealEtherToActors() internal {
        vm.deal(addrAdmin, startWalletBalance);
        vm.deal(addrUser_1, startWalletBalance);

        vm.deal(addressMike, startWalletBalance);
        vm.deal(addressBilbo, startWalletBalance);
        vm.deal(InvestorMark, startWalletBalance);
        vm.deal(InvestorBob, startWalletBalance);
        vm.deal(InvestorJanice, startWalletBalance);
    }
}
