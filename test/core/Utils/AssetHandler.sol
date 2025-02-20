//SPDX-License-Identifier: NONE
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/Test.sol";
import {IAssetInstance} from "../../../src/core/util/IAssetInstance.sol";
import {AssetInstanceEvents} from "../../../src/core/util/AssetInstanceEvents.sol";
import {Asset_Structs} from "../../../src/core/util/AssetInstanceStructs.sol";
import {Globals} from "./Globals.sol";

/// @title The base handler for all statefull and stateless fuzzing tests.
/// @notice Values that can be modified before testing: look at Globals.sol

contract AssetHandler is Test, Globals, AssetInstanceEvents {
    /// @dev Asset contract handled by this AssetHandler.
    IAssetInstance internal asset;
    ///////////////////////////////////////
    /// @dev temporary function params ////
    ///////////////////////////////////////
    /// @dev An address that becomes msg.sender in called transaction.
    address internal currentActor;
    /// @dev The amount of shares that is send as param in makeSellOffer().
    uint24 internal offerAmount;
    /// @dev The price for a share that is send as param in makeSellOffer().
    uint96 internal offerPrice;
    /// @dev The amount of shares that is send as param in buyShares().
    uint24 internal buyAmount;
    /// @dev The price for a share that is send as param in buyShares() or changeOffer().
    uint96 internal sellPrice;
    /// @dev The msgValue for a share that is send as param in asset.buyShares{value: msgValue * buyAmount}().
    uint256 internal msgValuePerShare;
    /// @dev The value that is send as param in the withdraw() function.
    uint256 internal withdrawAmount = 0;
    /// @dev Specifes whether the block number is moved past `WITHDRAW_LOCK_PERIOD`.
    bool internal isBlockNumberCorrect = false;
    /// @dev The value that is send as param in the putNewLicense() function.
    bytes32 internal licenceHashInput = 0;
    /// @dev The value that is send as msg.value in the signLicense() function.
    uint224 internal licenceValue = 0;
    /// @dev The value that is send as _addr param in the payDividend() function.
    address internal dividendReceiver = address(0);

    ///////////////////////////////
    /// @dev 'ghost variables' ////
    ///////////////////////////////
    /// @dev Tracks the indexes of offers owners in the offererAddresses array.
    mapping(address => uint256) internal offererIndex;
    /// @dev An array of all addresses that have created any offer.
    /// @dev Asset contract instead of this has Offer[] so asset.getOffersLength() == getOffererAddressesLength().
    address[] internal offererAddresses;
    /// @dev Tracks the indexes of offers owners that are not pvileged shareholders in the normalShareholderAddresses array.
    mapping(address => uint256) internal normalShareholderIndex;
    /// @dev An array of all addresses that have created any offer that are not pvileged shareholders.
    address[] internal normalShareholderAddresses;
    /// @dev Tracks the indexes of all shareholders in the allShareholderAddresses array.
    mapping(address => uint256) internal allShareholderIndex;
    /// @dev An array of all shareholders no matter if they are privileged or normal.
    address[] internal allShareholderAddresses;
    /// @dev Tracks numer of shares in Normal shareholders hands.
    /// @dev Asset contract instead of this has sharesInPrivilegedHands.
    uint24 internal sharesInNormalHands = 0;
    /// @dev The sum of fees paid to the protocol for shares trading.
    uint256 internal protocolGain = 0;
    /// @dev Sum of Ether transferred to the protocol. Its the sum of ether as msg.value in buyShares() and signLicense() MINUS the sum of ether as msg.value in withdraw() and protocolGain
    uint256 internal assetContractGain = 0;

    /// @notice Takes random seed to set offerAmount in specified range.
    modifier boundAmountInOffer(uint256 _amountSeed) {
        if (asset.getShares(currentActor) >= MIN_AMOUNT_IN_OFFER) {
            offerAmount = uint24(
                bound(
                    _amountSeed,
                    MIN_AMOUNT_IN_OFFER,
                    asset.getShares(currentActor)
                )
            );
        }

        _;
        offerAmount = 0;
    }

    /// @notice Takes random seed to set offerPrice in specified range.
    modifier boundPriceInOffer(uint256 _priceSeed) {
        offerPrice = uint96(
            bound(_priceSeed, uint256(MIN_SELL_OFFER), uint256(MAX_SELL_OFFER))
        );
        _;
        offerPrice = 0;
    }

    /// @notice Takes random seed to set buyAmount in specified range.
    /// @param _howOftenAmountCorrectSeed describes how often buyAmount is set correctly on the basis of the offer, accordingly to HOW_OFTEN_CORRECT_AMOUNT
    modifier boundBuyAmount(
        address _from,
        uint256 _amountSeed,
        uint8 _howOftenAmountCorrectSeed
    ) {
        if (_howOftenAmountCorrectSeed <= THRESHOLD_AMOUNT) {
            // require(asset.getOffersIndex(_from) != 0, "boundBuyAmount");
            if (asset.getOffersIndex(_from) != 0) {
                buyAmount = uint24(
                    bound(
                        _amountSeed,
                        MIN_AMOUNT_IN_OFFER,
                        asset.getOffer(asset.getOffersIndex(_from)).amount
                    )
                );
            } else {
                buyAmount = uint24(bound(_amountSeed, 0, type(uint24).max));
            }
        } else {
            buyAmount = uint24(bound(_amountSeed, 0, type(uint24).max));
        }
        _;
        buyAmount = 0;
    }

    /// @notice Takes random seed to set msgValuePerShare in specified range.
    /// @param _from address of the offer owner.
    /// @param _howOftenCorrectSeed describes how often msgValue is set correctly on the basis of the offer, accordingly to HOW_OFTEN_CORRECT_MSGVALUE
    modifier boundMsgValuePerShare(
        uint256 _msgValueSeed,
        uint8 _howOftenCorrectSeed,
        address _from
    ) {
        bool notNecesaryCorrect = false;
        if (_howOftenCorrectSeed <= THRESHOLD_MSGVALUE) {
            // require(asset.getOffersIndex(_from) != 0, "boundMsgValuePerShare::1");
            if (asset.getOffersIndex(_from) != 0) {
                (
                    uint24 _amount,
                    uint256 _pricePerShare,
                    uint256 _ownerFee,
                    uint256 _privilegedFee
                ) = _getDataToBuy(0, _from);

                msgValuePerShare = _pricePerShare;
                if (currentActor != address(0)) {
                    if (msgValuePerShare * buyAmount > currentActor.balance) {
                        buyAmount = uint24(
                            currentActor.balance / msgValuePerShare
                        );
                    }
                }
            } else {
                notNecesaryCorrect = true;
            }
        } else {
            notNecesaryCorrect = true;
        }
        if (notNecesaryCorrect) {
            if (currentActor != address(0) && buyAmount != 0) {
                msgValuePerShare = uint96(
                    bound(
                        _msgValueSeed,
                        0,
                        currentActor.balance / uint256(buyAmount)
                    )
                );
            } else {
                msgValuePerShare = uint96(
                    bound(_msgValueSeed, 0, type(uint256).max)
                );
            }
        }
        _;
        msgValuePerShare = 0;
    }

    /// @notice Takes random seed to set sellPrice in specified range.
    modifier boundSellPrice(
        uint8 _howOftenCorrectSeed,
        uint256 _sellPriceSeed
    ) {
        require(currentActor != address(0), "boundSellPrice");
        if (_howOftenCorrectSeed <= THRESHOLD_SELLLIMIT) {
            sellPrice = uint96(
                bound(
                    _sellPriceSeed,
                    uint256(MIN_SELL_OFFER),
                    uint256(MAX_SELL_OFFER)
                )
            );
        } else {
            sellPrice = uint96(
                bound(_sellPriceSeed, 0, uint256(MAX_SELL_OFFER))
            );
        }
        _;
        sellPrice = 0;
    }

    /// @notice Sets specified currentActor.
    modifier useActor(address _actor) {
        currentActor = _actor;
        vm.startPrank(_actor);
        _dealEtherToActor();
        _;
        vm.stopPrank();
    }

    /// @notice Takes random seed to set currentActor.
    /// @dev currentActor is choosen from the privilegedShareholders array from Asset contract.
    modifier usePrivilegedShareholder(uint256 _actorIndexSeed) {
        address[] memory _privShareholders = asset.getAllPrivShareholders();
        currentActor = _privShareholders[
            bound(_actorIndexSeed, 1, _privShareholders.length - 1)
        ];
        vm.startPrank(currentActor);
        _dealEtherToActor();
        _;
        vm.stopPrank();
    }

    /// @notice Takes random seed to set currentActor.
    /// @dev currentActor can be a privilegd or normal shareholder or 'fresh' user without any shares.
    /// @dev Propability of which type of user is choosen is calculated on the basis of PRIVILEGED_ALL_RATIO and NORMAL_FRESH_RATIO.
    /// @param _whichActorSeed radomly selects if msg.sender will be privileged shareholder, normal shareholder, or fresh user
    modifier usePrivShareholerOrRandomUser(
        uint8 _whichActorSeed,
        uint256 _actorIndexSeed
    ) {
        if (_whichActorSeed <= THRESHOLD_1) {
            // PRIVILEGED % probability within ALL
            address[] memory _privShareholders = asset.getAllPrivShareholders();
            currentActor = _privShareholders[
                bound(_whichActorSeed, 1, _privShareholders.length - 1)
            ];
            vm.startPrank(currentActor);
            _dealEtherToActor();
            _;
            vm.stopPrank();
        } else {
            if (
                (_whichActorSeed - THRESHOLD_1) <= THRESHOLD_2 &&
                getNormalShareholderAddressesLength() > 0
            ) {
                // NORMAL % probability within NORMAL AND FRESH
                currentActor = normalShareholderAddresses[
                    bound(
                        _whichActorSeed,
                        1,
                        getNormalShareholderAddressesLength()
                    )
                ];
                vm.startPrank(currentActor);
                _dealEtherToActor();
                _;
                vm.stopPrank();
            } else {
                currentActor = makeAddr(
                    _uintToStringFull(uint64(_actorIndexSeed))
                );
                // uint x = 1;
                // while (asset.getShares(currentActor) != 0) {
                //     if (_actorIndexSeed > 0) {
                //         _actorIndexSeed -= x;
                //     } else {
                //         _actorIndexSeed = type(uint256).max;
                //     }
                //     x += 1;
                //     currentActor = makeAddr(
                //         _uintToStringFull(uint64(_actorIndexSeed))
                //     );
                // }
                vm.startPrank(currentActor);
                _dealEtherToActor();
                _;
                vm.stopPrank();
            }
        }
    }

    /// @notice Takes random seed to set offerAmount in specified range.
    modifier boundWithdrawAmount(uint256 _withdrawSeed) {
        withdrawAmount = uint256(
            bound(_withdrawSeed, 0, asset.getBalance(currentActor))
        );
        _;
        withdrawAmount = 0;
    }

    /// @notice Takes random seed to set offerAmount in specified range.
    modifier boundWithdrawAmountFullRange(
        uint8 _howOftenCorrectSeed,
        uint256 _withdrawSeed
    ) {
        if (_howOftenCorrectSeed <= THRESHOLD_WITHDRAW) {
            withdrawAmount = uint256(
                bound(_withdrawSeed, 0, asset.getBalance(currentActor))
            );
        } else {
            withdrawAmount = uint256(
                bound(
                    _withdrawSeed,
                    asset.getBalance(currentActor) + 1,
                    type(uint256).max
                )
            );
        }
        _;
        withdrawAmount = 0;
    }

    /// @notice Takes random seed to set offerAmount in specified range.
    modifier boundBlockNumber(uint8 _howOftenCorrectSeed, uint256 _blockSeed) {
        uint256 _newBlockNumber;
        if (_howOftenCorrectSeed <= THRESHOLD_BLOCK_NR_MOVED) {
            isBlockNumberCorrect = true;
            vm.roll(WITHDRAW_LOCK_PERIOD + 2);
        } else {
            _newBlockNumber = uint256(
                bound(_blockSeed, 1, WITHDRAW_LOCK_PERIOD)
            );
            vm.roll(_newBlockNumber);
        }
        _;
        vm.roll(1);
        isBlockNumberCorrect = false;
    }

    /// @notice Takes random seed to set licenceHashInput.
    /// @param _howOftenCreatedLicense describes how often licenceHashInput is set as a new hash in Asset contract, accordingly to HOW_OFTEN_CORRECT_AMOUNT
    modifier boundLicenseHashInput(
        uint8 _howOftenCreatedLicense,
        uint256 _licenseSeed
    ) {
        uint256 _numberOfLicenses = asset.getLicensesLength();
        if (
            _howOftenCreatedLicense <= THRESHOLD_CREATED_LICENSE &&
            _numberOfLicenses > 0
        ) {
            uint256 _index = bound(_licenseSeed, 1, _numberOfLicenses);
            licenceHashInput = asset.getLicense(_index).licenseHash;
        } else {
            licenceHashInput = keccak256(abi.encodePacked(_licenseSeed));
        }
        _;
        licenceHashInput = 0;
    }

    /// @notice Takes random seed to set licenceValue.
    /// @param _howOftenCorrectValue describes how often licenceValue is set on the basis of correct license hash, accordingly to HOW_OFTEN_CORRECT_LICENSE_VALUE
    modifier boundLicenceValue(
        uint8 _howOftenCorrectValue,
        uint256 _valueSeed
    ) {
        require(licenceHashInput != 0, "boundLicenceValue::1");
        if (
            _howOftenCorrectValue <= THRESHOLD_LICENSE_VALUE &&
            asset.getLicensesIndex(licenceHashInput) != 0 &&
            uint256(
                asset.getLicense(asset.getLicensesIndex(licenceHashInput)).value
            ) <=
            currentActor.balance
        ) {
            licenceValue = asset
                .getLicense(asset.getLicensesIndex(licenceHashInput))
                .value;
        } else {
            licenceValue = uint224(bound(_valueSeed, 0, currentActor.balance));
        }
        _;
        licenceValue = 0;
    }

    /// @notice Takes random seed to set dividendReceiver.
    /// @param _howOftenCorrectAddress describes how often _addr set as a param in payDividend() is entitled to the dividend , accordingly to HOW_OFTEN_CORRECT_DIVIDEND_RECEIVER
    modifier boundDividendReceiver(
        uint8 _howOftenCorrectAddress,
        uint256 _actorIndexSeed
    ) {
        if (_howOftenCorrectAddress <= THRESHOLD_DIVIDEND_RECEIVER) {
            address[] memory _shareholders = getAllShareholders();
            dividendReceiver = _shareholders[
                bound(_actorIndexSeed, 1, _shareholders.length - 1)
            ];
        } else {
            dividendReceiver = makeAddr(
                _uintToStringFull(uint64(_actorIndexSeed))
            );
        }
        _;
        dividendReceiver = address(0);
    }

    /// @dev address(0) is pushed so offererIndex and normalShareholderIndex can be used to find proper index and if return 0 it means such address cannot be found in offererAddresses and normalShareholderAddresses arrays.
    constructor(address _assetAddr) {
        asset = IAssetInstance(_assetAddr);
        offererAddresses.push(address(0));
        normalShareholderAddresses.push(address(0));
        allShareholderAddresses = asset.getAllPrivShareholders();
        setUpAllShareholderAddresses();
    }

    function setUpAllShareholderAddresses() internal {
        for (uint i = 0; i <= getAllShareholderAddressesLength(); i++) {
            allShareholderIndex[allShareholderAddresses[i]] = i;
        }
    }

    /// @notice Returns 'ghost' current currentActor
    function getCurrentActor() public view returns (address) {
        return currentActor;
    }

    /// @notice Returns 'ghost' sharesInNormalHands.
    function getSharesInNormalHands() public view returns (uint256) {
        return sharesInNormalHands;
    }

    /// @notice Returns 'ghost' balance of AssetFactory.
    function getProtocolGain() public view returns (uint256) {
        return protocolGain;
    }

    /// @notice Returns 'ghost' assetContractGain.
    function getAssetContractGain() public view returns (uint256) {
        return assetContractGain;
    }

    /// @notice Returns 'ghost' number of offers.
    function getOffererAddressesLength() public view returns (uint256) {
        return (offererAddresses.length - 1);
    }

    /// @notice Returns 'ghost' number of normal shareholders.
    function getNormalShareholderAddressesLength()
        public
        view
        returns (uint256)
    {
        return (normalShareholderAddresses.length - 1);
    }

    /// @notice Returns 'ghost' list of normal shareholders.
    function getNormalShareholders()
        public
        view
        returns (address[] memory _normalShareholders)
    {
        _normalShareholders = normalShareholderAddresses;
    }

    /// @notice Returns 'ghost' number of all shareholders.
    function getAllShareholderAddressesLength() public view returns (uint256) {
        return (allShareholderAddresses.length - 1);
    }

    /// @notice Returns 'ghost' list of all shareholders.
    function getAllShareholders()
        public
        view
        returns (address[] memory _allShareholders)
    {
        _allShareholders = allShareholderAddresses;
    }

    /// @notice Makes smg.sender balance = 0.
    function _resetEtherToActor() internal {
        require(currentActor != address(0));
        vm.deal(currentActor, 0);
    }

    /// @notice Makes smg.sender at least balance = ETHER_FOR_ACTOR.
    function _dealEtherToActor() internal {
        require(currentActor != address(0));
        if (currentActor.balance < ETHER_FOR_ACTOR) {
            vm.deal(currentActor, ETHER_FOR_ACTOR);
        }
    }

    /// @notice Adds an address to the offererAddresses array and saves its index in this array.
    function _addOffererAddress(address _addr) internal {
        require(offererIndex[_addr] == 0, "_addr already in offererAddresses");
        offererIndex[_addr] = getOffererAddressesLength() + 1;
        offererAddresses.push(_addr);
    }

    /// @notice Removes an address from the offererAddresses array and resets its index in this array.
    function _removeOffererAddress(address _addr) internal {
        uint256 _index = offererIndex[_addr];
        if (
            getOffererAddressesLength() != 1 &&
            _index != getOffererAddressesLength()
        ) {
            address lastOffererAddr = offererAddresses[
                getOffererAddressesLength()
            ];
            offererAddresses[_index] = offererAddresses[
                getOffererAddressesLength()
            ];
            offererIndex[lastOffererAddr] = _index;
        }
        offererAddresses.pop();
        offererIndex[_addr] = 0;
    }

    /// @notice Adds an address to the normalShareholderAddresses array and saves its index in this array.
    function _addNormalShareholderAddresses(address _addr) internal {
        require(
            normalShareholderIndex[_addr] == 0,
            "_addr already in normalShareholderAddresses"
        );
        normalShareholderIndex[_addr] =
            getNormalShareholderAddressesLength() +
            1;
        normalShareholderAddresses.push(_addr);
    }

    /// @notice Removes an address from the normalShareholderAddresses array and resets its index in this array.
    function _removeNormalShareholderAddresses(address _addr) internal {
        uint256 _index = normalShareholderIndex[_addr];
        if (
            getNormalShareholderAddressesLength() != 1 &&
            _index != getNormalShareholderAddressesLength()
        ) {
            address lastOffererAddr = normalShareholderAddresses[
                getNormalShareholderAddressesLength()
            ];
            normalShareholderAddresses[_index] = normalShareholderAddresses[
                getNormalShareholderAddressesLength()
            ];
            normalShareholderIndex[lastOffererAddr] = _index;
        }
        normalShareholderAddresses.pop();
        normalShareholderIndex[_addr] = 0;
    }

    /// @notice Adds an address to the allShareholderAddresses array and saves its index in this array.
    function _addAllShareholderAddresses(address _addr) internal {
        require(
            allShareholderIndex[_addr] == 0,
            "_addr already in allShareholderAddresses"
        );
        allShareholderIndex[_addr] = getAllShareholderAddressesLength() + 1;
        allShareholderAddresses.push(_addr);
    }

    /// @notice Removes an address from the allShareholderAddresses array and resets its index in this array.
    function _removeAllShareholderAddresses(address _addr) internal {
        uint256 _index = allShareholderIndex[_addr];

        if (
            getAllShareholderAddressesLength() != 1 &&
            _index != getAllShareholderAddressesLength()
        ) {
            address lastOffererAddr = allShareholderAddresses[
                getAllShareholderAddressesLength()
            ];
            allShareholderAddresses[_index] = allShareholderAddresses[
                getAllShareholderAddressesLength()
            ];
            allShareholderIndex[lastOffererAddr] = _index;
        }
        allShareholderAddresses.pop();
        allShareholderIndex[_addr] = 0;
    }

    function _updateAddrArraysAfterBuyShares(
        address _buyer,
        address _seller,
        uint24 _numberOfShares
    ) internal {
        /// @dev _buyer is privileged
        if (asset.getPrivilegedShareholdersIndex(_buyer) != 0) {
            if (allShareholderIndex[_buyer] == 0) {
                _addAllShareholderAddresses(_buyer);
            }
            /// @dev We don't call _addOffererAddress() because priv shareholers don't automatically create an offer after buying shares.
        }
        /// @dev _buyer is normal/fresh user
        else {
            if (allShareholderIndex[_buyer] == 0) {
                _addAllShareholderAddresses(_buyer);
                _addNormalShareholderAddresses(_buyer);
                _addOffererAddress(_buyer);
            }
            sharesInNormalHands += _numberOfShares;
        }

        /// @dev _seller is privileged
        if (asset.getPrivilegedShareholdersIndex(_seller) != 0) {
            if (asset.getShares(_seller) == 0) {
                _removeAllShareholderAddresses(_seller);
            }
        }
        /// @dev _seller is normal/fresh user
        else {
            if (asset.getShares(_seller) == 0) {
                _removeAllShareholderAddresses(_seller);
                _removeNormalShareholderAddresses(_seller);
            }
            sharesInNormalHands -= _numberOfShares;
        }
        /// @dev No matter privileged/normal/fresh, remove the _seller address from the offererAddresses if all shares in the offer have been bought.
        if (asset.getOffersIndex(_seller) == 0) {
            _removeOffererAddress(_seller);
        }
    }

    /// @notice Randomly selects which offer the buyShares() transaction will be sent to.
    function _getOffererAddressToBuyFrom(
        uint256 _fromSeed
    ) internal view returns (address _from) {
        if (getOffererAddressesLength() == 1) {
            _from = offererAddresses[1];
        } else {
            _from = offererAddresses[
                uint256(bound(_fromSeed, 1, getOffererAddressesLength()))
            ];
        }
    }

    /// @notice Randomly selects params for the buyShares() transaction.
    function _getDataToBuy(
        uint256 _amountBuySeed,
        address _from
    )
        internal
        view
        returns (
            uint24 _amount,
            uint256 _price,
            uint256 _ownerFee,
            uint256 _privilegedFee
        )
    {
        uint24 _index = asset.getOffersIndex(_from);
        Asset_Structs.Offer memory _tempOffer = asset.getOffer(_index);
        uint256 _maxAmountToBuy = uint256(_tempOffer.amount);
        _amount = uint24(bound(_amountBuySeed, 1, _maxAmountToBuy));
        _ownerFee = uint256(_tempOffer.ownerFee);
        _privilegedFee = uint256(_tempOffer.privilegedFee);
        _price = uint256(_tempOffer.value) + _ownerFee + _privilegedFee;
    }

    function _getNewPriceForShare(
        address _offerOwner,
        uint96 _newSellLimit
    )
        internal
        view
        returns (uint256 _fullPrice, uint96 _ownerFee, uint96 _privilegedFee)
    {
        require(_offerOwner != address(0), "_getNewPriceForShare::1");
        require(_newSellLimit >= MIN_SELL_OFFER, "_getNewPriceForShare::2");
        _ownerFee = uint96((_newSellLimit / BIPS) * COMMITSION_FOR_OWNER);
        if (asset.getPrivilegedShareholdersIndex(_offerOwner) == 0) {
            _privilegedFee = uint96(
                (_newSellLimit / BIPS) * COMMITSION_FOR_PRIVILEGED
            );
        }
        _fullPrice =
            uint256(_newSellLimit) +
            uint256(_ownerFee) +
            uint256(_privilegedFee);
    }

    /// @notice Handles the error response from Asset contract.
    function _checkResponse(bool success, bytes memory data) internal pure {
        if (!success) {
            if (data.length > 0) {
                assembly {
                    let returndata_size := mload(data)
                    revert(add(32, data), returndata_size)
                }
            } else {
                revert("delegatecall failed");
            }
        }
    }

    /// @dev This function can be used in another function where currentActor, offerAmount and offerPrice is set.
    function _makeSellOffer_SubHandler_1() internal {
        /// @dev Makes sure currentActor is indeed a privileged shareholder.
        require(
            asset.getPrivilegedShareholdersIndex(currentActor) != 0,
            "makeSellOffer_SubHandler_1:: 1"
        );
        if (offerAmount >= MIN_AMOUNT_IN_OFFER) {
            asset.makeSellOffer(offerAmount, offerPrice);
            _addOffererAddress(currentActor);
        }
    }

    /// @dev This function updates the value of assetContractGain
    /// @param _msgValueInBuy The sum of ether send into the Asset contract as a payment for the previous owner of the shares plus fees for privileged shareholders. Its the value of msg.value minus the fee for the protocol
    /// @param _msgValueInSignLicense The ether send in the signLicense() function.
    /// @param _widrawalValue The ether send out of the protocol in the withdraw() function.
    function _updateAssetContractGain(
        uint256 _msgValueInBuy,
        uint256 _msgValueInSignLicense,
        uint256 _widrawalValue
    ) internal {
        require(
            assetContractGain >= _widrawalValue,
            "_updateAssetContractGain"
        );
        assetContractGain += _msgValueInBuy;
        assetContractGain += _msgValueInSignLicense;
        assetContractGain -= _widrawalValue;
    }
}
