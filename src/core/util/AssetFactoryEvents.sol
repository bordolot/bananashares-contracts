//SPDX-License-Identifier:BUSL-1.1

pragma solidity 0.8.23;

interface AssetFactoryEvents {
    // ---------------------
    //    Events
    // ---------------------
    /**
     * @notice Emitted during createAsset().
     * @param  AssetInstanceCreator Address that sends createAsset transaction.
     * @param  AssetInstanceAddress Address of already created Asset Smart Contract.
     * @param  assetName The name of the asset.
     */
    event AssetInstanceCreated(
        address indexed AssetInstanceCreator,
        address indexed AssetInstanceAddress,
        string assetName
    );
    /**
     * @notice Emitted during createAsset().
     * @param  AssetInstanceCreator Address that sends createAsset transaction.
     * @param  reason The reason of the error.
     */
    event AssetInstanceCreationFailure(
        address indexed AssetInstanceCreator,
        string reason
    );
}
