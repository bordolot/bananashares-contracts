//SPDX-License-Identifier: NONE
pragma solidity 0.8.23;

import {console} from "forge-std/Test.sol";

import {CoreTest_AssetsFactory} from "./Utils/CoreTest_AssetsFactory.sol";
import {SH_Stateless} from "./Utils/HandlersS-Less.sol";
// import {SH_Less_MakeSellOffer} from "./Utilities/HandlersS-Less.sol";
// import {SH_Less_CancelOffer} from "./Utilities/HandlersS-Less.sol";

import {IAssetInstance} from "../../src/core/util/IAssetInstance.sol";

import {AssetFactoryErrors} from "../../src/core/util/AssetFactoryErrors.sol";
import {AssetFactoryEvents} from "../../src/core/util/AssetFactoryEvents.sol";
import {AssetInstanceErrors} from "../../src/core/util/AssetInstanceErrors.sol";
import {AssetInstanceEvents} from "../../src/core/util/AssetInstanceEvents.sol";

contract Test_FuzzinngStateless is CoreTest_AssetsFactory, AssetFactoryEvents {
    function setUp() public {
        vm.roll(1);
        _createAssetFactory();
    }

    function _uint8ShuffleSeed(
        uint8 _input
    ) internal pure returns (uint8 _newSeed) {
        _newSeed = uint8(
            bound(
                uint256(keccak256(abi.encodePacked(_input))),
                0,
                uint256(type(uint8).max)
            )
        );
    }

    function _uint256ShuffleSeed(
        uint256 _input
    ) internal pure returns (uint256 _newSeed) {
        _newSeed = bound(
            uint256(keccak256(abi.encodePacked(_input))),
            0,
            type(uint256).max
        );
    }

    function testFuzzF_TryToWitdraw(address _user) public {
        if (_user != addressMike) {
            vm.expectRevert();
            vm.prank(_user);
            assetFactory.withdraw();
        }
    }

    function testFuzzF_SL_CreateAssetWithStrangeArrayLengths(
        string calldata _title,
        uint8 _NumberOfAuthors,
        uint8 _NumberOfAddresses,
        uint8 _NumberOfShareholders
    ) public {
        bytes32 _assetHash = keccak256(
            abi.encodePacked(
                (_NumberOfAuthors % 256) +
                    (_NumberOfAddresses % 256) +
                    (_NumberOfShareholders % 256)
            )
        );
        string[] memory _authors = new string[](_NumberOfAuthors);
        address[] memory _shareholderAddress = new address[](
            _NumberOfAddresses
        );
        uint24[] memory _shares = new uint24[](_NumberOfShareholders);

        uint8 i = 0;

        if (_NumberOfAuthors > 0) {
            for (i = 0; i < _NumberOfAuthors; i++) {
                _authors[i] = _uintToString(i + 1);
            }
        }
        if (_NumberOfAddresses > 0) {
            for (i = 0; i < _NumberOfAddresses; i++) {
                _shareholderAddress[i] = makeAddr(_uintToString(i + 1));
            }
        }

        if (_NumberOfShareholders > 0) {
            uint24 _sharesToRedistribute = TOTAL_SUPPLY;
            uint24 _sharesForShareholder = TOTAL_SUPPLY / _NumberOfShareholders;
            for (i = 0; i < _NumberOfShareholders; i++) {
                if (i == _NumberOfShareholders - 1) {
                    _shares[i] = _sharesToRedistribute;
                } else {
                    _shares[i] = _sharesForShareholder;
                    _sharesToRedistribute -= _sharesForShareholder;
                }
            }
        }

        vm.prank(addressMike);

        if (bytes(_title).length > TITLE_LENGTH_LIMIT) {
            vm.expectEmit(true, false, false, true);
            emit AssetInstanceCreationFailure(
                addressMike,
                "wrong title length"
            );
        } else if (_NumberOfAddresses > PRIV_SHAREDOLDERS_LIMIT) {
            vm.expectEmit(true, false, false, true);
            emit AssetInstanceCreationFailure(
                addressMike,
                "too many shareholders"
            );
        } else if (_NumberOfAddresses != _NumberOfAuthors) {
            vm.expectEmit(true, false, false, true);
            emit AssetInstanceCreationFailure(addressMike, "wrong length 1");
        } else if (_NumberOfAddresses != _NumberOfShareholders) {
            vm.expectEmit(true, false, false, true);
            emit AssetInstanceCreationFailure(addressMike, "wrong length 2");
        } else if (_NumberOfShareholders == 0) {
            vm.expectEmit(true, false, false, true);
            emit AssetInstanceCreationFailure(addressMike, "wrong suply");
        } else {
            vm.expectEmit(true, false, false, true);
            emit AssetInstanceCreated(addressMike, address(0));
        }

        //     else {
        //     vm.expectEmit(true, false, false, true);
        //     emit AssetInstanceCreationFailure(
        //         addressMike,
        //         "Low-level error occurred"
        //     );
        // }

        assetFactory.createAssetInstance(
            _title,
            _authors,
            _shareholderAddress,
            _shares,
            _assetHash
        );
    }

    function testFuzzF_SL_makeSellOffer(
        uint256 _assetSeed,
        uint24 _amount,
        uint96 _price,
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed
    ) public {
        _createTestAssets(_assetSeed, 1);
        SH_Stateless assetHandlerStateless = new SH_Stateless(
            assetsAddresses[0],
            address(bananasharesToken)
        );
        assetHandlerStateless.makeSellOffer(
            _amount,
            _price,
            _whichActorSeed,
            _actorIndexSeed
        );
    }

    function testFuzzF_SL_cancelOffer(
        uint256 _assetSeed,
        uint256 _amountSeed,
        uint256 _priceSeed,
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed
    ) public {
        _createTestAssets(_assetSeed, 1);
        SH_Stateless assetHandlerStateless = new SH_Stateless(
            assetsAddresses[0],
            address(bananasharesToken)
        );

        assetHandlerStateless.makeSellOffer_Legit(
            _amountSeed,
            _priceSeed,
            _actorIndexSeed
        );

        assetHandlerStateless.cancelOffer(_whichActorSeed, _actorIndexSeed);
    }

    function testFuzzF_SL_buyShares(
        uint256 _assetSeed,
        uint256 _amountSeed,
        uint8 _howOftenAmountCorrectSeed,
        uint256 _priceSeed,
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed,
        uint256 _msgValueSeed,
        uint8 _howOftenCorrectSeed,
        uint256 _sellPriceSeed
    ) public {
        _createTestAssets(_assetSeed, 1);
        SH_Stateless assetHandlerStateless = new SH_Stateless(
            assetsAddresses[0],
            address(bananasharesToken)
        );
        assetHandlerStateless.makeSellOffer_Legit(
            _amountSeed,
            _priceSeed,
            _actorIndexSeed
        );

        address _from = IAssetInstance(assetsAddresses[0])
            .getOffer(
                bound(
                    _uint256ShuffleSeed(_priceSeed),
                    1,
                    IAssetInstance(assetsAddresses[0]).getOffersLength()
                )
            )
            .from;

        assetHandlerStateless.buyShares(
            _whichActorSeed,
            _actorIndexSeed,
            _from,
            _amountSeed,
            _howOftenAmountCorrectSeed,
            _msgValueSeed,
            _howOftenCorrectSeed,
            _sellPriceSeed
        );
        assertEq(
            IAssetInstance(assetsAddresses[0]).getSharesInPrivilegedHands() +
                assetHandlerStateless.getSharesInNormalHands(),
            TOTAL_SUPPLY
        );
        assertEq(
            assetHandlerStateless.getAssetContractGain(),
            assetsAddresses[0].balance
        );
    }

    function testFuzzF_SL_payEarndFeesToAllPrivileged(
        uint256 _assetSeed,
        uint256 _amountSeed,
        uint8 _howOftenAmountCorrectSeed,
        uint256 _priceSeed,
        uint8 _whichActorSeed,
        uint8 _whichActorSeed2,
        uint256 _actorIndexSeed,
        uint256 _msgValueSeed,
        uint8 _howOftenCorrectSeed,
        uint256 _sellPriceSeed
    ) public {
        _createTestAssets(_assetSeed, 1);

        SH_Stateless assetHandlerStateless = new SH_Stateless(
            assetsAddresses[0],
            address(bananasharesToken)
        );

        assetHandlerStateless.makeSellOffer_Legit(
            _amountSeed,
            _priceSeed,
            _actorIndexSeed
        );
        require(
            IAssetInstance(assetsAddresses[0]).getOffersLength() >= 1,
            "testFuzzF_SL_payEarndFeesToAllPrivileged::1"
        );
        address _from = IAssetInstance(assetsAddresses[0])
            .getOffer(
                bound(
                    _uint256ShuffleSeed(_priceSeed),
                    1,
                    IAssetInstance(assetsAddresses[0]).getOffersLength()
                )
            )
            .from;
        /// @dev Makes sure the amount is often correct.
        /// @dev Makes sure the msg.value and _sellLimit is often correct ->  _howOftenAmountCorrectSeed = 0;.
        /// @dev By calling buyShares twice: the first time with _whichActorSeed and the second time with _whichActorSeed2, this function tries to simulate a scenario when fees for privileged shareholders are created. It happens when first actor is a fresh user or normal shareholder. -> _howOftenCorrectSeed = 0;
        assetHandlerStateless.buyShares(
            _whichActorSeed,
            _actorIndexSeed,
            _from,
            _amountSeed,
            0,
            _msgValueSeed,
            0,
            _sellPriceSeed
        );
        if (IAssetInstance(assetsAddresses[0]).getOffersLength() >= 1) {
            _from = IAssetInstance(assetsAddresses[0])
                .getOffer(IAssetInstance(assetsAddresses[0]).getOffersLength())
                .from;
            assetHandlerStateless.buyShares(
                _whichActorSeed2,
                _actorIndexSeed,
                _from,
                _amountSeed,
                _howOftenAmountCorrectSeed,
                _msgValueSeed,
                _howOftenCorrectSeed,
                _sellPriceSeed
            );
        }

        /// @dev Shuffle seeds.
        _howOftenCorrectSeed = _uint8ShuffleSeed(_howOftenCorrectSeed);
        _sellPriceSeed = _uint256ShuffleSeed(_sellPriceSeed);

        assetHandlerStateless.payEarndFeesToAllPrivileged(
            _howOftenCorrectSeed,
            _sellPriceSeed
        );

        assertEq(
            IAssetInstance(assetsAddresses[0]).getSharesInPrivilegedHands() +
                assetHandlerStateless.getSharesInNormalHands(),
            TOTAL_SUPPLY
        );
        assertEq(
            assetHandlerStateless.getAssetContractGain(),
            assetsAddresses[0].balance
        );
    }

    function testFuzzF_SL_withdraw(
        uint256 _assetSeed,
        uint256 _amountSeed,
        uint8 _howOftenAmountCorrectSeed,
        uint256 _priceSeed,
        uint8 _whichActorSeed,
        uint8 _whichActorSeed2,
        uint256 _actorIndexSeed,
        uint256 _msgValueSeed,
        uint8 _howOftenCorrectSeed,
        uint256 _sellPriceSeed
    ) public {
        _createTestAssets(_assetSeed, 1);
        SH_Stateless assetHandlerStateless = new SH_Stateless(
            assetsAddresses[0],
            address(bananasharesToken)
        );

        assetHandlerStateless.makeSellOffer_Legit(
            _amountSeed,
            _priceSeed,
            _actorIndexSeed
        );
        require(
            IAssetInstance(assetsAddresses[0]).getOffersLength() >= 1,
            "testFuzzF_SL_payEarndFeesToAllPrivileged::1"
        );
        address _from = IAssetInstance(assetsAddresses[0])
            .getOffer(
                bound(
                    _uint256ShuffleSeed(_priceSeed),
                    1,
                    IAssetInstance(assetsAddresses[0]).getOffersLength()
                )
            )
            .from;

        /// @dev Makes sure the amount is often correct .
        _howOftenAmountCorrectSeed = 0;
        /// @dev Makes sure the msg.value and _sellLimit is often correct _howOftenCorrectSeed = 0;.
        assetHandlerStateless.buyShares(
            _whichActorSeed,
            _actorIndexSeed,
            _from,
            _amountSeed,
            _howOftenAmountCorrectSeed,
            _msgValueSeed,
            0,
            _sellPriceSeed
        );

        assetHandlerStateless.withdraw(
            _whichActorSeed2,
            _actorIndexSeed,
            _howOftenCorrectSeed,
            _sellPriceSeed
        );
        assertEq(
            IAssetInstance(assetsAddresses[0]).getSharesInPrivilegedHands() +
                assetHandlerStateless.getSharesInNormalHands(),
            TOTAL_SUPPLY
        );
        assertEq(
            assetHandlerStateless.getAssetContractGain(),
            assetsAddresses[0].balance
        );
    }

    function testFuzzF_SL_changeOffer(
        uint256 _assetSeed,
        uint256 _amountSeed,
        uint256 _priceSeed,
        uint8 _whichActorSeed,
        uint8 _whichActorSeed2,
        uint256 _actorIndexSeed,
        uint256 _actorIndexSeed2,
        uint256 _msgValueSeed,
        uint8 _howOftenCorrectSeed,
        uint256 _sellPriceSeed
    ) public {
        _createTestAssets(_assetSeed, 1);
        SH_Stateless assetHandlerStateless = new SH_Stateless(
            assetsAddresses[0],
            address(bananasharesToken)
        );

        assetHandlerStateless.makeSellOffer_Legit(
            _amountSeed,
            _priceSeed,
            _actorIndexSeed
        );
        require(
            IAssetInstance(assetsAddresses[0]).getOffersLength() >= 1,
            "testFuzzF_SL_payEarndFeesToAllPrivileged::1"
        );
        address _from = IAssetInstance(assetsAddresses[0])
            .getOffer(
                bound(
                    _uint256ShuffleSeed(_priceSeed),
                    1,
                    IAssetInstance(assetsAddresses[0]).getOffersLength()
                )
            )
            .from;

        /// @dev Makes sure the amount is often correct _howOftenAmountCorrectSeed = 0;.
        /// @dev Makes sure the msg.value and _sellLimit is often correct _howOftenCorrectSeed = 0;.
        assetHandlerStateless.buyShares(
            _whichActorSeed,
            _actorIndexSeed,
            _from,
            _amountSeed,
            0,
            _msgValueSeed,
            0,
            _sellPriceSeed
        );
        assetHandlerStateless.changeOffer(
            _whichActorSeed2,
            _actorIndexSeed2,
            _howOftenCorrectSeed,
            _sellPriceSeed
        );

        assertEq(
            IAssetInstance(assetsAddresses[0]).getSharesInPrivilegedHands() +
                assetHandlerStateless.getSharesInNormalHands(),
            TOTAL_SUPPLY
        );
        assertEq(
            assetHandlerStateless.getAssetContractGain(),
            assetsAddresses[0].balance
        );
    }

    function testFuzzF_SL_putNewLicense(
        uint256 _assetSeed,
        uint8 _whichActorSeed,
        uint8 _whichActorSeed2,
        uint256 _actorIndexSeed,
        uint256 _actorIndexSeed2,
        uint8 _whichLicense,
        uint256 _licenseSeed,
        uint224 _valueForLicence
    ) public {
        _createTestAssets(_assetSeed, 1);
        SH_Stateless assetHandlerStateless = new SH_Stateless(
            assetsAddresses[0],
            address(bananasharesToken)
        );
        assetHandlerStateless.putNewLicense(
            _whichActorSeed,
            _actorIndexSeed,
            0,
            _licenseSeed,
            _valueForLicence
        );
        assetHandlerStateless.putNewLicense(
            _whichActorSeed2,
            _actorIndexSeed2,
            _whichLicense,
            _licenseSeed,
            _valueForLicence
        );
    }

    function testFuzzF_SL_activateLicense(
        uint256 _assetSeed,
        uint8 _whichActorSeed,
        uint8 _whichActorSeed2,
        uint256 _actorIndexSeed,
        uint256 _actorIndexSeed2,
        uint8 _whichLicense,
        uint256 _licenseSeed,
        uint224 _valueForLicence,
        bool _activateFlag
    ) public {
        _createTestAssets(_assetSeed, 1);
        SH_Stateless assetHandlerStateless = new SH_Stateless(
            assetsAddresses[0],
            address(bananasharesToken)
        );
        assetHandlerStateless.putNewLicense(
            _whichActorSeed,
            _actorIndexSeed,
            0,
            _licenseSeed,
            _valueForLicence
        );
        assetHandlerStateless.activateLicense(
            _whichActorSeed2,
            _actorIndexSeed2,
            _whichLicense,
            _licenseSeed,
            _activateFlag
        );
    }

    function testFuzzF_SL_signLicense(
        uint256 _assetSeed,
        uint8 _whichActorSeed,
        uint8 _whichActorSeed2,
        uint256 _actorIndexSeed,
        uint256 _actorIndexSeed2,
        uint8 _whichLicense,
        uint256 _licenseSeed,
        uint224 _valueForLicence,
        bool _activateFlag,
        uint8 _howOftenCorrectValue,
        uint256 _valueSeed
    ) public {
        _createTestAssets(_assetSeed, 1);
        SH_Stateless assetHandlerStateless = new SH_Stateless(
            assetsAddresses[0],
            address(bananasharesToken)
        );
        assetHandlerStateless.putNewLicense(
            _whichActorSeed,
            _actorIndexSeed,
            0,
            _licenseSeed,
            _valueForLicence
        );
        assetHandlerStateless.activateLicense(
            _whichActorSeed2,
            _actorIndexSeed2,
            _whichLicense,
            _licenseSeed,
            _activateFlag
        );

        /// @dev Shuffle seeds.
        _whichActorSeed2 = _uint8ShuffleSeed(_whichActorSeed2);
        _actorIndexSeed2 = _uint256ShuffleSeed(_actorIndexSeed2);
        _whichLicense = _uint8ShuffleSeed(_whichLicense);
        _licenseSeed = _uint256ShuffleSeed(_licenseSeed);

        assetHandlerStateless.signLicense(
            _whichActorSeed2,
            _actorIndexSeed2,
            _whichLicense,
            _licenseSeed,
            _howOftenCorrectValue,
            _valueSeed
        );
    }

    function testFuzzF_SL_payDividend(
        uint256 _assetSeed,
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed,
        uint8 _whichSeed,
        uint256 _licenseSeed,
        uint224 _valueForLicence,
        uint8 _howOftenCorrectAddress,
        uint256 _receiverSeed
    ) public {
        _createTestAssets(_assetSeed, 1);
        SH_Stateless assetHandlerStateless = new SH_Stateless(
            assetsAddresses[0],
            address(bananasharesToken)
        );
        /// @dev Create license.
        assetHandlerStateless.putNewLicense(
            _whichActorSeed,
            _actorIndexSeed,
            0,
            _licenseSeed,
            _valueForLicence
        );

        /// @dev Create offer.
        assetHandlerStateless.makeSellOffer_Legit(0, 0, _actorIndexSeed);
        address _from = IAssetInstance(assetsAddresses[0])
            .getOffer(
                bound(
                    _uint256ShuffleSeed(_actorIndexSeed),
                    1,
                    IAssetInstance(assetsAddresses[0]).getOffersLength()
                )
            )
            .from;
        /// @dev Shuffle seeds.
        _whichActorSeed = _uint8ShuffleSeed(_whichActorSeed);
        _actorIndexSeed = _uint256ShuffleSeed(_actorIndexSeed);

        /// @dev Create potentially normal user.
        assetHandlerStateless.buyShares(
            _whichActorSeed,
            _actorIndexSeed,
            _from,
            0,
            _whichSeed,
            0,
            _uint8ShuffleSeed(_whichSeed),
            0
        );

        /// @dev Shuffle seeds.
        _whichActorSeed = _uint8ShuffleSeed(_whichActorSeed);
        _actorIndexSeed = _uint256ShuffleSeed(_actorIndexSeed);
        _whichSeed = _uint8ShuffleSeed(_whichSeed);
        _whichSeed = _uint8ShuffleSeed(_whichSeed);
        _licenseSeed = _uint256ShuffleSeed(_licenseSeed);

        /// @dev Create a payment so users will have dividends.
        assetHandlerStateless.signLicense(
            _whichActorSeed,
            _actorIndexSeed,
            0,
            _licenseSeed,
            0,
            0
        );

        /// @dev Shuffle seeds.
        _whichActorSeed = _uint8ShuffleSeed(_whichActorSeed);
        _actorIndexSeed = _uint256ShuffleSeed(_actorIndexSeed);

        /// @dev Pay dividends to all users so next fresh user can purchase shares.
        assetHandlerStateless.payDividendToAll_Legit(
            _whichActorSeed,
            _actorIndexSeed
        );

        /// @dev Shuffle seeds.
        _whichActorSeed = _uint8ShuffleSeed(_whichActorSeed);
        _actorIndexSeed = _uint256ShuffleSeed(_actorIndexSeed);
        _whichSeed = _uint8ShuffleSeed(_whichSeed);

        _from = IAssetInstance(assetsAddresses[0])
            .getOffer(IAssetInstance(assetsAddresses[0]).getOffersLength())
            .from;
        /// @dev Create a potentially normal user without the right to a dividend.
        if (_from != address(0)) {
            assetHandlerStateless.buyShares(
                _whichActorSeed,
                _actorIndexSeed,
                _from,
                0,
                _whichSeed,
                0,
                _uint8ShuffleSeed(_whichSeed),
                0
            );
        }

        /// @dev Shuffle seeds.
        _whichActorSeed = _uint8ShuffleSeed(_whichActorSeed);
        _actorIndexSeed = _uint256ShuffleSeed(_actorIndexSeed);
        _whichSeed = _uint8ShuffleSeed(_whichSeed);
        _licenseSeed = _uint256ShuffleSeed(_licenseSeed);

        /// @dev Try to pay a dividend to a user without the right to any dividends.
        assetHandlerStateless.payDividend(
            _whichActorSeed,
            _actorIndexSeed,
            _howOftenCorrectAddress,
            _receiverSeed,
            _uint8ShuffleSeed(_whichSeed),
            _uint256ShuffleSeed(_licenseSeed)
        );

        /// @dev Shuffle seeds.
        _whichActorSeed = _uint8ShuffleSeed(_whichActorSeed);
        _actorIndexSeed = _uint256ShuffleSeed(_actorIndexSeed);
        _whichSeed = _uint8ShuffleSeed(_whichSeed);
        _whichSeed = _uint8ShuffleSeed(_whichSeed);
        _licenseSeed = _uint256ShuffleSeed(_licenseSeed);

        /// @dev Create a payment so users will have dividends.
        assetHandlerStateless.signLicense(
            _whichActorSeed,
            _actorIndexSeed,
            0,
            _licenseSeed,
            0,
            0
        );

        /// @dev Create a payment so users will have dividends.
        assetHandlerStateless.signLicense(
            _whichActorSeed,
            _actorIndexSeed,
            0,
            _licenseSeed,
            0,
            0
        );

        /// @dev Create a payment so users will have dividends.
        assetHandlerStateless.signLicense(
            _whichActorSeed,
            _actorIndexSeed,
            0,
            _licenseSeed,
            0,
            0
        );

        /// @dev Shuffle seeds.
        _whichActorSeed = _uint8ShuffleSeed(_whichActorSeed);
        _actorIndexSeed = _uint256ShuffleSeed(_actorIndexSeed);
        _whichSeed = _uint8ShuffleSeed(_whichSeed);
        _licenseSeed = _uint256ShuffleSeed(_licenseSeed);

        /// @dev Try to pay a dividend to a user without the right to any dividends.
        assetHandlerStateless.payDividend(
            _whichActorSeed,
            _actorIndexSeed,
            _howOftenCorrectAddress,
            _receiverSeed,
            _whichSeed,
            _licenseSeed
        );

        assertEq(
            IAssetInstance(assetsAddresses[0]).getSharesInPrivilegedHands() +
                assetHandlerStateless.getSharesInNormalHands(),
            TOTAL_SUPPLY
        );
        assertEq(
            assetHandlerStateless.getAssetContractGain(),
            assetsAddresses[0].balance
        );
    }
}
