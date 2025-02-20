//SPDX-License-Identifier: NONE
pragma solidity 0.8.23;

import {StdInvariant, console} from "forge-std/Test.sol";

import {CoreTest_AssetsFactory} from "./Utils/CoreTest_AssetsFactory.sol";
import {SH_Statefull} from "./Utils/HandlersS-Full.sol";

import {IAssetInstance} from "../../src/core/util/IAssetInstance.sol";

contract Test_FuzzinngStatefull is StdInvariant, CoreTest_AssetsFactory {
    address[] handlers;

    /// @dev before each test run in your console `export RANDOM_SEED=$(date +%s)`
    /// @dev or run each test with `--ffi` flag
    function setUp() public {
        // uint256 pcTimestamp = vm.envUint("RANDOM_SEED");
        vm.roll(1);
        uint256 pcTimestamp = _generateSeed();
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(pcTimestamp)));

        _createAssetFactory();
        _createTestAssets(randomSeed, NUMBER_OF_ASSETS_IN_TEST_CALL);
        _createHandlerForEachAsset(
            NUMBER_OF_ASSETS_IN_TEST_CALL,
            address(bananasharesToken)
        );

        /// @dev Adds handlers to the array of target contracts.
        for (uint8 i = 0; i < NUMBER_OF_ASSETS_IN_TEST_CALL; i++) {
            targetContract(handlers[i]);
        }
    }

    function _createHandlerForEachAsset(
        uint8 _numberOfAssets,
        address _govTokenAddr
    ) internal {
        SH_Statefull assetHandler_1;
        for (uint8 i = 0; i < _numberOfAssets; i++) {
            assetHandler_1 = new SH_Statefull(
                assetsAddresses[i],
                _govTokenAddr
            );
            handlers.push(address(assetHandler_1));
        }
    }

    // function invariant_empty() public pure returns (bool) {
    //     return (true);
    // }

    /// @notice Checks whether the number of offers in a IAssetInstance contract corresponds with the number of active offerors tracked by a handler.
    function invariant_NumberOfOffers() public view {
        IAssetInstance _tempAsset;
        for (uint i = 0; i < NUMBER_OF_ASSETS_IN_TEST_CALL; i++) {
            _tempAsset = IAssetInstance(assetsAddresses[i]);
            assertEq(
                _tempAsset.getOffersLength(),
                SH_Statefull(handlers[i]).getOffererAddressesLength()
            );
        }
    }

    /// @notice Checks whether the sum of number of shares held by privileged and normal sharholders keeps the value of TOTAL_SUPPLY .
    function invariant_NumberOfShares() public view {
        IAssetInstance _tempAsset;
        for (uint i = 0; i < NUMBER_OF_ASSETS_IN_TEST_CALL; i++) {
            _tempAsset = IAssetInstance(assetsAddresses[i]);

            assertEq(
                _tempAsset.getSharesInPrivilegedHands() +
                    SH_Statefull(handlers[i]).getSharesInNormalHands(),
                TOTAL_SUPPLY
            );
        }
    }

    /// @notice Checks whether the protocol collects its fees poperly
    function invariant_AssetsFactoryBalance() public view {
        uint256 _agragatedGain;
        for (uint i = 0; i < NUMBER_OF_ASSETS_IN_TEST_CALL; i++) {
            _agragatedGain += SH_Statefull(handlers[i]).getProtocolGain();
        }
        assertGe(address(assetFactory).balance, _agragatedGain);
    }

    /// @notice Checks whether a IAssetInstance contract is not losing ether by accident.
    function invariant_CheckEachAssetBalance() public view {
        for (uint i = 0; i < NUMBER_OF_ASSETS_IN_TEST_CALL; i++) {
            assertEq(
                SH_Statefull(handlers[i]).getAssetContractGain(),
                assetsAddresses[i].balance
            );
        }
    }
}
