//SPDX-License-Identifier: NONE
pragma solidity 0.8.23;

// import {AssetsFactory, AssetCore, Asset} from "../../src/AssetsFactory.sol";
import {Test, console} from "forge-std/Test.sol";
import {Globals} from "../../core/Utils/Globals.sol";
// import {Actors} from "./Actors.sol";

import {IAssetFactory} from "../../../src/core/util/IAssetFactory.sol";
import {IAssetInstance} from "../../../src/core/util/IAssetInstance.sol";
import {Asset_Structs} from "../../../src/core/util/AssetInstanceStructs.sol";

/// @title Creates specified number of Asset contracts
/// @notice Values that can be modified before testing: FIRST_SHAREHOLDER_MAX_SHARES
contract CreateAssetInstance is Test, Globals {
    /// @dev Each TestAsset from testAssetsInfo is used to create a corresponding Asset contract.
    /// @dev So testAssetsInfo[i].assetHash() == Asset(assetsAddresses[i]).assetHash().
    TestAsset[] internal testAssetsInfo;
    address[] internal assetsAddresses;

    /// @param _numberOfAssets number of assets in one test call
    function _createTestAssetsCore(
        address _assetFactoryAddr,
        uint256 _numberOfAssets
    ) internal {
        address _newAssetAddress;
        TestAsset memory _tempTestAsset;

        for (uint i = 0; i < _numberOfAssets; i++) {
            _tempTestAsset = testAssetsInfo[i];
            IAssetFactory(_assetFactoryAddr).createAssetInstance(
                _tempTestAsset.nameOfAsset,
                _tempTestAsset.authors,
                _tempTestAsset.shareholderAddress,
                _tempTestAsset.shares,
                _tempTestAsset.assetHash
            );
            _newAssetAddress = IAssetFactory(_assetFactoryAddr)
                .getAssetInstanceByHash(_tempTestAsset.assetHash);
            assetsAddresses.push(_newAssetAddress);
            vm.resetGasMetering();
        }
    }

    function _createTestAssets(
        address _assetFactoryAddr,
        uint256 _seed,
        uint256 _numberOfAssets
    ) internal {
        _fillTestAssetsInfo(_seed, _numberOfAssets);
        _createTestAssetsCore(_assetFactoryAddr, _numberOfAssets);
    }

    function _createTestAssetsOnlyOneShareholder(
        address _assetFactoryAddr,
        uint256 _seed,
        uint256 _numberOfAssets
    ) internal {
        _fillTestAssetsInfoOnlyOnePrivShareholder(_seed, _numberOfAssets);
        _createTestAssetsCore(_assetFactoryAddr, _numberOfAssets);
    }

    function _createSpecificAssetLocally(
        address _assetFactoryAddr,
        string memory _nameOfAsset,
        string[] memory _initialOwners,
        address[] memory _shareholderAddress,
        uint24[] memory _shares,
        bytes32 _assetHash
    ) internal returns (address) {
        address _newAssetAddress;
        IAssetFactory(_assetFactoryAddr).createAssetInstance(
            _nameOfAsset,
            _initialOwners,
            _shareholderAddress,
            _shares,
            _assetHash
        );
        _newAssetAddress = IAssetFactory(_assetFactoryAddr)
            .getAssetInstanceByHash(_assetHash);
        return _newAssetAddress;
    }

    function _fillTestAssetsInfo(
        uint256 _seed,
        uint256 _numberOfAssets
    ) internal {
        uint256 _internalSeed;
        string memory _tempTitle;
        string[] memory _tempAuthors;
        address[] memory _tempShareholderAddress;
        uint24[] memory _tempShares;
        bytes32 _tempHash;
        TestAsset memory _tempTestAsset;

        for (uint i = 0; i < _numberOfAssets; i++) {
            _internalSeed = uint256(keccak256(abi.encodePacked(_seed + i)));
            (_tempTitle, _tempHash) = _createAssetTitleAndHash(_internalSeed);

            uint24 _numberOfShareholders = uint24(
                (_internalSeed % uint256(PRIV_SHAREDOLDERS_LIMIT)) + 1
            );
            uint24 _numberOfSharesForFirstShareholder = uint24(
                (_internalSeed % FIRST_SHAREHOLDER_MAX_SHARES) + 1
            );
            (
                _tempAuthors,
                _tempShareholderAddress
            ) = _createPrivilegedShareholders(
                _numberOfShareholders,
                _internalSeed
            );
            _tempShares = _redistributeShares(
                _numberOfShareholders,
                _numberOfSharesForFirstShareholder
            );
            _tempTestAsset.nameOfAsset = _tempTitle;
            _tempTestAsset.authors = _tempAuthors;
            _tempTestAsset.shareholderAddress = _tempShareholderAddress;
            _tempTestAsset.shares = _tempShares;
            _tempTestAsset.assetHash = _tempHash;
            testAssetsInfo.push(_tempTestAsset);
            vm.resetGasMetering();
        }
    }

    function _fillTestAssetsInfoOnlyOnePrivShareholder(
        uint256 _seed,
        uint256 _numberOfAssets
    ) internal {
        uint256 _internalSeed;
        string memory _tempTitle;
        string[] memory _tempAuthors;
        address[] memory _tempShareholderAddress;
        uint24[] memory _tempShares;
        bytes32 _tempHash;
        TestAsset memory _tempTestAsset;

        for (uint i = 0; i < _numberOfAssets; i++) {
            _internalSeed = uint256(keccak256(abi.encodePacked(_seed + i)));
            (_tempTitle, _tempHash) = _createAssetTitleAndHash(_internalSeed);

            uint24 _numberOfShareholders = 1;
            (
                _tempAuthors,
                _tempShareholderAddress
            ) = _createPrivilegedShareholders(
                _numberOfShareholders,
                _internalSeed
            );
            _tempShares = _redistributeShares(_numberOfShareholders, 0);
            _tempTestAsset.nameOfAsset = _tempTitle;
            _tempTestAsset.authors = _tempAuthors;
            _tempTestAsset.shareholderAddress = _tempShareholderAddress;
            _tempTestAsset.shares = _tempShares;
            _tempTestAsset.assetHash = _tempHash;
            testAssetsInfo.push(_tempTestAsset);
            vm.resetGasMetering();
        }
    }

    function _createAssetTitleAndHash(
        uint256 _seed
    ) internal pure returns (string memory _title, bytes32 _hash) {
        _title = _uintToStringFull(uint96(_seed));
        _hash = keccak256(abi.encodePacked(_seed));
    }

    function _createPrivilegedShareholders(
        uint24 _numberOfShareholdersToCreate,
        uint256 _seed
    )
        internal
        returns (string[] memory _authors, address[] memory _shareholderAddress)
    {
        uint256 _internalSeed;
        string memory _name;
        _authors = new string[](_numberOfShareholdersToCreate);
        _shareholderAddress = new address[](_numberOfShareholdersToCreate);
        for (uint24 i = 0; i < _numberOfShareholdersToCreate; i++) {
            _internalSeed = uint256(keccak256(abi.encodePacked(_seed + i)));
            _name = _uintToStringFull(uint64(_internalSeed));
            _authors[i] = _name;
            _shareholderAddress[i] = makeAddr(_name);
            vm.resetGasMetering();
        }
    }

    function _redistributeShares(
        uint24 _numberOfShareholders,
        uint24 _numberOfSharesForFirstShareholder
    ) internal pure returns (uint24[] memory _shares) {
        _shares = new uint24[](_numberOfShareholders);
        if (_numberOfShareholders == 1) {
            _shares[0] = TOTAL_SUPPLY;
        } else {
            uint24 _numberOfSharesForTheRest = (TOTAL_SUPPLY -
                _numberOfSharesForFirstShareholder) /
                (_numberOfShareholders - 1);
            uint24 _numberOfSharesForTheLast = (TOTAL_SUPPLY -
                _numberOfSharesForFirstShareholder);
            _shares[0] = _numberOfSharesForFirstShareholder;
            for (uint i = 1; i < _numberOfShareholders; i++) {
                if (i == _numberOfShareholders - 1) {
                    _shares[i] = _numberOfSharesForTheLast;
                } else {
                    _shares[i] = _numberOfSharesForTheRest;
                    _numberOfSharesForTheLast -= _numberOfSharesForTheRest;
                }
            }
        }
    }

    function _createSellOffer(
        address _assetAddr,
        address _privShareholAddr,
        uint256 _numberOfShares,
        uint256 _pricePerShare
    ) internal {
        if (
            IAssetInstance(_assetAddr).getPrivilegedShareholdersIndex(
                _privShareholAddr
            ) == 0
        ) {
            revert("Given address doesn't belong to a privileged shareholder");
        }
        vm.startPrank(_privShareholAddr);
        IAssetInstance(_assetAddr).makeSellOffer(
            uint24(_numberOfShares),
            uint96(_pricePerShare)
        );
        vm.stopPrank();
    }

    function _buyShares(
        address _buyer,
        address _assetAddr,
        address _offeror,
        uint24 _numberOfShares,
        uint96 _newPricePerShare
    ) internal {
        uint256 _index;
        uint256 _pricePerShareToPay;
        vm.startPrank(_buyer);
        _index = IAssetInstance(_assetAddr).getOffersIndex(_offeror);
        Asset_Structs.Offer memory _offer = IAssetInstance(_assetAddr).getOffer(
            _index
        );
        _pricePerShareToPay =
            uint256(_offer.value) +
            uint256(_offer.privilegedFee) +
            uint256(_offer.ownerFee);
        IAssetInstance(_assetAddr).buyShares{
            value: _pricePerShareToPay * _numberOfShares
        }(_offeror, _numberOfShares, _newPricePerShare);
        vm.stopPrank();
    }

    function _putAllSharesInOffers(
        address _assetAddr,
        uint96 _newPricePerShare
    ) internal {
        address[] memory _allPrivilegedShareholders;
        uint24 _numberOfShares;
        uint i;

        _allPrivilegedShareholders = IAssetInstance(_assetAddr)
            .getAllPrivShareholders();

        for (i = 1; i < _allPrivilegedShareholders.length; i++) {
            _numberOfShares = IAssetInstance(_assetAddr).getShares(
                _allPrivilegedShareholders[i]
            );
            if (_numberOfShares > 0) {
                _createSellOffer(
                    _assetAddr,
                    _allPrivilegedShareholders[i],
                    _numberOfShares,
                    _newPricePerShare
                );
            }
        }
    }

    function _buyOutAllSharesInOffersByOneUser(
        address _assetAddr,
        address _user,
        uint96 _newPricePerShare
    ) internal {
        uint256 _numberOfOffers;
        Asset_Structs.Offer memory _offer;
        _numberOfOffers = IAssetInstance(_assetAddr).getOffersLength();
        if (_numberOfOffers == 0) {
            revert("_buyOutAllSharesInOffersByOneUser: no offers");
        }
        _offer = IAssetInstance(_assetAddr).getOffer(1);
        _buyShares(
            _user,
            _assetAddr,
            _offer.from,
            _offer.amount,
            _newPricePerShare
        );
        _numberOfOffers = IAssetInstance(_assetAddr).getOffersLength();
        while (_numberOfOffers > 1) {
            _offer = IAssetInstance(_assetAddr).getOffer(1);
            if (_offer.from == _user) {
                _offer = IAssetInstance(_assetAddr).getOffer(2);
            }
            _buyShares(
                _user,
                _assetAddr,
                _offer.from,
                _offer.amount,
                _newPricePerShare
            );
            _numberOfOffers = IAssetInstance(_assetAddr).getOffersLength();
        }
    }
}
