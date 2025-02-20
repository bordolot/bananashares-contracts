//SPDX-License-Identifier:BUSL-1.1

pragma solidity 0.8.23;

import {Asset_Structs} from "./AssetInstanceStructs.sol";

interface IAssetInstance_write {
    // -----------------
    //    Write Functions
    // -----------------

    function makeSellOffer(uint24 _amount, uint96 _price) external;

    function cancelOffer() external;

    function buyShares(
        address _from,
        uint24 _amount,
        uint96 _sellLimit
    ) external payable;

    function payEarndFeesToAllPrivileged() external;

    function withdraw(uint256 _amount) external;

    function changeOffer(uint96 _newLimit) external;

    function putNewLicense(bytes32 _licenseHash, uint224 _value) external;

    function activateLicense(bytes32 _licenseHash, bool _activate) external;

    function signLicense(bytes32 _licenseHash) external payable;

    function payDividend(address _addr) external;
}
