// SPDX-License-Identifier: BULS-1.1

pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Actors} from "./Utils/Actors.sol";
import {Globals} from "./Utils/Globals.sol";

import {AssetFactoryProxy} from "../../src/core/AssetFactoryProxy.sol";
import {AssetFactory} from "../../src/core/AssetFactory.sol";
import {AssetInstanceProxy} from "../../src/core/AssetInstanceProxy.sol";
import {AssetInstance} from "../../src/core/AssetInstance.sol";

import {IAssetFactory_write} from "../../src/core/util/IAssetFactory_write.sol";
import {IAssetFactory} from "../../src/core/util/IAssetFactory.sol";
import {IAssetInstance} from "../../src/core/util/IAssetInstance.sol";

import {AssetFactoryErrors} from "../../src/core/util/AssetFactoryErrors.sol";
import {AssetFactoryEvents} from "../../src/core/util/AssetFactoryEvents.sol";
import {AssetInstanceErrors} from "../../src/core/util/AssetInstanceErrors.sol";
import {AssetInstanceEvents} from "../../src/core/util/AssetInstanceEvents.sol";
import {Asset_Structs} from "../../src/core/util/AssetInstanceStructs.sol";

import {BananasharesToken} from "../../src/governance/BananasharesToken.sol";

contract Test_AssetFactory is
    Test,
    Actors,
    Globals,
    AssetInstanceErrors,
    AssetInstanceEvents,
    AssetFactoryErrors,
    AssetFactoryEvents
{
    AssetFactory factoryImplementation;
    AssetInstance assetImplementation;
    AssetFactoryProxy assetFactory;
    IAssetInstance assetInstance;

    BananasharesToken bananasharesToken;

    bool callResult;
    bytes callResultData;

    uint24 shareMike = 600_000;
    uint24 shareBilbo = 400_000;
    // uint24 shareMike = 600_557;
    // uint24 shareBilbo = 399_443;

    string[] authors = ["Mike Bolt", "Bilbo Baggins"];
    address[] addresses = [addressMike, addressBilbo];
    uint24[] shares = [shareMike, shareBilbo];
    bytes32 testAssetHash =
        0x1234567812345678123456781234567812345678123456781234567812345678;
    bytes32 testAssetHash_2 =
        0x1234567812345678123456781234567812345678123456781234567812345679;

    uint224 licenseValue = (0.1 ether);

    StandardOffer standardOffer = StandardOffer({amount: 10_000, value: 1e14});
    StandardBuyValues standardBuyValues =
        StandardBuyValues({amount: 1_000, newSellLimit: 2e14});

    TestAsset testAsset =
        TestAsset({
            nameOfAsset: "testAsset",
            authors: authors,
            shareholderAddress: addresses,
            shares: shares,
            assetHash: testAssetHash
        });

    function setUp() public {
        vm.roll(block.number + 1);
        _dealEtherToActors();
        vm.startPrank(addrAdmin);
        bananasharesToken = new BananasharesToken(TOKENS_FOR_FOUNDER);
        factoryImplementation = new AssetFactory(
            address(bananasharesToken),
            block.number
        );

        bytes memory _calldata = abi.encodeWithSelector(
            AssetFactory.initialize.selector,
            addrTimelockController
        );

        assetFactory = new AssetFactoryProxy(
            address(factoryImplementation),
            _calldata,
            COMMITSION_FOR_PRIVILEGED,
            COMMITSION_FOR_OWNER,
            MIN_SELL_OFFER
        );

        bananasharesToken.grantRole(
            keccak256("MINT_ROLE"),
            address(assetFactory)
        );

        vm.stopPrank();
        vm.startPrank(addrTimelockController);
        assetImplementation = new AssetInstance(address(assetFactory));
        IAssetFactory(address(assetFactory)).setAssetInstanceImplementation(
            address(assetImplementation)
        );
        vm.stopPrank();

        address _addrAsset = _createAsset();
        assetInstance = IAssetInstance(payable(_addrAsset));
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   helpFunctions                            //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function _createAsset() public returns (address newAssetAddress) {
        (callResult, callResultData) = address(assetFactory).call(
            abi.encodeWithSelector(
                IAssetFactory_write.createAssetInstance.selector,
                testAsset.nameOfAsset,
                testAsset.authors,
                testAsset.shareholderAddress,
                testAsset.shares,
                testAsset.assetHash
            )
        );
        newAssetAddress = IAssetFactory(address(assetFactory))
            .getAssetInstanceByHash(testAsset.assetHash);
    }

    function _createAssetWithXNumerOfShareholders(
        uint24 _x,
        string memory _title
    ) public returns (address newAssetAddress) {
        require(_x <= testPrivilegedNames.length);
        string[] memory xAuthors = new string[](_x);
        address[] memory xAddresses = new address[](_x);
        uint24[] memory xShares = new uint24[](_x);
        uint24 totalNumner = TOTAL_SUPPLY;
        uint24 sharesPerShareholder = totalNumner / _x;
        for (uint i = 0; i < _x; i++) {
            xAuthors[i] = testPrivilegedNames[i];
            xAddresses[i] = testPrivilegedAddresses[i];
            xShares[i] = sharesPerShareholder;
            if (i == (_x - 1)) {
                xShares[i] = totalNumner;
            } else {
                totalNumner -= sharesPerShareholder;
            }
        }
        TestAsset memory xTestAsset = TestAsset({
            nameOfAsset: _title,
            authors: xAuthors,
            shareholderAddress: xAddresses,
            shares: xShares,
            assetHash: bytes32(uint256(uint24(1234) + _x))
        });

        IAssetFactory(address(assetFactory)).createAssetInstance(
            xTestAsset.nameOfAsset,
            xTestAsset.authors,
            xTestAsset.shareholderAddress,
            xTestAsset.shares,
            xTestAsset.assetHash
        );
        newAssetAddress = IAssetFactory(address(assetFactory))
            .getAssetInstanceByHash(xTestAsset.assetHash);
    }

    function _createLicense(
        address _creator,
        bool isExpectRevert,
        string memory RevertInfo
    ) public returns (bytes32 _licenseHash) {
        uint256 l = assetInstance.getLicensesLength();
        _licenseHash = keccak256(abi.encode(bytes32(l + 1)));
        _licenseHash = bytes32(l + 1);
        vm.startPrank(_creator);
        if (isExpectRevert) {
            vm.expectRevert(bytes(RevertInfo));
        }
        assetInstance.putNewLicense(_licenseHash, licenseValue);
        vm.stopPrank();
    }

    function _createPayment(address _payer, bytes32 _licenseHash) public {
        vm.prank(_payer);
        string memory sig = "signLicense(bytes32)";
        (bool ok, ) = address(assetInstance).call{value: licenseValue}(
            abi.encodeWithSignature(sig, _licenseHash)
        );
        assert(ok);
    }

    function _createOfferFromPrivileged(
        address _from,
        uint24 _amount,
        uint96 _valuePerShare
    ) public {
        vm.prank(_from);
        assetInstance.makeSellOffer(_amount, _valuePerShare);
    }

    function _createOfferFromPrivileged_InSpecificAsset(
        address _asset,
        address _from,
        uint24 _amount,
        uint96 _valuePerShare
    ) public {
        vm.prank(_from);
        IAssetInstance(_asset).makeSellOffer(_amount, _valuePerShare);
    }

    function _investorBuysSomeShares(
        address _investor,
        address _from,
        uint24 _amount,
        uint96 _sellLimit,
        bool isExpectRevert,
        string memory RevertInfo
    ) public {
        uint256 index = assetInstance.getOffersIndex(_from);
        Asset_Structs.Offer memory offer = assetInstance.getOffer(index);

        uint256 pricePerShareToPay = uint256(offer.value) +
            uint256(offer.privilegedFee) +
            uint256(offer.ownerFee);

        if (isExpectRevert) {
            vm.expectRevert(bytes(RevertInfo));
        }
        vm.startPrank(_investor);
        assetInstance.buyShares{value: pricePerShareToPay * _amount}(
            _from,
            _amount,
            _sellLimit
        );
        vm.stopPrank();
    }

    function _investorBuysSomeShares_InSpecificAsset(
        address _asset,
        address _investor,
        address _from,
        uint24 _amount,
        uint96 _sellLimit,
        bool isExpectRevert,
        string memory RevertInfo
    ) public {
        uint256 index = IAssetInstance(_asset).getOffersIndex(_from);
        Asset_Structs.Offer memory offer = IAssetInstance(_asset).getOffer(
            index
        );

        uint256 pricePerShareToPay = uint256(offer.value) +
            uint256(offer.privilegedFee) +
            uint256(offer.ownerFee);

        if (isExpectRevert) {
            vm.expectRevert(bytes(RevertInfo));
        }
        vm.startPrank(_investor);
        IAssetInstance(_asset).buyShares{value: pricePerShareToPay * _amount}(
            _from,
            _amount,
            _sellLimit
        );
        vm.stopPrank();
    }

    function _prepareFor_testPayFeesForPrivileged() public {
        // 1. Creates an offer from a priviledged.
        // 2. An user buys some shares.
        // 3. Another user buys some shares from the first user.
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );
        _investorBuysSomeShares(
            InvestorMark,
            addressBilbo,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        _investorBuysSomeShares(
            InvestorBob,
            InvestorMark,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
    }

    function _prepareFor_testPayFeesForPrivileged_InSpecificAsset(
        address _asset
    ) public {
        // 1. Creates an offer from a priviledged.
        // 2. An user buys some shares.
        // 3. Another user buys some shares from the first user.
        _createOfferFromPrivileged_InSpecificAsset(
            _asset,
            testPrivilegedAddresses[0],
            standardOffer.amount,
            standardOffer.value
        );
        _investorBuysSomeShares_InSpecificAsset(
            _asset,
            InvestorMark,
            testPrivilegedAddresses[0],
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        _investorBuysSomeShares_InSpecificAsset(
            _asset,
            InvestorBob,
            InvestorMark,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
    }

    function _prepareFor_WithdrawForPrivileged() public {
        _prepareFor_testPayFeesForPrivileged();
        assetInstance.payEarndFeesToAllPrivileged();
    }

    function _bytes32ToString(
        bytes32 _bytes32
    ) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i * 2] = hexChars[uint8(_bytes32[i] >> 4)];
            str[1 + i * 2] = hexChars[uint8(_bytes32[i] & 0x0f)];
        }
        return string(str);
    }

    function _decodeError(bytes memory data) public pure returns (bytes32) {
        require(data.length >= 4, "Data too short");

        bytes32 first32bytes;
        assembly {
            first32bytes := mload(add(data, 32))
        }
        bytes4 errorSelector = bytes4(first32bytes);
        bytes4 expectedSelector = 0x08c379a0;
        require(errorSelector == expectedSelector, "Not an error message");

        bytes32 errorMessage32bytes;
        assembly {
            errorMessage32bytes := mload(add(data, 100))
        }

        return errorMessage32bytes;
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   createAssetInstance                      //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function testAssetCreate() public view {
        uint24 index0 = assetInstance.getPrivilegedShareholdersIndex(
            address(0)
        );
        uint24 index1 = assetInstance.getPrivilegedShareholdersIndex(
            addressMike
        );
        uint24 index2 = assetInstance.getPrivilegedShareholdersIndex(
            addressBilbo
        );
        console.log("index0: ", index0);
        console.log("index1: ", index1);
        console.log("index2: ", index2);

        assertEq(index0, 0);
        assertEq(index1, 1);
        assertEq(index2, 2);

        uint256 privilegedShareholdersLength = assetInstance
            .getPrivilegedShareholdersLength();
        assertEq(privilegedShareholdersLength, addresses.length);

        address[] memory privilegedAddresses = assetInstance
            .getAllPrivShareholders();
        for (uint i = 0; i < privilegedAddresses.length; i++) {
            console.log("privilegedAddress: ", privilegedAddresses[i]);
            address addr = privilegedAddresses[i];
            uint24 share = assetInstance.getShares(addr);
            console.log("privilegedShare: ", share);
        }

        Asset_Structs.Author memory tempAuthor = assetInstance.getAuthor(0);
        Asset_Structs.Author[] memory tempAuthors = assetInstance
            .getAllAuthors();
        uint256 authorsLength = assetInstance.getAuthorsLength();

        (address tempAddr, uint24 tempShare) = assetInstance
            .getPrivilegedShareholder(1);
        (address tempAddr2, uint24 tempShare2) = assetInstance
            .getPrivilegedShareholder(2);
        assertEq(addressMike, tempAddr);
        assertEq(shareMike, tempShare);
        assertEq(addressBilbo, tempAddr2);
        assertEq(shareBilbo, tempShare2);

        assertEq(authors[0], tempAuthor.name);
        assertEq(authors[1], tempAuthors[1].name);
        assertEq(authors.length, authorsLength);
        assertEq(privilegedAddresses[1], addressMike);
        assertEq(privilegedAddresses[2], addressBilbo);
    }

    function testEmitAssetCreated() public {
        console.log(testAsset.nameOfAsset);
        vm.startPrank(addressMike);
        assertEq(testAsset.nameOfAsset, "testAsset");
        assertEq(testAsset.shareholderAddress[0], addressMike);

        vm.expectEmit(true, false, false, true);

        emit AssetInstanceCreated(addressMike, address(0));
        IAssetFactory(address(assetFactory)).createAssetInstance(
            testAsset.nameOfAsset,
            testAsset.authors,
            testAsset.shareholderAddress,
            testAsset.shares,
            0x1234567812345678123456781234567812345678123456781234567812345671
        );
        address newAssetAddress = IAssetFactory(address(assetFactory))
            .getAssetInstanceByHash(
                0x1234567812345678123456781234567812345678123456781234567812345671
            );
        console.log(
            IAssetFactory(address(assetFactory)).getAssetInstanceByHash(
                0x1234567812345678123456781234567812345678123456781234567812345671
            )
        );
        console.logBytes32(
            IAssetFactory(address(assetFactory)).getAssetInstanceHashByAddress(
                newAssetAddress
            )
        );
        vm.stopPrank();
    }

    function test_RevertWhen_TheSameHash() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                AssetFactoryErrors.AssetInstanceAlreadyExists.selector,
                testAssetHash
            )
        );
        vm.startPrank(addressMike);
        IAssetFactory(address(assetFactory)).createAssetInstance(
            testAsset.nameOfAsset,
            testAsset.authors,
            testAsset.shareholderAddress,
            testAsset.shares,
            testAssetHash
        );
        vm.stopPrank();
    }

    function testTooLongTitle() public {
        string
            memory wrongTitle = "123456789 123456789 123456789 123456789 123456789 123456789 12345";
        vm.startPrank(addressMike);
        vm.expectEmit(false, false, false, true);
        emit AssetInstanceCreationFailure(addressMike, "wrong title length");
        IAssetFactory(address(assetFactory)).createAssetInstance(
            wrongTitle,
            testAsset.authors,
            testAsset.shareholderAddress,
            testAsset.shares,
            testAssetHash_2
        );
        vm.stopPrank();
    }

    function testTooManyAddresses() public {
        addresses = [
            address(1),
            address(2),
            address(3),
            address(4),
            address(5),
            address(6),
            address(7),
            address(8),
            address(9),
            address(10),
            address(11)
        ];
        vm.startPrank(addressMike);
        vm.expectEmit(false, false, false, true);
        emit AssetInstanceCreationFailure(addressMike, "too many shareholders");
        IAssetFactory(address(assetFactory)).createAssetInstance(
            testAsset.nameOfAsset,
            testAsset.authors,
            addresses,
            testAsset.shares,
            testAssetHash_2
        );
        vm.stopPrank();
    }

    function testWrongAuthorsNumber() public {
        authors = ["Mike Bolt", "Bilbo Baggins", "Bilbo Baggins"];
        vm.startPrank(addressMike);
        vm.expectEmit(false, false, false, true);
        emit AssetInstanceCreationFailure(addressMike, "wrong length 1");
        IAssetFactory(address(assetFactory)).createAssetInstance(
            testAsset.nameOfAsset,
            authors,
            testAsset.shareholderAddress,
            testAsset.shares,
            testAssetHash_2
        );
        vm.stopPrank();
    }

    function testWrongSharesNumber() public {
        shares = [shareMike, shareBilbo, shareBilbo];
        vm.startPrank(addressMike);
        vm.expectEmit(false, false, false, true);
        emit AssetInstanceCreationFailure(addressMike, "wrong length 2");
        IAssetFactory(address(assetFactory)).createAssetInstance(
            testAsset.nameOfAsset,
            testAsset.authors,
            testAsset.shareholderAddress,
            shares,
            testAssetHash_2
        );
        vm.stopPrank();
    }

    function testDuplicatePrivilegedAddress() public {
        addresses = [addressMike, addressMike];
        vm.startPrank(addressMike);
        vm.expectEmit(false, false, false, true);
        emit AssetInstanceCreationFailure(addressMike, "duplicate address");
        IAssetFactory(address(assetFactory)).createAssetInstance(
            testAsset.nameOfAsset,
            testAsset.authors,
            addresses,
            testAsset.shares,
            testAssetHash_2
        );
        vm.stopPrank();
    }

    function testWrongSuply() public {
        shares = [shareMike, shareBilbo + 10];
        vm.startPrank(addressMike);
        vm.expectEmit(false, false, false, true);
        emit AssetInstanceCreationFailure(addressMike, "wrong suply");
        IAssetFactory(address(assetFactory)).createAssetInstance(
            testAsset.nameOfAsset,
            testAsset.authors,
            testAsset.shareholderAddress,
            shares,
            testAssetHash_2
        );
        vm.stopPrank();
    }

    function testTooLongAuthor() public {
        authors = ["Mike Bolt", "123456789 123456789 123456789 123"];
        vm.startPrank(addressMike);
        vm.expectEmit(false, false, false, true);
        emit AssetInstanceCreationFailure(addressMike, "wrong length author");
        IAssetFactory(address(assetFactory)).createAssetInstance(
            testAsset.nameOfAsset,
            authors,
            testAsset.shareholderAddress,
            testAsset.shares,
            testAssetHash_2
        );
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                  AssetsFactory                          /////
    ////////                   withdraw                                 //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function testWithdrawFromAssetsFactory() public {
        _createOfferFromPrivileged(
            addressMike,
            standardOffer.amount,
            standardOffer.value
        );
        uint256 index = assetInstance.getOffersIndex(addressMike);
        Asset_Structs.Offer memory offer = assetInstance.getOffer(index);
        uint96 ownerFee = offer.ownerFee;
        vm.prank(addressMike);
        uint256 balanceBeforeInSM = address(assetFactory).balance;
        assert(balanceBeforeInSM == 0);
        _investorBuysSomeShares(
            InvestorMark,
            addressMike,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        uint256 balanceAfterInSM = address(assetFactory).balance;
        vm.assertEq(ownerFee * standardBuyValues.amount, balanceAfterInSM);
        uint256 balanceBeforeInWallet = addrTimelockController.balance;
        vm.prank(addrTimelockController);
        IAssetFactory(address(assetFactory)).withdraw();
        uint256 balanceAfterInWallet = addrTimelockController.balance;
        vm.assertEq(
            balanceBeforeInWallet + balanceAfterInSM,
            balanceAfterInWallet
        );
    }

    function test_RevertWhen_NotOwnerWantsToWithdraw() public {
        vm.prank(addrTimelockController);
        IAssetFactory(address(assetFactory)).withdraw();
        vm.expectRevert();
        vm.prank(addressBilbo);
        IAssetFactory(address(assetFactory)).withdraw();
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   makeSellOffer                            //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    // forge test --mt testMakeSellOffer -vv
    function testMakeSellOffer() public {
        uint24 _amount = 10_000;
        uint96 _bid = 1e18;
        vm.startPrank(addressMike);
        vm.expectEmit(true, false, false, true);
        emit SellOfferPut(
            addressMike,
            _amount,
            _bid + uint96((_bid * COMMITSION_FOR_OWNER) / BIPS)
        );
        assetInstance.makeSellOffer(_amount, _bid);
        uint256 length = assetInstance.getOffersLength();
        console.log("length: ", length);
        console.log("--------------------------------");
        uint256 index = assetInstance.getOffersIndex(addressMike);
        console.log("index: ", index);
        console.log("--------------------------------");
        Asset_Structs.Offer memory offer = assetInstance.getOffer(index);

        address from = offer.from;
        uint24 amount = offer.amount;
        uint96 value = offer.value;
        uint96 privilegedFee = offer.privilegedFee;
        uint96 ownerFee = offer.ownerFee;

        console.log("from: ", from);
        console.log("amount: ", amount);
        console.log("value: ", value);
        console.log("privilegedFee: ", privilegedFee);
        console.log("ownerFee: ", ownerFee);
        console.log("--------------------------------");

        assertEq(from, addressMike);
        assertEq(amount, _amount);
        assertEq(value, _bid);
        assertEq(privilegedFee, 0);
        assertEq(ownerFee, (_bid * COMMITSION_FOR_OWNER) / BIPS);

        _amount = 50_000;
        _bid = 3e17;
        assetInstance.makeSellOffer(_amount, _bid);
        length = assetInstance.getOffersLength();
        offer = assetInstance.getOffer(length);

        from = offer.from;
        amount = offer.amount;
        value = offer.value;
        privilegedFee = offer.privilegedFee;
        ownerFee = offer.ownerFee;

        console.log("from: ", from);
        console.log("amount: ", amount);
        console.log("value: ", value);
        console.log("privilegedFee: ", privilegedFee);
        console.log("ownerFee: ", ownerFee);

        assertEq(amount, _amount);
        assertEq(value, _bid);
        assertEq(privilegedFee, 0);
        assertEq(ownerFee, (_bid * COMMITSION_FOR_OWNER) / BIPS);
        vm.stopPrank();
    }

    function test_CreateAnotherOfferAndCheckIfRemovesPrevious() public {
        StandardOffer memory firstOffer = StandardOffer({
            amount: 10_000,
            value: 1e14
        });
        StandardOffer memory secondOffer = StandardOffer({
            amount: 20_000,
            value: 2e14
        });
        vm.startPrank(addressMike);
        assetInstance.makeSellOffer(firstOffer.amount, firstOffer.value);
        uint256 firstOffersLength = assetInstance.getOffersLength();
        Asset_Structs.Offer memory firstAssetOffer = assetInstance.getOffer(
            firstOffersLength
        );
        assetInstance.makeSellOffer(secondOffer.amount, secondOffer.value);
        uint256 secondOffersLength = assetInstance.getOffersLength();
        Asset_Structs.Offer memory secondAssetOffer = assetInstance.getOffer(
            secondOffersLength
        );
        assertEq(firstOffersLength, 1);
        assertEq(secondOffersLength, 1);
        assertEq(firstAssetOffer.amount, firstOffer.amount);
        assertEq(firstAssetOffer.value, firstOffer.value);
        assertEq(secondAssetOffer.amount, secondAssetOffer.amount);
        assertEq(secondAssetOffer.value, secondAssetOffer.value);
        vm.stopPrank();
    }

    function test_RevertWhen_NormalUserCreatesOffer() public {
        vm.startPrank(InvestorMark);
        vm.expectRevert("Not privileged Shareholder");
        assetInstance.makeSellOffer(standardOffer.amount, standardOffer.value);
        vm.stopPrank();
    }

    function test_RevertWhen_AmountIsZero() public {
        vm.startPrank(addressMike);
        vm.expectRevert("Amount 0");
        assetInstance.makeSellOffer(0, standardOffer.value);
        vm.stopPrank();
    }

    function test_RevertWhen_NotEnoughShares() public {
        vm.startPrank(addressMike);
        vm.expectEmit(true, false, false, false);
        emit SellOfferPut(addressMike, 0, 0);
        assetInstance.makeSellOffer(shareMike, standardOffer.value);
        vm.expectRevert("Not enough shares");
        assetInstance.makeSellOffer(shareMike + 1, standardOffer.value);
        vm.stopPrank();
    }

    function test_RevertWhen_PriceToSmall() public {
        vm.startPrank(addressMike);
        vm.expectEmit(true, false, false, false);
        emit SellOfferPut(addressMike, 0, 0);
        assetInstance.makeSellOffer(standardOffer.amount, MIN_SELL_OFFER);
        vm.expectRevert("Price too small");
        assetInstance.makeSellOffer(standardOffer.amount, MIN_SELL_OFFER - 1);
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   cancelOffer                              //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function testCancelOffer() public {
        uint24 _amount = 10_000;
        uint96 _bid = 1e18;
        vm.startPrank(addressMike);
        assetInstance.makeSellOffer(_amount, _bid);

        vm.expectEmit();
        emit OfferCancelled(addressMike);
        assetInstance.cancelOffer();

        uint256 length = assetInstance.getOffersLength();
        assertEq(length, 0);
    }

    function test_RevertWhen_YouAreNotPriviledged() public {
        vm.prank(addressMike);
        assetInstance.makeSellOffer(standardOffer.amount, standardOffer.value);
        _investorBuysSomeShares(
            InvestorMark,
            addressMike,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        uint256 length = assetInstance.getOffersLength();
        vm.prank(InvestorMark);
        vm.expectRevert("Not privileged");
        assetInstance.cancelOffer();
        assertEq(length, 2);
    }

    function test_RevertWhen_NoOffer() public {
        vm.prank(addressMike);
        vm.expectRevert("No offer");
        assetInstance.cancelOffer();
    }

    function test_cancelOfferAndMakeSureLastOfferChangeIndex() public {
        vm.prank(addressMike);
        assetInstance.makeSellOffer(standardOffer.amount, standardOffer.value);
        vm.prank(addressBilbo);
        assetInstance.makeSellOffer(standardOffer.amount, standardOffer.value);
        vm.prank(addressMike);
        assetInstance.cancelOffer();
        uint256 offersLength = assetInstance.getOffersLength();
        uint24 offerIndexMike = assetInstance.getOffersIndex(addressMike);
        uint24 offerIndexBilbo = assetInstance.getOffersIndex(addressBilbo);
        Asset_Structs.Offer memory assetOffer = assetInstance.getOffer(
            offerIndexBilbo
        );
        assertEq(offersLength, 1);
        assertEq(offerIndexMike, 0);
        assertEq(offerIndexBilbo, 1);
        assertEq(assetOffer.from, addressBilbo);
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   buyShares                                //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////
    function testBuySharesAndCheckFees() public {
        address offerOwner = addressBilbo;
        //create privileged offer
        vm.prank(offerOwner);
        assetInstance.makeSellOffer(standardOffer.amount, standardOffer.value);
        uint256 index = assetInstance.getOffersIndex(offerOwner);
        Asset_Structs.Offer memory offer = assetInstance.getOffer(index);
        uint256 pricePerShareToPay = uint256(offer.value) +
            uint256(offer.privilegedFee) +
            uint256(offer.ownerFee);

        //check god reward before transaction
        uint256 godRewardBefore = address(assetFactory).balance;
        console.log("godRewardBefore", godRewardBefore);

        //Investor buys offer
        vm.prank(InvestorMark);
        string memory sig = "buyShares(address,uint24,uint96)";
        (bool ok, ) = address(assetInstance).call{
            value: pricePerShareToPay * standardBuyValues.amount
        }(
            abi.encodeWithSignature(
                sig,
                offerOwner,
                standardBuyValues.amount,
                standardBuyValues.newSellLimit
            )
        );
        assert(ok);
        uint256 feesToPayGod_part_1 = offer.ownerFee * standardBuyValues.amount;
        uint256 feesToPayAllPrivileged_part_1 = offer.privilegedFee *
            standardBuyValues.amount;
        console.log("feesToPayAllPrivileged", feesToPayAllPrivileged_part_1);

        //check god reward after transaction
        uint256 godRewardAfter = address(assetFactory).balance;
        console.log("godRewardAfter", godRewardAfter);
        assertEq(feesToPayGod_part_1, godRewardAfter);
        assertEq(feesToPayAllPrivileged_part_1, 0);

        //new check god reward before 2nd transaction
        godRewardBefore = address(assetFactory).balance;
        console.log("godRewardBefore", godRewardBefore);

        //New Investor buys offer from first Investor
        index = assetInstance.getOffersIndex(InvestorMark);
        offer = assetInstance.getOffer(index);
        pricePerShareToPay =
            uint256(offer.value) +
            uint256(offer.privilegedFee) +
            uint256(offer.ownerFee);
        vm.prank(InvestorBob);
        (ok, ) = address(assetInstance).call{
            value: pricePerShareToPay * standardBuyValues.amount
        }(
            abi.encodeWithSignature(
                sig,
                InvestorMark,
                standardBuyValues.amount,
                standardBuyValues.newSellLimit
            )
        );
        assert(ok);
        uint256 feesToPayGod_part_2 = offer.ownerFee * standardBuyValues.amount;
        uint256 feesToPayAllPrivileged_part_2 = offer.privilegedFee *
            standardBuyValues.amount;
        console.log(
            "feesToPayAllPrivileged_part_2",
            feesToPayAllPrivileged_part_2
        );

        //check god reward after transaction
        vm.prank(addressMike);
        godRewardAfter = address(assetFactory).balance;
        console.log("godRewardAfter", godRewardAfter);

        uint256 feesToPayAllPrivileged = assetInstance.getPrivilegedFees(
            addressMike
        ) + assetInstance.getPrivilegedFees(addressBilbo);

        assertEq(feesToPayGod_part_1 + feesToPayGod_part_2, godRewardAfter);
        console.log(
            "REMINDER:",
            (feesToPayAllPrivileged_part_2 - feesToPayAllPrivileged)
        );
        assertLt(
            (feesToPayAllPrivileged_part_2 - feesToPayAllPrivileged),
            ACCEPTABLE_REMINDER
        );
    }

    function testIvestorsBuyFullOffer() public {
        address offerOwner = addressBilbo;
        uint24 offerStartShares = shareBilbo;

        vm.startPrank(offerOwner);
        assetInstance.makeSellOffer(standardOffer.amount, standardOffer.value);

        uint256 index = assetInstance.getOffersIndex(offerOwner);
        Asset_Structs.Offer memory offer = assetInstance.getOffer(index);
        uint24 offerOwnerSharesInOfferBefor = offer.amount;

        uint256 pricePerShareToPay = uint256(offer.value) +
            uint256(offer.privilegedFee) +
            uint256(offer.ownerFee);

        vm.startPrank(InvestorMark);
        string memory sig = "buyShares(address,uint24,uint96)";
        (bool ok, ) = address(assetInstance).call{
            value: pricePerShareToPay * standardBuyValues.amount
        }(
            abi.encodeWithSignature(
                sig,
                offerOwner,
                standardBuyValues.amount,
                standardBuyValues.newSellLimit
            )
        );
        assert(ok);

        uint24 investorMarkShares = assetInstance.getShares(InvestorMark);
        uint24 offerOwnerShares = assetInstance.getShares(offerOwner);
        offer = assetInstance.getOffer(index);
        uint24 offerOwnerSharesInOfferAfter = offer.amount;

        console.log("investorMarkShares: ", investorMarkShares);
        console.log("offerOwnerShares: ", offerOwnerShares);
        console.log("offerOwnerSharesInOffer: ", offerOwnerSharesInOfferAfter);

        assertEq(investorMarkShares, standardBuyValues.amount);
        assertEq(offerOwnerShares, offerStartShares - standardBuyValues.amount);
        assertEq(
            offerOwnerSharesInOfferAfter,
            offerOwnerSharesInOfferBefor - standardBuyValues.amount
        );
    }

    function test_IvestorsBuyPartOffer() public {
        vm.prank(addressMike);
        assetInstance.makeSellOffer(standardOffer.amount, standardOffer.value);
        _investorBuysSomeShares(
            InvestorMark,
            addressMike,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        _investorBuysSomeShares(
            InvestorBob,
            InvestorMark,
            standardBuyValues.amount / 2,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        uint256 indexMark = assetInstance.getOffersIndex(InvestorMark);
        uint256 indexBob = assetInstance.getOffersIndex(InvestorBob);
        assertEq(indexMark, 2);
        assertEq(indexBob, 3);
        _investorBuysSomeShares(
            InvestorBob,
            InvestorMark,
            standardBuyValues.amount / 2,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        indexMark = assetInstance.getOffersIndex(InvestorMark);
        indexBob = assetInstance.getOffersIndex(InvestorBob);
        assertEq(indexMark, 0);
        assertEq(indexBob, 2);
    }

    function test_RevertWhen_BuyIfThereIsNoOffer() public {
        _investorBuysSomeShares(
            InvestorMark,
            addressBilbo,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            true,
            "Offer 0"
        );
    }

    function test_RevertWhen_BuyIfAmoutIsZero() public {
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );
        _investorBuysSomeShares(
            InvestorMark,
            addressBilbo,
            0,
            standardBuyValues.newSellLimit,
            true,
            "Amount 0"
        );
    }

    function test_RevertWhen_BuyIfAmoutIsToHigh() public {
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );
        _investorBuysSomeShares(
            InvestorMark,
            addressBilbo,
            standardOffer.amount + 1,
            standardBuyValues.newSellLimit,
            true,
            "Amount exceeds available value"
        );
    }

    function test_RevertWhen_BuyAndSetNewLimitToZero() public {
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );
        _investorBuysSomeShares(
            InvestorMark,
            addressBilbo,
            standardOffer.amount,
            0,
            true,
            "SellLimit too small"
        );
    }
    function test_RevertWhen_BuyIfOfferorHasDividendToCollect() public {
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );
        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        _createPayment(InvestorJanice, _licenseHash);
        _investorBuysSomeShares(
            InvestorMark,
            addressBilbo,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            true,
            "Offeror has dividend to pay"
        );
    }

    function test_RevertWhen_BuyIfBuyerHasDividendToCollect() public {
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );

        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        _createPayment(InvestorJanice, _licenseHash);
        assetInstance.payDividend(addressBilbo);

        _investorBuysSomeShares(
            addressMike,
            addressBilbo,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            true,
            "Buyer has dividend to pay"
        );
    }

    function test_RevertWhen_BuyIfPrivilegedOfferorHasFeesToCollect() public {
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );
        _investorBuysSomeShares(
            InvestorMark,
            addressBilbo,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        _investorBuysSomeShares(
            InvestorBob,
            InvestorMark,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        _investorBuysSomeShares(
            InvestorMark,
            addressBilbo,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            true,
            "Privileged Offeror has fees to collect"
        );
    }

    function test_RevertWhen_BuyIfPrivilegedBuyerHasFeesToCollect() public {
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );
        _investorBuysSomeShares(
            InvestorMark,
            addressBilbo,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        _investorBuysSomeShares(
            InvestorBob,
            InvestorMark,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        _investorBuysSomeShares(
            addressMike,
            InvestorBob,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            true,
            "Privileged Buyer has fees to collect"
        );
    }

    function test_RevertWhen_BuyIfSentNotEnoughEther() public {
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );

        uint256 index = assetInstance.getOffersIndex(addressBilbo);
        Asset_Structs.Offer memory offer = assetInstance.getOffer(index);

        uint256 pricePerShareToPay = uint256(offer.value) +
            uint256(offer.privilegedFee) +
            uint256(offer.ownerFee);

        vm.expectRevert("Wrong ether amount");
        vm.startPrank(InvestorMark);
        assetInstance.buyShares{
            value: pricePerShareToPay * standardBuyValues.amount - 1
        }(
            addressBilbo,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit
        );
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   payEarndFeesToAllPrivileged              //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function testPayFeesForPrivileged() public {
        _prepareFor_testPayFeesForPrivileged();
        uint256 addressMikeBalanceBefore = assetInstance.getBalance(
            addressMike
        );
        uint256 addressMikeFeeBefore = assetInstance.getPrivilegedFees(
            addressMike
        );
        console.log("addressMikeBalanceBefore", addressMikeBalanceBefore);
        console.log("addressMikeFeeBefore", addressMikeFeeBefore);

        assetInstance.payEarndFeesToAllPrivileged();
        uint256 addressMikeBalanceAfter = assetInstance.getBalance(addressMike);
        uint256 addressMikeFeeAfter = assetInstance.getPrivilegedFees(
            addressMike
        );
        console.log("addressMikeBalanceAfter", addressMikeBalanceAfter);
        console.log("addressMikeFeeAfter", addressMikeFeeAfter);

        assertEq(addressMikeBalanceBefore, addressMikeFeeAfter);
        assertEq(addressMikeFeeBefore, addressMikeBalanceAfter);
    }

    function test_GasLimitTooLowWhilePayFeesForPrivileged() public {
        uint256 gasForOneIteration = 29000;
        uint256 gasNeededBeforeLoop = 8_000;
        uint256 gasNeededAfterLoop = 5_000;
        uint24 numberOfShareholders = 10;
        address _addrAsset = _createAssetWithXNumerOfShareholders(
            numberOfShareholders,
            "Paradise"
        );
        uint256 gasLimitSufficient = gasNeededBeforeLoop +
            gasForOneIteration *
            numberOfShareholders +
            gasNeededAfterLoop;
        uint256 gasLimitUnsufficient = gasLimitSufficient -
            3 *
            gasForOneIteration;
        _prepareFor_testPayFeesForPrivileged_InSpecificAsset(_addrAsset);

        (bool ok, bytes memory data) = _addrAsset.call{
            gas: gasLimitUnsufficient
        }(abi.encodeWithSignature("payEarndFeesToAllPrivileged()"));
        assert(!ok);
        if (!ok) {
            bytes32 returnValue = _decodeError(data);
            bytes32 expectedResult = bytes32(
                abi.encodePacked("Not enough gas")
            );
            assertEq(returnValue, expectedResult);
        }
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   withdraw                                 //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function testWithdrawForPrivileged() public {
        _prepareFor_WithdrawForPrivileged();

        // uint256 addressMikeMainBalanceBefore = addressMike.balance;
        // console.log(
        //     "addressMikeMainBalanceBefore",
        //     addressMikeMainBalanceBefore
        // );
        // uint256 addressMikeBalanceInAssetBefore = assetInstance.getBalance(
        //     addressMike
        // );
        // vm.startPrank(addressMike);
        // assetInstance.withdraw(addressMikeBalanceInAssetBefore);

        // uint256 addressMikeMainBalanceInWalletAfter = addressMike.balance;
        // console.log(
        //     "addressMikeMainBalanceAfter ",
        //     addressMikeMainBalanceInWalletAfter
        // );
        // assertEq(
        //     (addressMikeBalanceInAssetBefore + startWalletBalance),
        //     addressMikeMainBalanceInWalletAfter
        // );
        ////////////////////////////////////////////////////////////
        uint256 addressBilboMainBalanceBefore = addressBilbo.balance;
        console.log(
            "addressBilboMainBalanceBefore",
            addressBilboMainBalanceBefore
        );
        uint256 addressBilboBalanceInAssetBefore = assetInstance.getBalance(
            addressBilbo
        );
        vm.startPrank(addressBilbo);
        vm.expectRevert(
            abi.encodeWithSelector(
                AssetInstanceErrors.WithdrawLockActive.selector
            )
        );
        assetInstance.withdraw(addressBilboBalanceInAssetBefore);

        vm.roll(block.number + WITHDRAW_LOCK_PERIOD + 1);
        assetInstance.withdraw(addressBilboBalanceInAssetBefore);

        uint256 addressBilboMainBalanceInWalletAfter = addressBilbo.balance;
        console.log(
            "addressBilboMainBalanceAfter ",
            addressBilboMainBalanceInWalletAfter
        );
        assertEq(
            (addressBilboBalanceInAssetBefore + startWalletBalance),
            addressBilboMainBalanceInWalletAfter
        );
    }

    function test_RevertWhen_InsufficientBalance() public {
        _prepareFor_testPayFeesForPrivileged();
        uint256 _balance = assetInstance.getBalance(InvestorMark);
        vm.expectRevert("Insufficient balance");
        vm.prank(InvestorMark);
        assetInstance.withdraw(_balance + 1);
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   changeOffer                              //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function testChangeOffer() public {
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );

        _investorBuysSomeShares(
            InvestorMark,
            addressBilbo,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );

        uint256 index = assetInstance.getOffersIndex(InvestorMark);
        assert(index != 0);
        Asset_Structs.Offer memory offer = assetInstance.getOffer(index);
        uint96 valueBefore = offer.value;

        vm.prank(InvestorMark);
        assetInstance.changeOffer(standardBuyValues.newSellLimit + 100);

        offer = assetInstance.getOffer(index);
        uint96 valueAfter = offer.value;

        assertEq(valueBefore + 100, valueAfter);
    }

    function test_RevertWhen_NoOffers() public {
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );

        _investorBuysSomeShares(
            InvestorJanice,
            addressBilbo,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        vm.expectRevert("No offers");
        vm.prank(InvestorMark);
        assetInstance.changeOffer(standardBuyValues.newSellLimit);
    }

    function test_RevertWhen_SellLimitTooSmall() public {
        _createOfferFromPrivileged(
            addressBilbo,
            standardOffer.amount,
            standardOffer.value
        );

        _investorBuysSomeShares(
            InvestorMark,
            addressBilbo,
            standardBuyValues.amount,
            standardBuyValues.newSellLimit,
            false,
            ""
        );
        vm.expectRevert("SellLimit too small");
        vm.prank(InvestorMark);
        assetInstance.changeOffer(MIN_SELL_OFFER - 1);
    }
    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   putNewLicense                            //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function testCreateLicense() public {
        _createLicense(addressMike, false, "");
        Asset_Structs.License memory _license = assetInstance.getLicense(1);
        console.log("licenseHash: ", _bytes32ToString(_license.licenseHash));
        console.log("value: ", _license.value);
        assertEq(_license.value, licenseValue);
    }

    function test_RevertWhen_TryToCreateLicenseAndNotPrivileged() public {
        _createLicense(InvestorBob, true, "Not privileged");
    }

    function test_RevertWhen_TryToBuyLicenseButItAlreadyExists() public {
        bytes32 _licenseHash = _createLicense(addressMike, false, "");

        vm.startPrank(addressMike);
        vm.expectRevert("This license exists");
        assetInstance.putNewLicense(_licenseHash, licenseValue);
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   activateLicense                          //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function testActivateLicense() public {
        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        uint256 _index = assetInstance.getLicensesIndex(_licenseHash);
        assert(_index != 0);

        Asset_Structs.License memory _license = assetInstance.getLicense(
            _index
        );
        bool isActiveBefore = _license.active;

        vm.expectEmit(true, false, false, true);
        emit LicenseDeactivated(addressMike, _licenseHash);
        vm.prank(addressMike);
        assetInstance.activateLicense(_licenseHash, false);

        _license = assetInstance.getLicense(_index);
        bool isActiveAfter = _license.active;

        assertNotEq(isActiveBefore, isActiveAfter);

        vm.expectEmit(true, false, false, true);
        emit LicenseActivated(addressMike, _licenseHash);
        vm.prank(addressMike);
        assetInstance.activateLicense(_licenseHash, true);

        _license = assetInstance.getLicense(_index);
        bool isActiveAfter_2 = _license.active;
        assertNotEq(isActiveAfter, isActiveAfter_2);
    }

    function test_RevertWhen_TryToActivateAndNotPrivileged() public {
        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        uint256 _index = assetInstance.getLicensesIndex(_licenseHash);
        assert(_index != 0);

        vm.startPrank(InvestorBob);
        vm.expectRevert("Not privileged");
        assetInstance.activateLicense(_licenseHash, false);
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   signLicense                              //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function testSignLicense() public {
        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        vm.expectEmit(true, false, false, true);
        emit NewPayment(InvestorMark, _licenseHash);
        _createPayment(InvestorMark, _licenseHash);
        Asset_Structs.Payment memory tempPayment = assetInstance.getPayment(1);
        assertEq(licenseValue, tempPayment.paymentValue);
        assertEq(assetInstance.getPaymentsLength(), 1);
    }

    function testSignMultipleLicenseInOneBlock() public {
        uint256 warpValue = 1641070800;
        vm.warp(warpValue);
        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        _createPayment(InvestorMark, _licenseHash);
        _createPayment(InvestorMark, _licenseHash);
        _createPayment(InvestorMark, _licenseHash);
        Asset_Structs.Payment memory tempPayment_1 = assetInstance.getPayment(
            1
        );
        Asset_Structs.Payment memory tempPayment_2 = assetInstance.getPayment(
            2
        );
        Asset_Structs.Payment memory tempPayment_3 = assetInstance.getPayment(
            3
        );
        uint256 date_1 = uint256(tempPayment_1.date);
        uint256 date_2 = uint256(tempPayment_2.date);
        uint256 date_3 = uint256(tempPayment_3.date);
        assertNotEq(date_1, date_2);
        assertNotEq(date_1, date_3);
        assertNotEq(date_2, date_3);
        assertEq(warpValue, date_1);
        assertEq(warpValue + 1, date_2);
        assertEq(warpValue + 2, date_3);
    }

    function test_RevertWhen_TryToSignLicenseWhenDoesntExist() public {
        bytes32 _licenseHash = keccak256(abi.encode("fake license"));
        vm.startPrank(InvestorBob);
        string memory sig = "signLicense(bytes32)";
        (bool ok, bytes memory data) = address(assetInstance).call{
            value: licenseValue
        }(abi.encodeWithSignature(sig, _licenseHash));
        assert(!ok);
        if (!ok) {
            bytes32 returnValue = _decodeError(data);
            bytes32 expectedResult = bytes32(abi.encodePacked("Doesn't exist"));
            assertEq(returnValue, expectedResult);
        }
        vm.stopPrank();
    }

    function test_RevertWhen_TryToSignLicenseWhenNotActive() public {
        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        vm.prank(addressMike);
        assetInstance.activateLicense(_licenseHash, false);

        vm.startPrank(InvestorBob);
        string memory sig = "signLicense(bytes32)";
        (bool ok, bytes memory data) = address(assetInstance).call{
            value: licenseValue
        }(abi.encodeWithSignature(sig, _licenseHash));
        assert(!ok);
        if (!ok) {
            bytes32 returnValue = _decodeError(data);
            bytes32 expectedResult = bytes32(abi.encodePacked("Not active"));
            assertEq(returnValue, expectedResult);
        }
        vm.stopPrank();
    }

    function test_RevertWhen_TryToSignLicenseWhenNotEnoughtEther() public {
        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        vm.startPrank(InvestorBob);
        string memory sig = "signLicense(bytes32)";
        (bool ok, bytes memory data) = address(assetInstance).call{
            value: licenseValue - 1
        }(abi.encodeWithSignature(sig, _licenseHash));
        assert(!ok);
        if (!ok) {
            bytes32 returnValue = _decodeError(data);
            bytes32 expectedResult = bytes32(abi.encodePacked("Not enough"));
            assertEq(returnValue, expectedResult);
        }
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   payDividend                              //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function testAddrHasDividendToPay() public view {
        (uint256 value, uint256 howMany) = assetInstance.getDividendToPay(
            addressMike
        );
        console.log("howMany value: ", howMany, uint256(value));
        assertEq(howMany, 0);
    }

    function test_TryPayDividend() public {
        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        vm.warp(1641070800);
        _createPayment(InvestorJanice, _licenseHash);
        vm.warp(1641070800 + 100);
        _createPayment(InvestorJanice, _licenseHash);
        vm.warp(1641070800 + 200);
        _createPayment(InvestorJanice, _licenseHash);
        vm.warp(1641070800 + 300);

        (uint256 valueDividendBefore, uint256 howManyBefore) = assetInstance
            .getDividendToPay(addressBilbo);
        console.log(
            "valueDividendBefore howManyBefore",
            uint256(valueDividendBefore),
            howManyBefore
        );
        uint256 userBalanceBefore = assetInstance.getBalance(addressBilbo);
        console.log("userBalanceBefore", userBalanceBefore);

        vm.expectEmit(true, false, false, true);
        emit DividendPaid(addressBilbo, valueDividendBefore, 3);
        assetInstance.payDividend(addressBilbo);

        (uint256 valueDividendAfter, uint256 howManyAfter) = assetInstance
            .getDividendToPay(addressBilbo);
        console.log(
            "valueDividendAfter howManyAfter",
            valueDividendAfter,
            howManyAfter
        );
        uint256 userBalanceAfter = assetInstance.getBalance(addressBilbo);
        console.log("userBalanceAfter", userBalanceAfter);

        assertEq(userBalanceAfter, valueDividendBefore);
        assertEq(userBalanceBefore, valueDividendAfter);
    }

    function testPayDividend() public {
        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        (uint256 dividend_1_Before, uint256 howMany_1_Before) = assetInstance
            .getDividendToPay(addressMike);
        (uint256 dividend_2_Before, uint256 howMany_2_Before) = assetInstance
            .getDividendToPay(addressBilbo);
        assert(dividend_1_Before == 0);
        assert(dividend_2_Before == 0);
        assert(howMany_1_Before == 0);
        assert(howMany_2_Before == 0);

        _createPayment(InvestorMark, _licenseHash);
        (uint256 dividend_1_After, uint256 howMany_1_After) = assetInstance
            .getDividendToPay(addressMike);
        (uint256 dividend_2_After, uint256 howMany_2_After) = assetInstance
            .getDividendToPay(addressBilbo);

        console.log(
            "dividend_1_After howMany_1_After",
            dividend_1_After,
            howMany_1_After
        );
        console.log(
            "dividend_2_After howMany_2_After",
            dividend_2_After,
            howMany_2_After
        );
        console.log(
            "reminder",
            licenseValue - (dividend_1_After + dividend_2_After)
        );

        assertLe(
            (licenseValue - (dividend_1_After + dividend_2_After)),
            ACCEPTABLE_REMINDER
        );
    }

    function test_RevertWhen_PayDividendNotShareholder() public {
        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        _createPayment(InvestorMark, _licenseHash);
        vm.expectRevert("Not a shareholder");
        assetInstance.payDividend(InvestorMark);
    }

    function test_RevertWhen_PayDividendNoPayments() public {
        vm.expectRevert("No payments");
        assetInstance.payDividend(addressMike);
    }

    function test_RevertWhen_PayDividendNoDividends() public {
        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        _createPayment(InvestorMark, _licenseHash);
        assetInstance.payDividend(addressMike);
        vm.expectRevert("No dividends");
        assetInstance.payDividend(addressMike);
    }

    function testPayDividendPartly() public {
        //1236 gas per console.log("xx", gasleft())
        uint256 gasForOneIteration = 1670; // value from console
        uint256 gasNeededOutsideLoop = 59_000 + 20000; // value from console
        uint24 numberOfPayments = 4;

        bytes32 _licenseHash = _createLicense(addressMike, false, "");
        for (uint i = 0; i < numberOfPayments; i++) {
            _createPayment(InvestorMark, _licenseHash);
        }

        uint256 gasLimitSufficient = gasNeededOutsideLoop +
            gasForOneIteration *
            numberOfPayments;
        uint256 gasLimitUnsufficient = gasLimitSufficient -
            1 *
            gasForOneIteration;

        // vm.expectEmit(true, false, false, true);
        // emit DividendPaidOnlyPartly(
        //     addressMike,
        //     (licenseValue * shareMike) / TOTAL_SUPPLY,
        //     numberOfPayments - 1
        // );
        (bool ok, ) = address(assetInstance).call{gas: gasLimitUnsufficient}(
            abi.encodeWithSignature("payDividend(address)", addressMike)
        );
        console.log(ok);
        // (, uint256 howMany_2_After) = assetInstance.getDividendToPay(addressMike);
        // console.log(howMany_2_After);

        // assert(ok);
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   nextFunction                             //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////
}
