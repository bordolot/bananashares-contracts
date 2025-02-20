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
     */
    event AssetInstanceCreated(
        address indexed AssetInstanceCreator,
        address indexed AssetInstanceAddress
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
