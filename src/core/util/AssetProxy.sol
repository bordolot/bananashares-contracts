// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {IAssetFactory} from "./IAssetFactory.sol";

contract AssetProxy is Proxy {
    /**
     * @dev The address of the `AssetFactoryProxy`, which stores the implementation address for the `AssetInstanceProxy`.
     */
    address private immutable _beacon;
    /**
     * @dev The address of the beacon contract is invalid.
     */
    error InvalidBeacon(address beaconAddress);

    constructor(address _AssetFactoryProxyAddr) {
        if (_AssetFactoryProxyAddr.code.length == 0) {
            revert InvalidBeacon(_AssetFactoryProxyAddr);
        }
        _beacon = _AssetFactoryProxyAddr;
    }
    /**
     * @dev Returns the implementation for the `AssetInstanceProxy`.
     */
    function _implementation() internal view override returns (address) {
        return IAssetFactory(_beacon).getAssetInstanceImplementation();
    }
}
