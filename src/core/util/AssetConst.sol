//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.23;

contract AssetConst {
    // ---------------------------------------------------------------------
    //    Constants common for `AssetInstanceProxy` and `AssetFactoryProxy`
    // ---------------------------------------------------------------------
    /// @dev The total number of shares redistributed between all shareholders in `AssetInstanceProxy`.
    uint24 constant TOTAL_SUPPLY = 1_000_000;
    /// @dev Decimals in `BananasharesToken`.
    uint256 constant GOV_TOKEN_DECIMALS = 10 ** 18;
}
