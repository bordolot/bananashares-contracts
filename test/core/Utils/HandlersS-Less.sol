//SPDX-License-Identifier: NONE
pragma solidity 0.8.23;

import {console2} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Asset_Structs} from "../../../src/core/util/AssetInstanceStructs.sol";
import {AssetInstanceErrors} from "../../../src/core/util/AssetInstanceErrors.sol";

import {AssetHandler} from "./AssetHandler.sol";

/// @title Main stateless handler
contract SH_Stateless is AssetHandler {
    address bananasharesTokenAddr;
    constructor(
        address _assetAddr,
        address _govTokenAddr
    ) AssetHandler(_assetAddr) {
        bananasharesTokenAddr = _govTokenAddr;
    }

    function makeSellOffer(
        uint24 _amount,
        uint96 _price,
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed
    ) external usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed) {
        bool _resultSuccess = false;
        if (asset.getPrivilegedShareholdersIndex(getCurrentActor()) == 0) {
            vm.expectRevert("Not privileged Shareholder");
        } else if (_amount == 0) {
            vm.expectRevert("Amount 0");
        } else if (asset.getShares(getCurrentActor()) < _amount) {
            vm.expectRevert("Not enough shares");
        } else if (_price < MIN_SELL_OFFER) {
            vm.expectRevert("Price too small");
        } else {
            vm.expectEmit(true, false, false, false);
            emit SellOfferPut(getCurrentActor(), 0, 0);
            _resultSuccess = true;
        }
        asset.makeSellOffer(_amount, _price);
        if (_resultSuccess) {
            /// @dev 'ghost variables' update
            _addOffererAddress(getCurrentActor());
        }
    }

    function makeSellOffer_Legit(
        uint256 _amountSeed,
        uint256 _priceSeed,
        uint256 _actorIndexSeed
    )
        external
        usePrivilegedShareholder(_actorIndexSeed)
        boundAmountInOffer(_amountSeed)
        boundPriceInOffer(_priceSeed)
    {
        if (offerAmount >= MIN_AMOUNT_IN_OFFER) {
            if (asset.getOffersIndex(currentActor) == 0) {
                /// @dev 'ghost variables' update
                _addOffererAddress(currentActor);
            }
            asset.makeSellOffer(offerAmount, offerPrice);
        }
    }

    function cancelOffer(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed
    ) external usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed) {
        bool _resultSuccess = false;
        if (asset.getPrivilegedShareholdersIndex(getCurrentActor()) == 0) {
            vm.expectRevert("Not privileged");
        } else if (asset.getOffersIndex(getCurrentActor()) == 0) {
            vm.expectRevert("No offer");
        } else {
            vm.expectEmit(true, false, false, false);
            emit OfferCancelled(getCurrentActor());
            _resultSuccess = true;
        }
        asset.cancelOffer();
        if (_resultSuccess) {
            /// @dev 'ghost variables' update
            _removeOffererAddress(getCurrentActor());
        }
    }

    function buyShares(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed,
        address _from,
        uint256 _amountSeed,
        uint8 _howOftenAmountCorrectSeed,
        uint256 _msgValueSeed,
        uint8 _howOftenMsgValueCorrectSeed,
        uint256 _sellPriceSeed
    )
        external
        usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed)
        boundBuyAmount(_from, _amountSeed, _howOftenAmountCorrectSeed)
    {
        buyShares_1(
            _from,
            _msgValueSeed,
            _howOftenMsgValueCorrectSeed,
            _sellPriceSeed
        );
    }

    function buyShares_1(
        address _from,
        uint256 _msgValueSeed,
        uint8 _howOftenMsgValueCorrectSeed,
        uint256 _sellPriceSeed
    )
        internal
        boundMsgValuePerShare(
            _msgValueSeed,
            _howOftenMsgValueCorrectSeed,
            _from
        )
        boundSellPrice(_howOftenMsgValueCorrectSeed, _sellPriceSeed)
    {
        buyShares_2(_from);
    }

    function buyShares_2(address _from) internal {
        Asset_Structs.Offer memory _tempOffer = asset.getOffer(
            asset.getOffersIndex(_from)
        );
        bool _resultSuccess = false;
        if (asset.getOffersIndex(_from) == 0) {
            // require(_tempOffer.amount != 0, "Offer 0");
            /// @dev In this combination this error will never occur.
            vm.expectRevert("Offer 0");
        } else if (buyAmount == 0) {
            // require(_amount != 0, "Amount 0");
            vm.expectRevert("Amount 0");
        } else if (
            asset.getOffer(asset.getOffersIndex(_from)).amount < buyAmount
        ) {
            // require(_amount <= _tempOffer.amount, "Amount exceeds available value");
            vm.expectRevert("Amount exceeds available value");
        } else if (MIN_SELL_OFFER > sellPrice) {
            // require(_sellLimit >= MIN_SELL_OFFER, "SellLimit too small");
            vm.expectRevert("SellLimit too small");
        } else if (
            asset.getPaymentIndex(asset.getLastDayOfDividendPayment(_from)) !=
            asset.getPaymentsLength()
        ) {
            // require(
            //     paymentIndex[lastDayOfDividendPayment[_from]] ==
            //         (_paymentsLength - 1),
            //     "Offeror has dividend to pay"
            // );
            vm.expectRevert("Offeror has dividend to pay");
        } else if (
            asset.getPaymentIndex(
                asset.getLastDayOfDividendPayment(currentActor)
            ) !=
            asset.getPaymentsLength() &&
            asset.getShares(currentActor) != 0
        ) {
            // require(
            //     paymentIndex[lastDayOfDividendPayment[msg.sender]] ==
            //         (_paymentsLength - 1),
            //     "Buyer has dividend to pay"
            // );
            vm.expectRevert("Buyer has dividend to pay");
        } else if (
            asset.getPrivilegedFees(_from) != 0 &&
            asset.getPrivilegedShareholdersIndex(_from) != 0
        ) {
            // require(
            //     aggregatedPrivilegedFees == 0,
            //     "Privileged Offeror has fees to collect"
            // );
            vm.expectRevert("Privileged Offeror has fees to collect");
        } else if (
            asset.getPrivilegedFees(currentActor) != 0 &&
            asset.getPrivilegedShareholdersIndex(currentActor) != 0
        ) {
            // require(
            //     aggregatedPrivilegedFees == 0,
            //     "Privileged Buyer has fees to collect"
            // );
            vm.expectRevert("Privileged Buyer has fees to collect");
        } else if (
            (uint256(_tempOffer.value) +
                uint256(_tempOffer.ownerFee) +
                uint256(_tempOffer.privilegedFee)) *
                buyAmount !=
            msgValuePerShare * buyAmount
        ) {
            // require(
            //     ((_amount * _tempOffer.value) +
            //         (_amount * _tempOffer.ownerFee) +
            //         (_amount * _tempOffer.privilegedFee)) == msg.value,
            //     "Wrong ether amount"
            // );
            vm.expectRevert("Wrong ether amount");
        } else {
            vm.expectEmit(true, true, false, true);
            emit SharesBought(_from, msgValuePerShare, currentActor, buyAmount);
            _resultSuccess = true;
        }

        asset.buyShares{value: msgValuePerShare * buyAmount}(
            _from,
            buyAmount,
            sellPrice
        );
        if (_resultSuccess) {
            /// @dev 'ghost variables' update
            _updateAddrArraysAfterBuyShares(currentActor, _from, buyAmount);
            _updateAssetContractGain(
                ((uint256(_tempOffer.value) +
                    uint256(_tempOffer.privilegedFee)) * buyAmount),
                0,
                0
            );
        }
    }

    function payEarndFeesToAllPrivileged(
        uint8 _howOftenLowGasSeed,
        uint256 _gasSeed
    ) external {
        bool _resultSuccess = false;
        bool _changeGasTx = false;
        uint256 _gasForTx;
        if (asset.getSharesInPrivilegedHands() == 0) {
            /// @dev To increase the likelihood of this revert occurring you can set PRIVILEGED_ALL_RATIO = 0, HOW_OFTEN_CORRECT_AMOUNT = 100, HOW_OFTEN_CORRECT_MSGVALUE = 100,HOW_OFTEN_CORRECT_SELLLIMIT = 100, and int .toml:: runs = 10000
            vm.expectRevert("priv shares 0");
        } else if (
            _howOftenLowGasSeed <= THRESHOLD_GAS_IS_SET_LOW &&
            asset.getAuthorsLength() != 1
        ) {
            _changeGasTx = true;
            _gasForTx = bound(
                _gasSeed,
                GAS_LIMIT_FEES - GAS_LIMIT_RANGE,
                GAS_LIMIT_FEES
            );
            vm.expectEmit(true, false, false, false);
            emit GasLimitTooLow();
            vm.expectRevert("Not enough gas");
        } else if (asset.getAggregatedPrivilegedFees() != 0) {
            vm.expectEmit(false, false, false, true);
            emit EarndFeesToAllPrivileged(asset.getAggregatedPrivilegedFees());
        } else {
            vm.expectEmit(false, false, false, true);
            emit EarndFeesToAllPrivileged(0);
            _resultSuccess = true;
        }
        if (!_changeGasTx) {
            asset.payEarndFeesToAllPrivileged();
        } else {
            asset.payEarndFeesToAllPrivileged{gas: _gasForTx}();
        }

        if (_resultSuccess) {
            /// @dev 'ghost variables' update
        }
    }

    function withdraw(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed,
        uint8 _howOftenCorrectSeed,
        uint256 _withdrawSeed
    )
        external
        usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed)
        boundWithdrawAmountFullRange(_howOftenCorrectSeed, _withdrawSeed)
        boundBlockNumber(_howOftenCorrectSeed, _withdrawSeed)
    {
        bool _resultSuccess = false;
        if (
            !isBlockNumberCorrect &&
            asset.getPrivilegedShareholdersIndex(currentActor) != 0 &&
            IERC20(bananasharesTokenAddr).balanceOf(currentActor) != 0
        ) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    AssetInstanceErrors.WithdrawLockActive.selector
                )
            );
        } else if (withdrawAmount > asset.getBalance(currentActor)) {
            vm.expectRevert("Insufficient balance");
        } else {
            vm.expectEmit(true, false, false, true);
            emit Withdrawal(currentActor, withdrawAmount);
            _resultSuccess = true;
        }
        asset.withdraw(withdrawAmount);
        if (_resultSuccess) {
            _updateAssetContractGain(0, 0, withdrawAmount);
            /// @dev 'ghost variables' update
        }
    }

    function changeOffer(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed,
        uint8 _howOftenCorrectSeed,
        uint256 _sellPriceSeed
    )
        external
        usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed)
        boundSellPrice(_howOftenCorrectSeed, _sellPriceSeed)
    {
        bool _resultSuccess = false;
        if (asset.getOffersIndex(currentActor) == 0) {
            vm.expectRevert("No offers");
        } else if (sellPrice < MIN_SELL_OFFER) {
            vm.expectRevert("SellLimit too small");
        } else {
            (uint256 _x, , ) = _getNewPriceForShare(currentActor, sellPrice);
            vm.expectEmit(true, false, false, true);
            emit OfferChanged(currentActor, _x);
            _resultSuccess = true;
        }
        asset.changeOffer(sellPrice);
        if (_resultSuccess) {
            /// @dev 'ghost variables' update
        }
    }

    function putNewLicense(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed,
        uint8 _whichLicense,
        uint256 _licenseSeed,
        uint224 _valueForLicence
    )
        external
        usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed)
        boundLicenseHashInput(_whichLicense, _licenseSeed)
    {
        bool _resultSuccess = false;
        if (asset.getPrivilegedShareholdersIndex(currentActor) == 0) {
            vm.expectRevert("Not privileged");
        } else if (asset.getLicensesIndex(licenceHashInput) != 0) {
            vm.expectRevert("This license exists");
        } else {
            vm.expectEmit(true, false, false, false);
            emit NewLicenseCreated(currentActor);
            _resultSuccess = true;
        }
        asset.putNewLicense(licenceHashInput, _valueForLicence);
        if (_resultSuccess) {
            /// @dev 'ghost variables' update
        }
    }

    function activateLicense(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed,
        uint8 _whichLicense,
        uint256 _licenseSeed,
        bool _activateFlag
    )
        external
        usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed)
        boundLicenseHashInput(_whichLicense, _licenseSeed)
    {
        bool _resultSuccess = false;
        if (asset.getPrivilegedShareholdersIndex(currentActor) == 0) {
            vm.expectRevert("Not privileged");
        } else if (asset.getLicensesIndex(licenceHashInput) == 0) {
            vm.expectRevert("No such license");
        } else {
            vm.expectEmit(true, false, false, true);
            if (_activateFlag) {
                emit LicenseActivated(currentActor, licenceHashInput);
            } else {
                emit LicenseDeactivated(currentActor, licenceHashInput);
            }
            _resultSuccess = true;
        }
        asset.activateLicense(licenceHashInput, _activateFlag);
        if (_resultSuccess) {
            /// @dev 'ghost variables' update
        }
    }

    function signLicense(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed,
        uint8 _whichLicense,
        uint256 _licenseSeed,
        uint8 _howOftenCorrectValue,
        uint256 _valueSeed
    )
        external
        usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed)
        boundLicenseHashInput(_whichLicense, _licenseSeed)
        boundLicenceValue(_howOftenCorrectValue, _valueSeed)
    {
        bool _resultSuccess = false;
        if (asset.getLicensesIndex(licenceHashInput) == 0) {
            vm.expectRevert("Doesn't exist");
        } else if (
            asset.getLicense(asset.getLicensesIndex(licenceHashInput)).active ==
            false
        ) {
            vm.expectRevert("Not active");
        } else if (
            asset.getLicense(asset.getLicensesIndex(licenceHashInput)).value !=
            licenceValue
        ) {
            vm.expectRevert("Not enough");
        } else {
            vm.expectEmit(true, false, false, true);
            emit NewPayment(currentActor, licenceHashInput);
            _resultSuccess = true;
        }

        asset.signLicense{value: licenceValue}(licenceHashInput);
        if (_resultSuccess) {
            _updateAssetContractGain(0, licenceValue, 0);
            /// @dev 'ghost variables' update
        }
    }

    function payDividend(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed,
        uint8 _howOftenCorrectAddress,
        uint256 _receiverSeed,
        uint8 _howOftenLowGasSeed,
        uint256 _gasSeed
    )
        external
        usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed)
        boundDividendReceiver(_howOftenCorrectAddress, _receiverSeed)
    {
        bool _resultSuccess = false;
        (uint256 _value, uint256 _howMany) = asset.getDividendToPay(
            dividendReceiver
        );
        bool _changeGasTx = false;
        uint256 _gasForTx;
        if (asset.getShares(dividendReceiver) == 0) {
            vm.expectRevert("Not a shareholder");
        } else if (asset.getPaymentsLength() == 0) {
            vm.expectRevert("No payments");
        } else if (_howMany == 0) {
            vm.expectRevert("No dividends");
        } else if (
            _howOftenLowGasSeed <= THRESHOLD_GAS_IS_SET_LOW && _howMany >= 2
        ) {
            _changeGasTx = true;
            _gasForTx = bound(_gasSeed, GAS_LIMIT - GAS_LIMIT_RANGE, GAS_LIMIT);
            vm.expectEmit(true, false, false, false);
            emit DividendPaidOnlyPartly(dividendReceiver, 999, 666);
        } else {
            vm.expectEmit(true, false, false, true);
            emit DividendPaid(dividendReceiver, _value, _howMany);
            _resultSuccess = true;
        }

        if (!_changeGasTx) {
            asset.payDividend(dividendReceiver);
        } else {
            asset.payDividend{gas: _gasForTx}(dividendReceiver);
        }

        if (_resultSuccess) {
            /// @dev 'ghost variables' update
        }
    }

    function payDividendToAll_Legit(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed
    ) external usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed) {
        for (uint i = 1; i < allShareholderAddresses.length; i++) {
            (uint256 _value, uint256 _howMany) = asset.getDividendToPay(
                allShareholderAddresses[i]
            );
            bool _resultSuccess = false;
            if (asset.getShares(allShareholderAddresses[i]) == 0) {
                vm.expectRevert("Not a shareholder");
            } else if (asset.getPaymentsLength() == 0) {
                vm.expectRevert("No payments");
            } else if (_howMany == 0) {
                vm.expectRevert("No dividends");
            } else {
                vm.expectEmit(true, false, false, true);
                emit DividendPaid(allShareholderAddresses[i], _value, _howMany);
                _resultSuccess = true;
            }
            asset.payDividend(allShareholderAddresses[i]);
            if (_resultSuccess) {
                /// @dev 'ghost variables' update
            }
        }
    }
}

