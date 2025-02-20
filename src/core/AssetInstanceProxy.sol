// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import {console} from "forge-std/Test.sol";

import {Asset_Structs} from "./util/AssetInstanceStructs.sol";
import {AssetProxy} from "./util/AssetProxy.sol";
import {AssetInstanceStorage} from "./util/AssetInstanceStorage.sol";

/**
 *  @title The main contract responsible for interacting with a tokenized asset.
 *
 */

contract AssetInstanceProxy is AssetProxy, AssetInstanceStorage {
    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the `AssetInstanceProxy` contract.
    /// @param _nameOfAsset Specifies the name of the asset, which will be assigned to `nameOfAsset`.
    /// @param _initialOwners Specifies names of privileged shareholders, which will be assigned to the `authors` array.
    /// @param _shareholderAddress Specifies addresses of privileged shareholders, which will be assigned to the `privilegedShareholders` array.
    /// @param _shares Specifies the list of shares assigned to each privileged shareholder.
    /// @param _assetHash The hash of the asset.
    /// @dev address(0) and empty structs are pushed to storage arrays so that the corresponding ...Index mappings can be used to find the correct index in a specific array. If a mapping returns 0, it means the input cannot be found in the array.
    constructor(
        string memory _nameOfAsset,
        string[] memory _initialOwners,
        address[] memory _shareholderAddress,
        uint24[] memory _shares,
        bytes32 _assetHash
    ) AssetProxy(msg.sender) {
        uint _checkShares;
        Asset_Structs.Offer memory _emptyOffer;
        Asset_Structs.License memory _emptyLicense;
        Asset_Structs.Payment memory _emptyPayment;

        require(
            bytes(_nameOfAsset).length <= TITLE_LENGTH_LIMIT,
            "wrong title length"
        );
        require(
            _shareholderAddress.length <= PRIV_SHAREDOLDERS_LIMIT,
            "too many shareholders"
        );
        require(
            _shareholderAddress.length == _initialOwners.length,
            "wrong length 1"
        );
        require(_shareholderAddress.length == _shares.length, "wrong length 2");

        privilegedShareholders.push(address(0x0));

        for (uint24 i = 0; i < _shareholderAddress.length; i++) {
            require(
                privilegedShareholdersIndex[_shareholderAddress[i]] == 0,
                "duplicate address"
            );
            privilegedShareholdersIndex[_shareholderAddress[i]] = (i + 1);
            privilegedShareholders.push(_shareholderAddress[i]);
            shares[_shareholderAddress[i]] = _shares[i];
            _checkShares += _shares[i];
        }

        require(_checkShares == TOTAL_SUPPLY, "wrong suply");
        nameOfAsset = _nameOfAsset;
        assetHash = _assetHash;

        for (uint i = 0; i < _initialOwners.length; i++) {
            require(
                bytes(_initialOwners[i]).length <= AUTHOR_LENGTH_LIMIT,
                "wrong length author"
            );
            Asset_Structs.Author memory newAuthor = Asset_Structs.Author({
                name: _initialOwners[i]
            });
            authors.push(newAuthor);
        }

        _emptyOffer = Asset_Structs.Offer({
            from: address(0x0),
            value: 0,
            ownerFee: 0,
            privilegedFee: 0,
            amount: 0
        });
        _emptyLicense = Asset_Structs.License({
            licenseHash: bytes32("0x0"),
            value: 0,
            active: false
        });
        _emptyPayment = Asset_Structs.Payment({
            licenseHash: bytes32("0x0"),
            paymentValue: 0,
            date: 0,
            payer: address(0x0)
        });

        offers.push(_emptyOffer);
        licenses.push(_emptyLicense);
        payments.push(_emptyPayment);
        // Value of the immutable `assetFactoryAddr` set during implementation deployment.
        // assetFactoryAddr = msg.sender;
    }

    receive() external payable {}
}
