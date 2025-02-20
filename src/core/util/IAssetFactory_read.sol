//SPDX-License-Identifier:BUSL-1.1

pragma solidity 0.8.23;

import {Asset_Structs} from "./AssetInstanceStructs.sol";

interface IAssetFactory_read {
    // -----------------
    //    Read Functions
    // -----------------

    function getAssetInstanceByHash(
        bytes32 _hash
    ) external view returns (address);

    function getAssetInstanceHashByAddress(
        address _address
    ) external view returns (bytes32);

    function getAssetInstanceNumber() external view returns (uint256);

    function getAssetInstanceImplementation() external view returns (address);

    function getGlobalSettings()
        external
        view
        returns (Asset_Structs.GlobalSettings calldata);
}
