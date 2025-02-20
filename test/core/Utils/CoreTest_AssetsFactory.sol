//SPDX-License-Identifier: NONE
pragma solidity 0.8.23;

// import {AssetsFactory, AssetCore, Asset} from "../../src/AssetsFactory.sol";
import {Test, console} from "forge-std/Test.sol";
import {Globals} from "./Globals.sol";
import {Actors} from "./Actors.sol";
import {CreateAssetInstance} from "./CreateAssetInstance.sol";

import {IAssetFactory} from "../../../src/core/util/IAssetFactory.sol";
import {AssetFactoryProxy} from "../../../src/core/AssetFactoryProxy.sol";
import {AssetFactory} from "../../../src/core/AssetFactory.sol";
import {AssetInstance} from "../../../src/core/AssetInstance.sol";

import {BananasharesToken} from "../../../src/governance/BananasharesToken.sol";

/// @title Creates AssetsFactory and specified number of Asset contracts
/// @notice Values that can be modified before testing: FIRST_SHAREHOLDER_MAX_SHARES
contract CoreTest_AssetsFactory is Test, Globals, Actors, CreateAssetInstance {
    AssetFactory internal factoryImplementation;
    AssetInstance internal assetImplementation;
    IAssetFactory internal assetFactory;

    BananasharesToken internal bananasharesToken;

    function _createAssetFactory() internal {
        vm.roll(1);
        vm.startPrank(addressMike);

        bananasharesToken = new BananasharesToken(TOKENS_FOR_FOUNDER);
        factoryImplementation = new AssetFactory(
            address(bananasharesToken),
            block.number
        );

        bytes memory _calldata = abi.encodeWithSelector(
            AssetFactory.initialize.selector,
            addressMike
        );

        assetFactory = IAssetFactory(
            address(
                new AssetFactoryProxy(
                    address(factoryImplementation),
                    _calldata,
                    COMMITSION_FOR_PRIVILEGED,
                    COMMITSION_FOR_OWNER,
                    MIN_SELL_OFFER
                )
            )
        );
        assetImplementation = new AssetInstance(address(assetFactory));
        IAssetFactory(address(assetFactory)).setAssetInstanceImplementation(
            address(assetImplementation)
        );

        // In `bananasharesToken` grant the `MINT_ROLE` to the `assetFactory` contract.
        bananasharesToken.grantRole(
            keccak256("MINT_ROLE"),
            address(assetFactory)
        );

        vm.stopPrank();
    }

    function _createTestAssets(uint256 _seed, uint8 _numberOfAssets) internal {
        if (address(assetFactory) == address(0)) {
            revert("No AssetFactoryProxy implemented");
        }
        _createTestAssets(address(assetFactory), _seed, _numberOfAssets);
    }
}
