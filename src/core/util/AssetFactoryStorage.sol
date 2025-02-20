//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.23;

import {AssetFactoryConst} from "./AssetFactoryConst.sol";
import {IAssetFactory_read} from "./IAssetFactory_read.sol";
import {Asset_Structs} from "./AssetInstanceStructs.sol";

contract AssetFactoryStorage is IAssetFactory_read, AssetFactoryConst {
    // -----------------------------
    //    Immutable State Variables
    // -----------------------------

    /// @dev The address of Bananashares Token contract.
    address internal immutable bananasharesTokenAddr;

    /// @dev The protocol deployment date.
    uint256 internal immutable protocolDeploymentDate;

    // ---------------------
    //    Constants
    // ---------------------

    // Read from AssetFactoryConst

    // ---------------------
    //    State Variables
    // ---------------------

    /**
     * @dev Associates each AssetInstancesHashes address with the hash of a tokenized asset.
     */
    mapping(address => bytes32) internal AssetInstancesHashes;
    /**
     * @dev Associates each tokenized asset hash with its corresponding BBSInstance address.
     */
    mapping(bytes32 => address) internal AssetInstancesByHash;
    /**
     * @dev Number of AssetInstances.
     */
    uint256 internal numberOfAssetInstances;
    /**
     * @dev Spefifies AssetInstance implementation address.
     */
    address internal AssetInstanceImplementation;
    /**
     * @dev Specifies the protocol commissions and the minimum value of the sell offer in the AssetInstance contract.
     */
    Asset_Structs.GlobalSettings internal globalSettings;

    // -----------------
    //    Read Functions
    // -----------------

    /**
     * @notice Returns the address of AssetInstance contract for specific hash.
     */
    function getAssetInstanceByHash(
        bytes32 _hash
    ) external view returns (address) {
        return AssetInstancesByHash[_hash];
    }

    /**
     * @notice Returns the hash of AssetInstance contract for specific address.
     */
    function getAssetInstanceHashByAddress(
        address _address
    ) external view returns (bytes32) {
        return AssetInstancesHashes[_address];
    }

    /**
     * @notice Returns the number of AssetInstances.
     */
    function getAssetInstanceNumber() external view returns (uint256) {
        return numberOfAssetInstances;
    }

    /**
     * @notice Returns the implementation address of AssetInstances.
     */
    function getAssetInstanceImplementation() external view returns (address) {
        return AssetInstanceImplementation;
    }

    /**
     * @notice Returns the `globalSettings`.
     */
    function getGlobalSettings()
        external
        view
        returns (Asset_Structs.GlobalSettings memory)
    {
        return globalSettings;
    }
}
