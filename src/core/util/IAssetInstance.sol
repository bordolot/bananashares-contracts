//SPDX-License-Identifier:BUSL-1.1

pragma solidity 0.8.23;

import {Asset_Structs} from "./AssetInstanceStructs.sol";
import {IAssetInstance_write} from "./IAssetInstance_write.sol";
import {IAssetInstance_read} from "./IAssetInstance_read.sol";

interface IAssetInstance is IAssetInstance_write, IAssetInstance_read {}
