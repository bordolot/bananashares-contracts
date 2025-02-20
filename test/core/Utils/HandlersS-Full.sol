//SPDX-License-Identifier: NONE
pragma solidity 0.8.23;

import {console} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AssetHandler} from "./AssetHandler.sol";

import {Asset_Structs} from "../../../src/core/util/AssetInstanceStructs.sol";

/// @title Main statefull handler
/// @notice "If blocks" are used to handle reverts thar are caused by inputs that are known in advance to cause revert.
contract SH_Statefull is AssetHandler {
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
        if (asset.getPrivilegedShareholdersIndex(getCurrentActor()) == 0) {
            //revert expected
        } else if (_amount == 0) {
            //revert expected
        } else if (asset.getShares(getCurrentActor()) < _amount) {
            //revert expected
        } else if (_price < MIN_SELL_OFFER) {
            //revert expected
        } else {
            asset.makeSellOffer(_amount, _price);
            /// @dev 'ghost variables' update
            if (offererIndex[getCurrentActor()] == 0) {
                _addOffererAddress(getCurrentActor());
            }
        }
    }

    function cancelOffer(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed
    ) external usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed) {
        if (asset.getPrivilegedShareholdersIndex(getCurrentActor()) == 0) {
            //revert expected
        } else if (asset.getOffersIndex(getCurrentActor()) == 0) {
            //revert expected
        } else {
            asset.cancelOffer();
            /// @dev 'ghost variables' update
            _removeOffererAddress(getCurrentActor());
        }
    }

    function buyShares(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed,
        uint256 _fromSeed,
        uint256 _amountSeed,
        uint8 _howOftenAmountCorrectSeed,
        uint256 _msgValueSeed,
        uint8 _howOftenMsgValueCorrectSeed,
        uint256 _sellPriceSeed
    ) external usePrivShareholerOrRandomUser(_whichActorSeed, _actorIndexSeed) {
        address _from = address(0);
        if (asset.getOffersLength() >= 1) {
            _from = asset
                .getOffer(bound(_fromSeed, 1, asset.getOffersLength()))
                .from;
        }
        buyShares_1(
            _from,
            _amountSeed,
            _howOftenAmountCorrectSeed,
            _msgValueSeed,
            _howOftenMsgValueCorrectSeed,
            _sellPriceSeed
        );
    }

    function buyShares_1(
        address _from,
        uint256 _amountSeed,
        uint8 _howOftenAmountCorrectSeed,
        uint256 _msgValueSeed,
        uint8 _howOftenMsgValueCorrectSeed,
        uint256 _sellPriceSeed
    )
        internal
        boundBuyAmount(_from, _amountSeed, _howOftenAmountCorrectSeed)
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
        if (asset.getOffersIndex(_from) == 0) {
            //revert expected
        } else if (buyAmount == 0) {
            //revert expected
        } else if (
            asset.getOffer(asset.getOffersIndex(_from)).amount < buyAmount
        ) {
            //revert expected
        } else if (MIN_SELL_OFFER > sellPrice) {
            //revert expected
        } else if (
            asset.getPaymentIndex(asset.getLastDayOfDividendPayment(_from)) !=
            asset.getPaymentsLength()
        ) {
            //revert expected
        } else if (
            asset.getPaymentIndex(
                asset.getLastDayOfDividendPayment(currentActor)
            ) !=
            asset.getPaymentsLength() &&
            asset.getShares(currentActor) != 0
        ) {
            //revert expected
        } else if (
            asset.getPrivilegedFees(_from) != 0 &&
            asset.getPrivilegedShareholdersIndex(_from) != 0
        ) {
            //revert expected
        } else if (
            asset.getPrivilegedFees(currentActor) != 0 &&
            asset.getPrivilegedShareholdersIndex(currentActor) != 0
        ) {
            //revert expected
        } else if (
            (uint256(_tempOffer.value) +
                uint256(_tempOffer.ownerFee) +
                uint256(_tempOffer.privilegedFee)) *
                buyAmount !=
            msgValuePerShare * buyAmount
        ) {
            //revert expected
        } else {
            asset.buyShares{value: msgValuePerShare * buyAmount}(
                _from,
                buyAmount,
                sellPrice
            );
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
        if (asset.getSharesInPrivilegedHands() == 0) {
            //revert expected
        } else if (_howOftenLowGasSeed <= THRESHOLD_GAS_IS_SET_LOW) {
            // revert expected
            // console.log(_gasSeed);
            _gasSeed;
        } else if (asset.getAggregatedPrivilegedFees() != 0) {
            //revert expected
        } else {
            asset.payEarndFeesToAllPrivileged();
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
        if (
            !isBlockNumberCorrect &&
            asset.getPrivilegedShareholdersIndex(currentActor) != 0 &&
            IERC20(bananasharesTokenAddr).balanceOf(currentActor) != 0
        ) {
            //revert expected
        } else if (withdrawAmount > asset.getBalance(currentActor)) {
            //revert expected
        } else {
            asset.withdraw(withdrawAmount);
            /// @dev 'ghost variables' update
            _updateAssetContractGain(0, 0, withdrawAmount);
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
        if (asset.getOffersIndex(currentActor) == 0) {
            //revert expected
        } else if (sellPrice < MIN_SELL_OFFER) {
            //revert expected
        } else {
            asset.changeOffer(sellPrice);
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
        if (asset.getPrivilegedShareholdersIndex(currentActor) == 0) {
            //revert expected
        } else if (asset.getLicensesIndex(licenceHashInput) != 0) {
            //revert expected
        } else {
            asset.putNewLicense(licenceHashInput, _valueForLicence);
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
        if (asset.getPrivilegedShareholdersIndex(currentActor) == 0) {
            //revert expected
        } else if (asset.getLicensesIndex(licenceHashInput) == 0) {
            //revert expected
        } else {
            asset.activateLicense(licenceHashInput, _activateFlag);
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
        if (asset.getLicensesIndex(licenceHashInput) == 0) {
            //revert expected
        } else if (
            asset.getLicense(asset.getLicensesIndex(licenceHashInput)).active ==
            false
        ) {
            //revert expected
        } else if (
            asset.getLicense(asset.getLicensesIndex(licenceHashInput)).value !=
            licenceValue
        ) {
            //revert expected
        } else {
            asset.signLicense{value: licenceValue}(licenceHashInput);
            /// @dev 'ghost variables' update
            _updateAssetContractGain(0, licenceValue, 0);
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
        (, uint256 _howMany) = asset.getDividendToPay(dividendReceiver);
        uint256 _gasForTx;
        if (asset.getShares(dividendReceiver) == 0) {
            //revert expected
        } else if (asset.getPaymentsLength() == 0) {
            //revert expected
        } else if (_howMany == 0) {
            //revert expected
        } else if (
            _howOftenLowGasSeed <= THRESHOLD_GAS_IS_SET_LOW && _howMany >= 2
        ) {
            /// @todo This gas randomisation needs more analizys
            _gasForTx = bound(_gasSeed, GAS_LIMIT - GAS_LIMIT_RANGE, GAS_LIMIT);
            asset.payDividend{gas: _gasForTx}(dividendReceiver);
            /// @dev 'ghost variables' update
        } else {
            asset.payDividend(dividendReceiver);
            /// @dev 'ghost variables' update
        }
    }
}