/// @title Used for makeSellOffer()
contract SH_Less_MakeSellOffer is AssetHandler {
    constructor(address _assetAddr) AssetHandler(_assetAddr) {}

    function makeSellOffer(
        uint24 _amount,
        uint96 _price,
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed
    ) external usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed) {
        if (asset.getPrivilegedShareholdersIndex(getCurrentActor()) == 0) {
            vm.expectRevert("Not privileged Shareholder");
        } else if (_amount == 0) {
            vm.expectRevert("Amount 0");
        } else if (asset.getShares(getCurrentActor()) < _amount) {
            vm.expectRevert("Not enough shares");
        } else if (_price < MIN_SELL_OFFER) {
            vm.expectRevert("Price too small");
        } else {
            vm.expectEmit(true, false, false, false);
            emit SellOfferPut(getCurrentActor(), 0, 0);
        }
        asset.makeSellOffer(_amount, _price);
    }
}

/// @title Used for cancelOffer()
contract SH_Less_CancelOffer is AssetHandler {
    constructor(address _assetAddr) AssetHandler(_assetAddr) {}

    function makeSellOffer_Legit(
        uint256 _amountSeed,
        uint256 _priceSeed,
        uint256 _actorIndexSeed
    )
        external
        usePrivilegedShareholder(_actorIndexSeed)
        boundAmountInOffer(_amountSeed)
        boundPriceInOffer(_priceSeed)
    {
        if (offerAmount >= MIN_AMOUNT_IN_OFFER) {
            if (asset.getOffersIndex(currentActor) == 0) {
                _addOffererAddress(currentActor);
            }
            asset.makeSellOffer(offerAmount, offerPrice);
        }
    }
}
