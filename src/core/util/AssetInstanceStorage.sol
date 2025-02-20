//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.23;

import {Asset_Structs} from "./AssetInstanceStructs.sol";
import {IAssetInstance_read} from "./IAssetInstance_read.sol";
import {AssetInstanceConst} from "./AssetInstanceConst.sol";

contract AssetInstanceStorage is AssetInstanceConst, IAssetInstance_read {
    using Asset_Structs for *;

    // ---------------------
    //    Constants
    // ---------------------

    // Read from `AssetInstanceConst`

    // -----------------------------
    //    Immutable State Variables
    // -----------------------------
    /// @dev The address of `AssetFactoryProxy` contract.
    address internal immutable assetFactoryAddr;

    // ---------------------
    //    State Variables
    // ---------------------

    /// @dev The title of the asset.
    string internal nameOfAsset;
    /// @dev The hash of the asset.
    bytes32 internal assetHash;
    /// @dev The list of names of privileged shareholders.
    Asset_Structs.Author[] internal authors;

    /// @dev Associates each shareholder's address with the number of shares they hold.
    mapping(address => uint24) internal shares;
    /// @dev  The total number of shares held by privileged shareholders, calculated as the total number of shares minus the number of shares held by regular shareholders.
    uint24 internal sharesInPrivilegedHands = 1_000_000;
    /// @dev Assigns each privileged shareholder's address an index under which it can be found in the `privilegedShareholders` array.
    mapping(address => uint24) internal privilegedShareholdersIndex;
    /// @dev The list of privileged shareholders' addresses.
    address[] internal privilegedShareholders;

    /// @dev Assigns an index to the address of each offer owner, under which that particular owner's offer can be found in the `offers` array.
    mapping(address => uint24) internal offersIndex;
    /// @dev The array that stores each `Asset_Structs.Offer` in the contract.
    Asset_Structs.Offer[] internal offers;

    /// @dev Assigns each license's hash an index under which it can be found in the list of licenses.
    mapping(bytes32 => uint256) internal licensesIndex;
    /// @dev The list of Licenses.
    Asset_Structs.License[] internal licenses;

    /// @dev Assigns each date when a payment was made an index under which the corresponding `Asset_Structs.Payment` can be found in the payments array. timestamp => index
    mapping(uint48 => uint256) internal paymentIndex;
    /// @dev Associates each shareholder's address with a Asset_Structs.Payment date. The next Asset_Structs.Payment after that date will be the Asset_Structs.Payment to which the shareholder will be entitled. address => timestamp
    mapping(address => uint48) internal lastDayOfDividendPayment;
    /// @dev The list of all Payments.
    Asset_Structs.Payment[] internal payments;

    /// @dev This variable represents the sum of all fees gathered, which are designated for distribution among privileged shareholders. Upon invoking the `payEarndFeesToAllPrivileged` function, the accumulated fees are distributed proportionally to all privileged shareholders, and the value of this variable is reset to zero.
    uint256 internal aggregatedPrivilegedFees;

    /// @dev Assigns each address that used this platform a value that represents colected income from any sources: sold shares, dividend from licenses, fees for Proivileged Shareholders. This value is ready to be withdrawn from this smart contract.
    mapping(address => uint256) internal balances;

    /// @dev Assigns each address a block number that records the moment when the address received Bananashares Tokens.
    mapping(address => uint48) internal lastBlockGovTokenMinted;

    /// @dev The number of Bananashares Tokens that the `AssetInstanceProxy` has already minted for its users.
    uint256 internal govTokensMinted;

    // -----------------
    //    Read Functions
    // -----------------

    /// @notice Returns the address of `AssetFactoryProxy` address.
    function getAssetsFactoryAddr() external view returns (address) {
        return assetFactoryAddr;
    }

    /// @notice Returns the value of `nameOfAsset`.
    function getNameOfAsset() external view returns (string memory) {
        return nameOfAsset;
    }

    /// @notice Returns the value of `assetHash`.
    function getAssetHash() external view returns (bytes32) {
        return assetHash;
    }

    /// @notice Returns the length of the `authors` array.
    function getAuthorsLength() external view returns (uint256) {
        return authors.length;
    }

    /// @notice Returns a specific `Asset_Structs.Author` from the `authors` array.
    /// @param _index The index of the author in the `authors` array.
    function getAuthor(
        uint256 _index
    ) external view returns (Asset_Structs.Author memory) {
        return authors[_index];
    }

    /// @notice Returns the `authors` array.
    function getAllAuthors()
        external
        view
        returns (Asset_Structs.Author[] memory)
    {
        return authors;
    }

    /// @notice Returns the number of shares for a specific account.
    /// @param _addr The address of the specific account.
    function getShares(address _addr) external view returns (uint24) {
        return shares[_addr];
    }

    /// @notice Returns the total number of shares held by all privileged shareholders.
    function getSharesInPrivilegedHands() external view returns (uint24) {
        return sharesInPrivilegedHands;
    }

    /// @notice Returns the length of `privilegedShareholders` array.
    function getPrivilegedShareholdersLength()
        external
        view
        returns (uint256 length)
    {
        length = (privilegedShareholders.length - 1);
    }

    /// @notice Returns the whole `privilegedShareholders` array.
    function getAllPrivShareholders() external view returns (address[] memory) {
        return privilegedShareholders;
    }

    /// @notice Returns the index that a specified address occupies in the `privilegedShareholdersIndex` mapping. An index of 0 means the address does not belong to a privileged shareholder.
    /// @param _addr The address to be checked.
    function getPrivilegedShareholdersIndex(
        address _addr
    ) external view returns (uint24) {
        return privilegedShareholdersIndex[_addr];
    }

    /// @notice Returns the address and number of shares of a specific privileged shareholder.
    /// @param _index The index of the privileged shareholder in the `privilegedShareholders` array.
    function getPrivilegedShareholder(
        uint256 _index
    ) external view returns (address addr, uint24 share) {
        addr = privilegedShareholders[_index];
        share = shares[addr];
    }

    /// @notice Returns the length of the `offers` array.
    function getOffersLength() external view returns (uint256) {
        return (offers.length - 1);
    }

    /// @notice Returns the index of an `Asset_Structs.Offer` in the `offers` array for a specific account.
    /// @param _addr The address of the specific account.
    function getOffersIndex(address _addr) external view returns (uint24) {
        return offersIndex[_addr];
    }

    /// @notice Returns a specific `Asset_Structs.Offer`.
    /// @param _index The index of the specific `Asset_Structs.Offer` in the `offers` array.
    function getOffer(
        uint256 _index
    ) external view returns (Asset_Structs.Offer memory offer) {
        offer = offers[_index];
    }

    /// @notice Returns the length of the `licenses` array.
    function getLicensesLength() external view returns (uint256) {
        return (licenses.length - 1);
    }

    /// @notice Returns the index of an `Asset_Structs.License` in the `licenses` array for a specific hash.
    /// @param _hash The hash of the specific license.
    function getLicensesIndex(bytes32 _hash) external view returns (uint256) {
        return licensesIndex[_hash];
    }

    /// @notice Returns a specific `Asset_Structs.License`.
    /// @param _index The index of the specific `Asset_Structs.License` in the `licenses` array.
    function getLicense(
        uint256 _index
    ) external view returns (Asset_Structs.License memory) {
        return licenses[_index];
    }

    /// @notice Returns the length of the `payments` array.
    function getPaymentsLength() external view returns (uint256) {
        return (payments.length - 1);
    }

    /// @notice Returns the index of an `Asset_Structs.Payment` in the `payments` array for a specific timestamp.
    /// @param _timestamp The timestamp of the specific `Asset_Structs.Payment`.
    function getPaymentIndex(
        uint48 _timestamp
    ) external view returns (uint256) {
        return paymentIndex[_timestamp];
    }

    /// @notice Returns the last timestamp when a specific account was paid a dividend.
    /// @param _addr The address of the specific account.
    function getLastDayOfDividendPayment(
        address _addr
    ) external view returns (uint48) {
        return lastDayOfDividendPayment[_addr];
    }

    /// @notice Returns a specific `Asset_Structs.Payment`.
    /// @param _index The index of the specific `Asset_Structs.Payment` in the `payments` array.
    function getPayment(
        uint256 _index
    ) external view returns (Asset_Structs.Payment memory) {
        return payments[_index];
    }

    /// @notice Returns the total amount of Ether that a specific account can move from each `Asset_Structs.Payment` in the `payments` array to their balance in the `balances` mapping. Also returns the number of `Asset_Structs.Payment` entries they have the right to access.
    /// @param _addr The address of the specific account.
    function getDividendToPay(
        address _addr
    ) external view returns (uint256 value, uint256 howMany) {
        uint24 _shares = shares[_addr];
        // require(_shares != 0, "Not a shareholder");
        uint48 _lastPayment = lastDayOfDividendPayment[_addr];
        uint256 _index = paymentIndex[_lastPayment];
        uint256 _length = payments.length;
        howMany = (_length - 1 - _index);

        // if (howMany == 0) {
        //     return (false, 0, 0);
        // }
        // isThereDividend = true;
        for (uint256 i = 1; i <= howMany; i++) {
            value += uint256(
                (payments[_length - i].paymentValue * _shares) / TOTAL_SUPPLY
            );
        }
    }

    /// @notice Returns the total amount of Ether collected by all privileged shareholders from fees.
    function getAggregatedPrivilegedFees() external view returns (uint256) {
        return aggregatedPrivilegedFees;
    }

    /// @notice Returns the amount of Ether that a specific account can move from `aggregatedPrivilegedFees` to their balance in the `balances` mapping.
    /// @param _addr The address of the specific account.
    function getPrivilegedFees(
        address _addr
    ) external view returns (uint256 fees) {
        if (
            privilegedShareholdersIndex[_addr] != 0 &&
            sharesInPrivilegedHands != 0
        ) {
            fees =
                (aggregatedPrivilegedFees * shares[_addr]) /
                sharesInPrivilegedHands;
        }
    }

    /// @notice Returns the total amount of Ether ready to withdraw for a specific account.
    /// @param _addr The address of the specific account.
    function getBalance(address _addr) external view returns (uint256) {
        return balances[_addr];
    }

    /// @notice Returns the block number when a specified account was minted Bananashares Tokens.
    /// @param _addr The address of the specific account.
    function getLastBlockGovTokenMinted(
        address _addr
    ) external view returns (uint48) {
        return lastBlockGovTokenMinted[_addr];
    }

    /// @notice Returns the `govTokensMinted` value.
    function getGovTokensMinted() external view returns (uint256) {
        return govTokensMinted * GOV_TOKEN_DECIMALS;
    }
}
