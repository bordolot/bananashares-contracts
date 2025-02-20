//SPDX-License-Identifier:BUSL-1.1

pragma solidity 0.8.23;

interface AssetFactoryErrors {
    // ---------------------
    //    Errors
    // ---------------------
    /**
     * @dev AssetInstance with this hash already exists.
     */
    error AssetInstanceAlreadyExists(bytes32 AssetInstanceHash);

    /**
     * @dev The `implementation` is invalid.
     */
    error InvalidImplementation(address implementation);

    /**
     * @dev A `sender` with no authorization attempted to call a function.
     */
    error UnauthorizedFunctionCall(address sender);

    /**
     * @dev Indicates an error related to the current `balance` of the AssetFactory contract.
     */
    error InsufficientBalance();

    /**
     * @dev The Ether receiver address does not exist..
     */
    error ZeroAddress();
}
