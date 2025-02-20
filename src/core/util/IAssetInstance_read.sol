//SPDX-License-Identifier:BUSL-1.1

pragma solidity 0.8.23;

import {Asset_Structs} from "./AssetInstanceStructs.sol";

interface IAssetInstance_read {
    // -----------------
    //    Read Functions
    // -----------------

    function getAssetsFactoryAddr() external view returns (address);

    function getNameOfAsset() external view returns (string memory);

    function getAssetHash() external view returns (bytes32);

    function getAuthorsLength() external view returns (uint256);

    function getAuthor(
        uint256 _index
    ) external view returns (Asset_Structs.Author memory);

    function getAllAuthors()
        external
        view
        returns (Asset_Structs.Author[] memory);

    function getShares(address _addr) external view returns (uint24);

    function getSharesInPrivilegedHands() external view returns (uint24);

    function getPrivilegedShareholdersLength()
        external
        view
        returns (uint256 length);

    function getAllPrivShareholders() external view returns (address[] memory);

    function getPrivilegedShareholdersIndex(
        address _addr
    ) external view returns (uint24);

    function getPrivilegedShareholder(
        uint256 _index
    ) external view returns (address addr, uint24 share);

    function getOffersLength() external view returns (uint256);

    function getOffersIndex(address _addr) external view returns (uint24);

    function getOffer(
        uint256 _index
    ) external view returns (Asset_Structs.Offer memory offer);

    function getLicensesLength() external view returns (uint256);

    function getLicensesIndex(bytes32 _hash) external view returns (uint256);

    function getLicense(
        uint256 _index
    ) external view returns (Asset_Structs.License memory);

    function getPaymentsLength() external view returns (uint256);

    function getPaymentIndex(uint48 _timestamp) external view returns (uint256);

    function getLastDayOfDividendPayment(
        address _addr
    ) external view returns (uint48);

    function getPayment(
        uint256 _index
    ) external view returns (Asset_Structs.Payment memory);

    function getDividendToPay(
        address _addr
    ) external view returns (uint256 value, uint256 howMany);

    function getAggregatedPrivilegedFees() external view returns (uint256);

    function getPrivilegedFees(
        address _addr
    ) external view returns (uint256 fees);

    function getBalance(address _add) external view returns (uint256);

    function getLastBlockGovTokenMinted(
        address _addr
    ) external view returns (uint48);

    function getGovTokensMinted() external view returns (uint256);
}
