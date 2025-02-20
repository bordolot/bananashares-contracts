//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.23;

import {AssetConst} from "./AssetConst.sol";

contract AssetInstanceConst is AssetConst {
    // ---------------------
    //    Constants
    // ---------------------

    /// @dev A basis point (1/10,000 or 0.01%).
    uint24 constant BIPS = 10_000;
    /// @todo Decide if max value is necessary
    // uint96 constant MAX_SELL_OFFER = type(uint96).max;
    /// @dev The number of gas needed to finish the `payDividend` function.
    uint24 constant GAS_LIMIT = 65_000;
    /// @dev The number of gas needed to finish the `payEarndFeesToAllPrivileged` function.
    uint24 constant GAS_LIMIT_FEES = 35_000;
    /// @dev The max number of privileged shareholders.
    uint8 constant PRIV_SHAREDOLDERS_LIMIT = 10;
    /// @dev The max length of the title of the `nameOfAsset`.
    uint8 constant TITLE_LENGTH_LIMIT = 64;
    /// @dev The max length of the author name in the `Asset_Structs.Author`.
    uint8 constant AUTHOR_LENGTH_LIMIT = 32;
    /// @dev The period after minting BananasharesToken during which the `withdraw` function is blocked. This is necessary to prevent flash loan attacks and protocol centralization.
    /// 43200 - one day on the Optimism
    uint256 constant WITHDRAW_LOCK_PERIOD = 43_200 * 365;
}
