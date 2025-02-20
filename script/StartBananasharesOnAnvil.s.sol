// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;
//@TODO change inport to "/forge-std/Script.sol";
import {Script, console2} from "../lib/forge-std/src/Script.sol";

import {BananasharesDeployCore} from "./BananasharesDeployCore.sol";

contract AssetsFactoryScript is Script, BananasharesDeployCore {
    struct TestAsset {
        string nameOfAsset;
        string[] authors;
        address[] shareholderAddress;
        uint24[] shares;
        bytes32 assetHash;
    }
    struct TestOffer {
        uint24 amount;
        uint96 value;
    }

    struct StandardBuyValues {
        uint24 amount;
        uint96 newSellLimit;
    }

    uint256 constant VALUE_SENT_TO_TEST_ACCOUNT = 10 ether;

    // address god = address(vm.envUint("DEV_ADDRESS"));
    // uint devPrivateKey = vm.envUint("DEV_PRIVATE_KEY");
    // uint testPrivateKey_mainSponsor = vm.envUint("TEST_PRIVATE_KEY");

    /// @dev values read from anvil
    address god = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    uint devPrivateKey =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    uint testPrivateKey_mainSponsor =
        0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    address PrivShareholderBilbo;
    uint256 privateKeyBilbo;
    address PrivShareholderVoldemort;
    uint256 privateKeyVoldemort;
    address PrivShareholderSauron;
    uint256 privateKeySauron;

    address InvestorMark;
    uint256 privateKeyMark;
    address InvestorBob;
    uint256 privateKeyBob;
    address InvestorJanice;
    uint256 privateKeyJanice;

    string[] authors = ["Mike Bolt", "Bilbo Baggins"];
    address[] addresses;
    uint24[] shares = [500_000, 500_000];

    uint24 testAmuontForSale = 100_000;
    uint96 testValuePerShare = 1e14;

    TestAsset testAsset;

    TestOffer testOffer =
        TestOffer({amount: testAmuontForSale, value: testValuePerShare});

    StandardBuyValues standardBuyValues =
        StandardBuyValues({amount: 10_000, newSellLimit: 2e14});

    address assetCoreAddr;
    address AssetsFactoryAddr;
    address testAssetAddr;

    function setUp() public {}

    function run() public {
        _createAccounts();

        deployProtocol(god, devPrivateKey);
    }

    function _createAccounts() private {
        (PrivShareholderBilbo, privateKeyBilbo) = makeAddrAndKey("Bilbo");
        vm.broadcast(testPrivateKey_mainSponsor);
        (bool ok, ) = PrivShareholderBilbo.call{
            value: VALUE_SENT_TO_TEST_ACCOUNT
        }("");
        assert(ok);
        console2.log("PrivShareholderBilbo address: ", PrivShareholderBilbo);
        console2.log(
            "PrivShareholderBilbo privateKey: ",
            uint256ToHex(privateKeyBilbo)
        );

        (PrivShareholderVoldemort, privateKeyVoldemort) = makeAddrAndKey(
            "Voldemort"
        );
        vm.broadcast(testPrivateKey_mainSponsor);
        (ok, ) = PrivShareholderVoldemort.call{
            value: VALUE_SENT_TO_TEST_ACCOUNT
        }("");
        assert(ok);
        console2.log(
            "PrivShareholderVoldemort address: ",
            PrivShareholderVoldemort
        );
        console2.log(
            "PrivShareholderVoldemort privateKey: ",
            uint256ToHex(privateKeyVoldemort)
        );

        (PrivShareholderSauron, privateKeySauron) = makeAddrAndKey("Sauron");
        vm.broadcast(testPrivateKey_mainSponsor);
        (ok, ) = PrivShareholderSauron.call{value: VALUE_SENT_TO_TEST_ACCOUNT}(
            ""
        );
        assert(ok);
        console2.log("PrivShareholderSauron address: ", PrivShareholderSauron);
        console2.log(
            "PrivShareholderSauron privateKey: ",
            uint256ToHex(privateKeySauron)
        );

        (InvestorMark, privateKeyMark) = makeAddrAndKey("Mark");
        vm.broadcast(testPrivateKey_mainSponsor);
        (ok, ) = InvestorMark.call{value: VALUE_SENT_TO_TEST_ACCOUNT}("");
        assert(ok);
        console2.log("InvestorMark address: ", InvestorMark);
        console2.log("InvestorMark privateKey: ", uint256ToHex(privateKeyMark));

        (InvestorBob, privateKeyBob) = makeAddrAndKey("Bob");
        vm.broadcast(testPrivateKey_mainSponsor);
        (ok, ) = InvestorBob.call{value: VALUE_SENT_TO_TEST_ACCOUNT}("");
        assert(ok);
        console2.log("InvestorBob address: ", InvestorBob);
        console2.log("InvestorBob privateKey: ", uint256ToHex(privateKeyBob));

        (InvestorJanice, privateKeyJanice) = makeAddrAndKey("Janice");
        vm.broadcast(testPrivateKey_mainSponsor);
        (ok, ) = InvestorJanice.call{value: VALUE_SENT_TO_TEST_ACCOUNT}("");
        assert(ok);
        console2.log("InvestorJanice address: ", InvestorJanice);
        console2.log(
            "InvestorJanice privateKey: ",
            uint256ToHex(privateKeyJanice)
        );
        console2.log("--------------------------------------------------");
    }

    function uint256ToHex(
        uint256 _value
    ) internal pure returns (string memory) {
        // Convert uint256 to bytes32
        bytes32 valueBytes = bytes32(_value);

        // Create a string to hold the hex representation
        bytes memory hexString = new bytes(64 + 2); // 64 for the hex digits + 2 for '0x'

        // Define hex characters
        bytes16 hexAlphabet = "0123456789abcdef";

        // Add '0x' prefix
        hexString[0] = "0";
        hexString[1] = "x";

        // Iterate over each byte in the bytes32
        for (uint i = 0; i < 32; i++) {
            // Extract each nibble (4 bits) from the byte
            bytes1 byteValue = valueBytes[i];
            hexString[i * 2 + 2] = hexAlphabet[uint8(byteValue >> 4) & 0x0f];
            hexString[i * 2 + 3] = hexAlphabet[uint8(byteValue) & 0x0f];
        }

        return string(hexString);
    }
}
