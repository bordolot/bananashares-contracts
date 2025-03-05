// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.23;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {Script, console} from "../lib/forge-std/src/Script.sol";

import {BananasharesDeploySettings} from "./BananasharesDeploySettings.sol";

import {AssetFactory} from "../src/core/AssetFactory.sol";
import {AssetFactoryProxy} from "../src/core/AssetFactoryProxy.sol";
import {AssetInstance} from "../src/core/AssetInstance.sol";

import {IAssetFactory} from "../src/core/util/IAssetFactory.sol";

import {BananasharesToken} from "../src/governance/BananasharesToken.sol";
import {BananasharesGovTimelock} from "../src/governance/BananasharesGovTimelock.sol";
import {BananasharesGov} from "../src/governance/BananasharesGov.sol";

interface IOwnableUpgradeable {
    function transferOwnership(address newOwner) external;
}

contract BananasharesDeployCore is Script, BananasharesDeploySettings {
    function deployProtocol(
        address _deployerAddr,
        uint256 _deployerPrivateKey
    ) public {
        address[] memory _proposers;
        address[] memory _executors;

        BananasharesToken _bananasharesToken;
        BananasharesGovTimelock _bananasharesGovTimelock;
        BananasharesGov _bananasharesGov;

        AssetFactory _factoryImplementation;
        AssetFactoryProxy _assetFactory;
        AssetInstance _assetImplementation;

        /// the governance part
        vm.startBroadcast(_deployerPrivateKey);
        _bananasharesToken = new BananasharesToken(TOKENS_FOR_FOUNDER);

        _bananasharesGovTimelock = new BananasharesGovTimelock(
            TIMELOCK_MIN_DELAY,
            _proposers,
            _executors,
            _deployerAddr
        );

        _bananasharesGov = new BananasharesGov(
            _bananasharesToken,
            _bananasharesGovTimelock,
            VOTING_DELAY,
            PROPOSAL_THRESHOLD,
            VOTIG_PERIOD,
            QUORUM_FRACTION
        );

        _bananasharesGovTimelock.grantRole(
            _bananasharesGovTimelock.EXECUTOR_ROLE(),
            address(_bananasharesGov)
        );
        _bananasharesGovTimelock.grantRole(
            _bananasharesGovTimelock.PROPOSER_ROLE(),
            address(_bananasharesGov)
        );
        _bananasharesGovTimelock.grantRole(
            _bananasharesGovTimelock.CANCELLER_ROLE(),
            address(_bananasharesGov)
        );
        _bananasharesGovTimelock.revokeRole(
            _bananasharesGovTimelock.DEFAULT_ADMIN_ROLE(),
            _deployerAddr
        );

        // the core part

        _factoryImplementation = new AssetFactory(
            address(_bananasharesToken),
            block.number
        );

        _assetFactory = new AssetFactoryProxy(
            address(_factoryImplementation),
            abi.encodeWithSelector(
                AssetFactory.initialize.selector,
                _deployerAddr
            ),
            COMMITSION_FOR_PRIVILEGED,
            COMMITSION_FOR_OWNER,
            MIN_SELL_OFFER
        );

        _bananasharesToken.grantRole(
            keccak256("MINT_ROLE"),
            address(_assetFactory)
        );

        _assetImplementation = new AssetInstance(address(_assetFactory));
        IAssetFactory(address(_assetFactory)).setAssetInstanceImplementation(
            address(_assetImplementation)
        );
        IOwnableUpgradeable(address(_assetFactory)).transferOwnership(
            address(_bananasharesGovTimelock)
        );
        vm.stopBroadcast();
        console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        console.log("");
        console.log("block number:", block.number);
        console.log("BananasharesToken address: ", address(_bananasharesToken));
        console.log("BananasharesGov address: ", address(_bananasharesGov));
        console.log("AssetsFactory address: ", address(_assetFactory));
        console.log("");
        console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    }
}
