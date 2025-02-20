//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.23;

import {AssetConst} from "./AssetConst.sol";

contract AssetFactoryConst is AssetConst {
    // ---------------------
    //    Constants
    // ---------------------

    /// @dev The divisors that decrease the number of shares sold/bought in an `AssetInstance` to determine the number of `BananasharesToken` to mint.
    /// @dev The divisor applicable in the `EARLY_PERIOD` after protocol deployment.
    uint256 constant FIRST_DIVISOR = 100;
    /// @dev The divisor applicable after the `EARLY_PERIOD` of protocol deployment.
    uint256 constant SECOND_DIVISOR = 1000;
    /// @dev The period after protocol deployment during which the `AssetFactory` uses `SECOND_DIVISOR` instead of `FIRST_DIVISOR` to calculate the number of Bananashares Tokens to mint.
    /// 43200 - one day on the Optimism
    uint256 constant EARLY_PERIOD = 43_200 * 365;
}
