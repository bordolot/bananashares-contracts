//SPDX-License-Identifier:BUSL-1.1

pragma solidity 0.8.23;

import {IAssetFactory_read} from "./IAssetFactory_read.sol";
import {IAssetFactory_write} from "./IAssetFactory_write.sol";

interface IAssetFactory is IAssetFactory_read, IAssetFactory_write {}
