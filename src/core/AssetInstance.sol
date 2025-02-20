// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.23;

import {console} from "forge-std/Test.sol";

import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

import {AssetInstanceStorage} from "./util/AssetInstanceStorage.sol";
import {AssetInstanceEvents} from "./util/AssetInstanceEvents.sol";
import {AssetInstanceErrors} from "./util/AssetInstanceErrors.sol";
import {AssetInstanceMods} from "./util/AssetInstanceMods.sol";
import {Asset_Structs} from "./util/AssetInstanceStructs.sol";
import {IAssetInstance_write} from "./util/IAssetInstance_write.sol";
import {IAssetFactory_write} from "./util/IAssetFactory_write.sol";
import {IAssetFactory_read} from "./util/IAssetFactory_read.sol";

/**
 *  @title The version 0.1.0 implementation of `AssetInstanceProxy`.
 *
 */

contract AssetInstance is
    AssetInstanceStorage,
    AssetInstanceEvents,
    AssetInstanceErrors,
    AssetInstanceMods,
    IAssetInstance_write
{
    using Asset_Structs for *;

    constructor(address _assetsFactoryAddr) {
        assetFactoryAddr = _assetsFactoryAddr;
    }

    // -----------------
    //    Write Functions
    // -----------------

    /// @notice Checks if there is an existing `Asset_Structs.Offer` associated with a given address in the `offers` array.
    /// @param _addr The address to check.
    /// @return bool Returns `true` if there is an existing `Asset_Structs.Offer`.
    /// @return uint24 Returns the index of `Asset_Structs.Offer` in the `offers` array.
    function _checkIfOfferIsAlreadyCreated(
        address _addr
    ) internal view returns (bool, uint24) {
        uint24 _index = offersIndex[_addr];
        if (_index != 0) {
            return (true, _index);
        }
        return (false, 0);
    }

    /// @notice Checks if a given address is in the `privilegedShareholders` array.
    /// @param _addr The address to check.
    /// @return bool Returns `true` if the given address is a privileged shareholder.
    function _isAddrPrivileged(address _addr) internal view returns (bool) {
        if (privilegedShareholdersIndex[_addr] != 0) {
            return true;
        }
        return false;
    }

    /// @notice Removes an `Asset_Structs.Offer` from the `offers` array.
    /// @param _index The index of the `Asset_Structs.Offer` in the `offers` array.
    /// @param _addr The address of the offer's owner.
    function _removeOffer(uint24 _index, address _addr) internal {
        uint256 _offersLength = offers.length;
        require(_index < _offersLength, "Index out of bounds");
        if (_offersLength != 2) {
            address lastOfferAddr = offers[_offersLength - 1].from;
            offers[_index] = offers[_offersLength - 1];
            offersIndex[lastOfferAddr] = _index;
        }
        offers.pop();
        offersIndex[_addr] = 0;
    }

    /// @notice Extends the capabilities of the `buyShares` function by updating the amount of shares, balances, and collected fees, and by paying a commission to the protocol owner.
    /// @param _date The date of the last `Asset_Structs.License` payment.
    /// @param _from The address of the owner of `Asset_Structs.Offer`.
    /// @param _amount The number of shares bought by the user.
    /// @param _tempOffer A copy of `Asset_Structs.Offer`.
    /// @param _etherToPayPreviousOwner The total amount of Ether to be credited to the balance of the offer owner for their shares.
    /// @param _etherToPayProtocolOwner The total amount of Ether to be sent to the protocol owner.
    /// @param _etherToPayPrivileged The total amount of Ether to be added to `aggregatedPrivilegedFees` as a commission for privileged shareholders.
    /// @return newShares The updated number of shares the user owns after the purchase.
    function _redistributeShares(
        uint48 _date,
        address _from,
        uint24 _amount,
        Asset_Structs.Offer memory _tempOffer,
        uint256 _etherToPayPreviousOwner,
        uint256 _etherToPayProtocolOwner,
        uint256 _etherToPayPrivileged
    ) internal returns (uint24 newShares) {
        shares[_from] -= _amount;
        _tempOffer.amount -= _amount;
        uint24 _buyerCurrentShares = uint24(shares[msg.sender]);
        newShares = _buyerCurrentShares + _amount;
        if (_buyerCurrentShares == 0) {
            lastDayOfDividendPayment[msg.sender] = _date;
        }
        shares[msg.sender] += _amount;
        if (_tempOffer.amount == 0) {
            _removeOffer(offersIndex[_from], _from);
        } else {
            offers[offersIndex[_from]] = _tempOffer;
        }
        balances[_from] += _etherToPayPreviousOwner;
        aggregatedPrivilegedFees += _etherToPayPrivileged;
        bool _isSenderPrivileged = (privilegedShareholdersIndex[msg.sender] !=
            0);
        bool _isOffererPrivileged = (privilegedShareholdersIndex[_from] != 0);
        if (_isSenderPrivileged != _isOffererPrivileged) {
            if (_isOffererPrivileged) {
                sharesInPrivilegedHands -= _amount;
                // Mint tokens for initial users!
                _sendTokenMintingOrder(msg.sender, _from, _amount);
            } else {
                sharesInPrivilegedHands += _amount;
            }
        }
        // @todo In mainent phase use PROTOCOL_OWNER constant as e.g `Safe` address of the protocol.
        // (bool result, ) = PROTOCOL_OWNER.call{value: _etherToPayProtocolOwner}("");
        (bool result, ) = assetFactoryAddr.call{
            value: _etherToPayProtocolOwner
        }("");
        require(result);
    }

    /// @notice Sends the token minting order to the Bananashares Token contract through the `assetFactoryAddr`.
    /// @param _tokenReceiver_1 The address of the token receiver (regular)
    /// @param _tokenReceiver_2 The address of the token receiver (privileged)
    /// @param _numberOfTokens The number of tokens to be minted for each receiver.
    function _sendTokenMintingOrder(
        address _tokenReceiver_1,
        address _tokenReceiver_2,
        uint256 _numberOfTokens
    ) internal {
        uint256 _minted_1;
        uint256 _minted_2;
        (_minted_1, _minted_2) = IAssetFactory_write(assetFactoryAddr)
            .sendTokenMintingOrder(
                _tokenReceiver_1,
                _tokenReceiver_2,
                _numberOfTokens,
                govTokensMinted
            );

        if (_minted_2 > 0) {
            lastBlockGovTokenMinted[_tokenReceiver_2] = Time.blockNumber();
        }

        if ((_minted_1 + _minted_2) > 0) {
            Time.blockNumber();
            govTokensMinted += (_minted_1 + _minted_2);
            emit GovTokensMinted(
                _tokenReceiver_1,
                _tokenReceiver_2,
                _minted_1,
                _minted_2
            );
        }
    }

    /// @notice Creates a new `Asset_Structs.Offer` for a regular user after purchasing shares.
    /// @param _newSharesAmount The number of shares in the new `Asset_Structs.Offer`.
    /// @param _sellLimit The base price per share in the new `Asset_Structs.Offer`.
    function _createNewOffer(
        uint24 _newSharesAmount,
        uint96 _sellLimit,
        Asset_Structs.GlobalSettings memory _globalSettings
    ) internal {
        Asset_Structs.Offer memory _newOffer = Asset_Structs.Offer({
            from: msg.sender,
            value: _sellLimit,
            privilegedFee: uint96(
                (_sellLimit / BIPS) * _globalSettings.commission_for_privileged
            ),
            ownerFee: uint96(
                (_sellLimit / BIPS) * _globalSettings.commission_for_protocol
            ),
            amount: _newSharesAmount
        });
        offers.push(_newOffer);
        offersIndex[msg.sender] = uint24((offers.length - 1));
    }

    /// @notice Creates a new `Asset_Structs.Offer` for a privileged shareholder.
    /// @param _amount The number of shares to buy in the `Asset_Structs.Offer`.
    /// @param _price The price per share in the `Asset_Structs.Offer`.
    function makeSellOffer(uint24 _amount, uint96 _price) external onlyProxy {
        Asset_Structs.GlobalSettings
            memory _globalSettings = IAssetFactory_read(assetFactoryAddr)
                .getGlobalSettings();
        require(_isAddrPrivileged(msg.sender), "Not privileged Shareholder");
        require(_amount > 0, "Amount 0");
        require(_amount <= shares[msg.sender], "Not enough shares");
        require(_price >= _globalSettings.min_sell_offer, "Price too small");
        (bool _doesYourOfferExist, uint24 _pos) = _checkIfOfferIsAlreadyCreated(
            msg.sender
        );
        if (_doesYourOfferExist) {
            _removeOffer(_pos, msg.sender);
        }

        Asset_Structs.Offer memory _offer = Asset_Structs.Offer({
            from: msg.sender,
            value: _price,
            ownerFee: uint96(
                (_price / BIPS) * _globalSettings.commission_for_protocol
            ),
            privilegedFee: 0,
            amount: _amount
        });
        offers.push(_offer);
        offersIndex[msg.sender] = uint24((offers.length - 1));
        emit SellOfferPut(
            msg.sender,
            _amount,
            uint256(_offer.value) +
                uint256(_offer.ownerFee) +
                uint256(_offer.privilegedFee)
        );
    }

    /// @notice Removes the `Asset_Structs.Offer` from the `offers` array.
    function cancelOffer() external onlyProxy {
        require(_isAddrPrivileged(msg.sender), "Not privileged");
        (bool _doesYourOfferExist, uint24 _pos) = _checkIfOfferIsAlreadyCreated(
            msg.sender
        );
        require(_doesYourOfferExist, "No offer");

        if (_doesYourOfferExist) {
            _removeOffer(_pos, msg.sender);
            emit OfferCancelled(msg.sender);
        }
    }

    /// @notice Transfers ownership of the specified number of shares for the price set in the `Asset_Structs.Offer`.If the buyer is not a privileged shareholder, a new `Asset_Structs.Offer` is created.
    /// @param _from The address of the `Asset_Structs.Offer` owner from whom the caller intends to purchase shares.
    /// @param _amount The number of shares to purchase.
    /// @param _sellLimit If the caller is not a privileged shareholder, this value, plus the protocol owner's fee and the privileged shareholders' fee, determines the price of the new `Asset_Structs.Offer` created with `_amount` of purchased shares and the shares already owned by the caller.
    function buyShares(
        address _from,
        uint24 _amount,
        uint96 _sellLimit
    ) external payable onlyProxy {
        // uint256 gasStart = gasleft();
        Asset_Structs.GlobalSettings
            memory _globalSettings = IAssetFactory_read(assetFactoryAddr)
                .getGlobalSettings();
        Asset_Structs.Offer memory _tempOffer = offers[offersIndex[_from]];
        require(_tempOffer.amount != 0, "Offer 0");
        require(_amount != 0, "Amount 0");
        require(_amount <= _tempOffer.amount, "Amount exceeds available value");
        require(
            _sellLimit >= _globalSettings.min_sell_offer,
            "SellLimit too small"
        );
        uint256 _paymentsLength = payments.length;
        require(
            paymentIndex[lastDayOfDividendPayment[_from]] ==
                (_paymentsLength - 1),
            "Offeror has dividend to pay"
        );
        if (shares[msg.sender] != 0) {
            require(
                paymentIndex[lastDayOfDividendPayment[msg.sender]] ==
                    (_paymentsLength - 1),
                "Buyer has dividend to pay"
            );
        }
        if ((privilegedShareholdersIndex[_from] != 0)) {
            require(
                aggregatedPrivilegedFees == 0,
                "Privileged Offeror has fees to collect"
            );
        }
        if ((privilegedShareholdersIndex[msg.sender] != 0)) {
            require(
                aggregatedPrivilegedFees == 0,
                "Privileged Buyer has fees to collect"
            );
        }
        require(
            (uint256(_amount) *
                uint256(_tempOffer.value) +
                uint256(_amount) *
                uint256(_tempOffer.ownerFee) +
                uint256(_amount) *
                uint256(_tempOffer.privilegedFee)) == msg.value,
            "Wrong ether amount"
        );

        uint24 _newSharesAmount = _redistributeShares(
            payments[_paymentsLength - 1].date,
            _from,
            _amount,
            _tempOffer,
            (_amount * _tempOffer.value), // etherToPayPreviousOwner
            (_amount * _tempOffer.ownerFee), // _etherToPayProtocolOwner
            (_amount * _tempOffer.privilegedFee) // _etherToPayPrivileged
        );

        if (privilegedShareholdersIndex[msg.sender] == 0) {
            (
                bool _doesYourOfferExist,
                uint24 _pos
            ) = _checkIfOfferIsAlreadyCreated(msg.sender);
            if (_doesYourOfferExist) {
                _removeOffer(_pos, msg.sender);
            }
            _createNewOffer(_newSharesAmount, _sellLimit, _globalSettings);
        }

        emit SharesBought(
            _from,
            _tempOffer.value + _tempOffer.ownerFee + _tempOffer.privilegedFee,
            msg.sender,
            _amount
        );
        // emit GasUsage(gasStart - gasleft());
    }
    /// @notice Distributes the value of `aggregatedPrivilegedFees` among privileged shareholders in proportion to the number of shares each holds. Finally, resets `aggregatedPrivilegedFees` to zero.
    function payEarndFeesToAllPrivileged() external onlyProxy {
        uint256 _sharesInPrivilegedHands = sharesInPrivilegedHands;
        require(_sharesInPrivilegedHands != 0, "priv shares 0");
        // uint256 gasBigStart = gasleft();
        // uint256 gasStart = gasleft();
        // console2.log("gasStart", gasStart);

        uint256 _aggregatedPrivilegedFees = aggregatedPrivilegedFees;
        /// @dev numberOfPrivileged - the number of priviledged shareholders is always +1 more because address(0) at the position 0.
        uint256 _numberOfPrivileged = privilegedShareholders.length;
        uint256 _amountToPay;
        uint256 _reminder;

        // emit GasUsage(gasStart - gasleft());
        // uint256 gasBeforeLoop = gasleft();
        // console2.log("gas consumed Before the loop", gasBeforeLoop);

        for (uint256 i = 1; i < _numberOfPrivileged; i++) {
            // gasStart = gasleft();

            address shareHolder = privilegedShareholders[i];
            _amountToPay =
                (BIPS * _aggregatedPrivilegedFees * shares[shareHolder]) /
                _sharesInPrivilegedHands;
            _reminder += _amountToPay % BIPS;
            if (i == _numberOfPrivileged - 1) {
                _amountToPay = (_amountToPay + _reminder);
            }
            _amountToPay = _amountToPay / BIPS;
            balances[shareHolder] += _amountToPay;

            // emit GasUsage(gasStart - gasleft());
            // console2.log("iteration", i);
            // console2.log("gas consumed in one iteration", gasStart - gasleft());

            if (gasleft() < GAS_LIMIT_FEES && (i < _numberOfPrivileged - 1)) {
                // console2.log("gas left", gasleft());
                emit GasLimitTooLow();
                revert("Not enough gas");
            }
        }
        // console2.log("gas consumed In the whole loop", gasBeforeLoop - gasleft());
        // gasStart = gasleft();

        aggregatedPrivilegedFees = 0;
        emit EarndFeesToAllPrivileged(_aggregatedPrivilegedFees);

        // emit GasUsage(gasStart - gasleft());
        // emit GasUsage(gasBigStart - gasleft());
        // console2.log("gas consumed After loop", gasStart - gasleft());
        // console2.log("gas consumed All", gasBigStart - gasleft());
        // console2.log("gas left", gasleft());
    }

    /// @notice Withdraws the specified amount of Ether from the caller's balance.
    /// @param _amount The amount of Ether to withdraw.
    function withdraw(uint256 _amount) external onlyProxy nonReentrant {
        // Flashloan prevention
        uint48 _lastBlock = lastBlockGovTokenMinted[msg.sender];
        if (
            _lastBlock > 0 &&
            Time.blockNumber() <= _lastBlock + WITHDRAW_LOCK_PERIOD
        ) {
            revert WithdrawLockActive();
        }
        // Standard withdraw
        require(_amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        emit Withdrawal(msg.sender, _amount);
    }

    /// @notice Changes the price per share in the `Asset_Structs.Offer`. It can be called only by the owner of the `Asset_Structs.Offer`.
    /// @param _newLimit The new price per share in the `Asset_Structs.Offer`.
    function changeOffer(uint96 _newLimit) external onlyProxy {
        Asset_Structs.GlobalSettings
            memory _globalSettings = IAssetFactory_read(assetFactoryAddr)
                .getGlobalSettings();
        uint24 _offersIndex = offersIndex[msg.sender];
        require(_offersIndex != 0, "No offers");
        require(
            _newLimit >= _globalSettings.min_sell_offer,
            "SellLimit too small"
        );
        uint96 _newOwnerFee = uint96(
            (_newLimit / BIPS) * _globalSettings.commission_for_protocol
        );
        uint96 _newPrivilegedFee = uint96(
            (_newLimit / BIPS) * _globalSettings.commission_for_privileged
        );
        Asset_Structs.Offer storage _offer = offers[_offersIndex];
        if (_offer.privilegedFee == 0) {
            _newPrivilegedFee = 0;
        }
        _offer.value = _newLimit;
        _offer.ownerFee = _newOwnerFee;
        _offer.privilegedFee = _newPrivilegedFee;
        emit OfferChanged(
            msg.sender,
            uint256(_offer.value) +
                uint256(_offer.ownerFee) +
                uint256(_offer.privilegedFee)
        );
    }
    /// @notice Creates a new `Asset_Structs.License`.
    /// @param _licenseHash The hash of the license.
    /// @param _value The amount of Ether that needs to be paid to purchase this license.
    // @todo Is min value for _value necessary.
    function putNewLicense(
        bytes32 _licenseHash,
        uint224 _value
    ) external onlyProxy {
        require(_isAddrPrivileged(msg.sender), "Not privileged");
        require(licensesIndex[_licenseHash] == 0, "This license exists");
        Asset_Structs.License memory _newLicense = Asset_Structs.License({
            active: true,
            licenseHash: _licenseHash,
            value: _value
        });
        licenses.push(_newLicense);
        licensesIndex[_licenseHash] = (licenses.length - 1);
        emit NewLicenseCreated(msg.sender);
    }

    /// @notice Changes the status in the `Asset_Structs.License`. Setting the `active` parameter to `true` enables the purchase of this license.
    /// @param _licenseHash The hash of the license.
    /// @param _activate A boolean parameter that changes the license's status.
    function activateLicense(
        bytes32 _licenseHash,
        bool _activate
    ) external onlyProxy {
        require(_isAddrPrivileged(msg.sender), "Not privileged");
        require(licensesIndex[_licenseHash] != 0, "No such license");
        licenses[licensesIndex[_licenseHash]].active = _activate;
        if (_activate) {
            emit LicenseActivated(msg.sender, _licenseHash);
        } else {
            emit LicenseDeactivated(msg.sender, _licenseHash);
        }
    }

    /// @notice Accepts the amount of Ether specified in an `Asset_Structs.License`, creates a new `Asset_Structs.Payment` and stores it in the `payments` array.
    /// @param _licenseHash The `hash` value from the `Asset_Structs.License`.
    function signLicense(bytes32 _licenseHash) external payable onlyProxy {
        uint256 _licensesIndex = licensesIndex[_licenseHash];
        require(_licensesIndex != 0, "Doesn't exist");
        Asset_Structs.License memory _tempLicense = licenses[_licensesIndex];
        require(_tempLicense.active == true, "Not active");
        require(_tempLicense.value == msg.value, "Not enough");

        uint256 _paymentsLength = payments.length;
        uint48 _lastTimestamp = payments[_paymentsLength - 1].date;
        uint48 _nextTimestamp = uint48(block.timestamp);
        /// @dev Prevent from placing two payments with the same timestamp.
        if (_lastTimestamp >= _nextTimestamp) {
            uint48 _diff = _lastTimestamp - _nextTimestamp;
            _nextTimestamp += (_diff + 1);
        }

        Asset_Structs.Payment memory _newPayment;
        _newPayment.licenseHash = _licenseHash;
        _newPayment.paymentValue = uint224(msg.value);
        _newPayment.date = _nextTimestamp;
        _newPayment.payer = msg.sender;

        paymentIndex[_newPayment.date] = (_paymentsLength);
        payments.push(_newPayment);
        emit NewPayment(msg.sender, _licenseHash);
    }

    /// @notice Iterates through all eligible payments in the `payments` array for a given address and adds the appropriate portion of each `Asset_Structs.Payment` to the address's balance.
    /// @param _addr The address for which eligible payment portions are collected.
    function payDividend(address _addr) external onlyProxy {
        // uint256 gasStart = gasleft();
        // uint256 gasBigStart = gasleft();

        uint24 _numberOfShares = shares[_addr];
        require(_numberOfShares != 0, "Not a shareholder");
        uint256 _paymentsLength = payments.length;
        require(_paymentsLength - 1 > 0, "No payments");

        uint48 _lastDividendDate = lastDayOfDividendPayment[_addr];
        uint256 _tempPaymentIndex = paymentIndex[_lastDividendDate];

        require((_paymentsLength - 1) > _tempPaymentIndex, "No dividends");

        uint256 _dividendToPay;
        uint48 _newDividendDate;
        bool _paidOnlyPartly = false;

        // emit GasUsage(gasStart - gasleft());

        for (uint256 i = (_tempPaymentIndex + 1); i < _paymentsLength; i++) {
            // gasStart = gasleft();

            Asset_Structs.Payment memory _tempPayment = payments[i];
            _dividendToPay +=
                (_tempPayment.paymentValue * _numberOfShares) /
                TOTAL_SUPPLY;
            _newDividendDate = _tempPayment.date;

            // emit GasUsage(gasStart - gasleft());
            // emit GasUsage(gasleft());
            // emit GasUsage(0);

            if ((gasleft() < GAS_LIMIT) && (i < _paymentsLength - 1)) {
                // gasStart = gasleft();
                _paidOnlyPartly = true;
                emit DividendPaidOnlyPartly(
                    _addr,
                    _dividendToPay,
                    (_paymentsLength - 1 - i)
                );
                // emit GasUsage(gasStart - gasleft());
                break;
            }
        }
        // gasStart = gasleft();
        lastDayOfDividendPayment[_addr] = _newDividendDate;
        balances[_addr] += _dividendToPay;
        if (!_paidOnlyPartly) {
            // emit GasUsage(gasleft());
            emit DividendPaid(
                _addr,
                _dividendToPay,
                (_paymentsLength - 1 - _tempPaymentIndex)
            );
            // emit GasUsage(gasleft());
        }
        // emit GasUsage(gasStart - gasleft());
        // emit GasUsage(gasBigStart - gasleft());
    }
}
