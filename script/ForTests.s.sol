// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;
//@TODO change inport to "/forge-std/Script.sol";
import {Script, console2} from "../lib/forge-std/src/Script.sol";

import {IAssetFactory} from "../src/core/util/IAssetFactory.sol";
import {IAssetInstance} from "../src/core/util/IAssetInstance.sol";
import {Asset_Structs} from "../src/core/util/AssetInstanceStructs.sol";

contract ForTestsScript is Script {
    struct TestAsset {
        string nameOfAsset;
        string[] authors;
        address[] shareholderAddress;
        uint24[] shares;
        bytes32 assetHash;
    }

    struct StandardBuyValues {
        uint24 amount;
        uint96 newSellLimit;
    }

    struct TestOffer {
        uint24 amount;
        uint96 value;
    }

    struct StandardLicense {
        bytes32 licenseHash;
        uint256 licenseValue;
    }

    uint testPrivateKey = vm.envUint("TEST_PRIVATE_KEY");
    address god = address(0xA07e32bD82f9Ba911D45dA8cA5f6659eC6ae18EC);
    uint devPrivateKey = vm.envUint("DEV_PRIVATE_KEY");

    address PrivShareholderBilbo =
        address(0x34ED3B32B7d880361baD54bA9dEE3b9601B13103);
    uint256 privateKeyBilbo =
        81331330733352418677369874335159751743837942506247258398360323276233500598630;

    address PrivShareholderVoldemort =
        address(0xA08c12B354C708FE0fb3da491544d736b78fD4c8);
    uint256 privateKeyVoldemort =
        95763821202874919869441305293861788809198355907900158181261698489047693369433;

    address PrivShareholderSauron =
        address(0x9882Bf6692a11D4472b53C333AC36F6d1c435557);
    uint256 privateKeySauron =
        113958531888861830023945330284844580224303179342660316297404096256704749312157;

    address InvestorMark = address(0x1105e100448F237e93B6E48D7cef177a98e13Efb);
    uint256 privateKeyMark =
        22551718169398482611810602726502100416451823225805576406984255054387854130303;

    address InvestorBob = address(0x4dBa461cA9342F4A6Cf942aBd7eacf8AE259108C);
    uint256 privateKeyBob =
        18450763555729348787262135514425215427602321247876461995109591283836524067254;

    address InvestorJanice =
        address(0xDF5793C915FE74c35D8DA81A68636849b0FFe742);
    uint256 privateKeyJanice =
        94828747394690579249756711637816153451200346692178810666426884872712917348370;

    address[] addresses;
    // address addresses[_addrNr] = address(0xD128adF57CF93fd2259D7d0164966DE471a33d63);

    uint24 testAmuontForSale = 10_000;
    uint96 testValuePerShare = 1e14;

    StandardBuyValues standardBuyValues =
        StandardBuyValues({amount: 1_00, newSellLimit: 2e14});

    TestOffer testOffer =
        TestOffer({amount: testAmuontForSale, value: testValuePerShare});

    uint256 testLicenseValue = 0.01 ether;

    function setUp() public {
        if (addresses.length == 0) {
            addresses.push(address(0x8aCd85898458400f7Db866d53FCFF6f0D49741FF));
            addresses.push(address(0xe082b26cEf079a095147F35c9647eC97c2401B83));
        }
    }

    function _createTestAsset(
        address payable _AssetsFactory,
        uint256 _assetVariation
    ) private {
        IAssetFactory testAssetsFactory = IAssetFactory(_AssetsFactory);
        TestAsset memory testAsset;
        string[] memory authors = new string[](2);
        address[] memory testAddresses = new address[](2);
        uint24[] memory shares = new uint24[](2);

        if (_assetVariation == 1) {
            authors[0] = "Mike Bolt";
            authors[1] = "Bilbo Baggins";
            testAddresses[0] = god;
            testAddresses[1] = PrivShareholderBilbo;
            shares[0] = 500_000;
            shares[1] = 500_000;
            testAsset = TestAsset({
                nameOfAsset: "Bohemian rapsody",
                authors: authors,
                shareholderAddress: testAddresses,
                shares: shares,
                assetHash: 0x1234567812345678123456781234567812345678123456781234567812345678
            });
        } else {
            authors[0] = "Voldemort";
            authors[1] = "Sauron";
            testAddresses[0] = PrivShareholderVoldemort;
            testAddresses[1] = PrivShareholderSauron;
            shares[0] = 600_000;
            shares[1] = 400_000;
            testAsset = TestAsset({
                nameOfAsset: "Mamma Mia",
                authors: authors,
                shareholderAddress: testAddresses,
                shares: shares,
                assetHash: 0x2234567812345678123456781234567812345678123456781234567887654322
            });
        }

        vm.broadcast(privateKeyBilbo);
        testAssetsFactory.createAssetInstance(
            testAsset.nameOfAsset,
            testAsset.authors,
            testAsset.shareholderAddress,
            testAsset.shares,
            testAsset.assetHash
        );
        address testAssetAddress;
        testAssetAddress = testAssetsFactory.getAssetInstanceByHash(
            testAsset.assetHash
        );
        console2.log("testAssetAddress address: ", testAssetAddress);
        console2.log("--------------------------------------------------");

        addresses.push(testAssetAddress);
    }

    function _getCurrentPrivShareholder(
        uint256 _assetAddr
    )
        internal
        view
        returns (address _thisPrivShareholder, uint256 _thisPrivShareholderKey)
    {
        if (_assetAddr == 0) {
            _thisPrivShareholder = PrivShareholderBilbo;
            _thisPrivShareholderKey = privateKeyBilbo;
        } else {
            _thisPrivShareholder = PrivShareholderVoldemort;
            _thisPrivShareholderKey = privateKeyVoldemort;
        }
    }

    function _createTestAssetFullShareholders(
        address payable _AssetsFactory
    ) private {
        IAssetFactory testAssetsFactory = IAssetFactory(_AssetsFactory);
        TestAsset memory testAsset;
        string[] memory authors = new string[](10);
        address[] memory testAddresses = new address[](10);
        uint24[] memory shares = new uint24[](10);

        authors[0] = "Mike Bolt";
        authors[1] = "Bilbo Baggins";
        authors[2] = "author 3";
        authors[3] = "author 4";
        authors[4] = "author 5";
        authors[5] = "author 6";
        authors[6] = "author 7";
        authors[7] = "author 8";
        authors[8] = "author 9";
        authors[9] = "author 10";
        testAddresses[0] = god;
        testAddresses[1] = PrivShareholderBilbo;
        testAddresses[2] = makeAddr("author 3");
        testAddresses[3] = makeAddr("author 4");
        testAddresses[4] = makeAddr("author 5");
        testAddresses[5] = makeAddr("author 6");
        testAddresses[6] = makeAddr("author 7");
        testAddresses[7] = makeAddr("author 8");
        testAddresses[8] = makeAddr("author 9");
        testAddresses[9] = makeAddr("author 10");

        shares[0] = 100_000;
        shares[1] = 100_000;
        shares[2] = 100_000;
        shares[3] = 100_000;
        shares[4] = 100_000;
        shares[5] = 100_000;
        shares[6] = 100_000;
        shares[7] = 100_000;
        shares[8] = 100_000;
        shares[9] = 100_000;
        testAsset = TestAsset({
            nameOfAsset: "Bohemian rapsody",
            authors: authors,
            shareholderAddress: testAddresses,
            shares: shares,
            assetHash: 0x1234567812345678123456781234567812345678123456781234567812345999
        });

        vm.broadcast(devPrivateKey);
        testAssetsFactory.createAssetInstance(
            testAsset.nameOfAsset,
            testAsset.authors,
            testAsset.shareholderAddress,
            testAsset.shares,
            testAsset.assetHash
        );
        address testAssetAddress;
        testAssetAddress = testAssetsFactory.getAssetInstanceByHash(
            testAsset.assetHash
        );
        console2.log("testAssetAddress address: ", testAssetAddress);
        console2.log("--------------------------------------------------");

        addresses.push(testAssetAddress);
    }

    function try_createOffer(uint256 _addrNr, uint256 _by_privateKey) public {
        vm.broadcast(_by_privateKey);
        IAssetInstance(addresses[_addrNr]).makeSellOffer(
            testOffer.amount,
            testOffer.value
        );
    }

    function try_createOffer_2(
        uint256 _addrNr,
        uint256 _by_privateKey,
        uint24 _amount,
        uint96 _value
    ) public {
        vm.broadcast(_by_privateKey);
        IAssetInstance(addresses[_addrNr]).makeSellOffer(_amount, _value);
    }

    function try_buyShares(
        uint256 _addrNr,
        uint256 _by_privateKey,
        address _from,
        uint24 _amount,
        uint96 _sellLimit
    ) public {
        string memory sig = "buyShares(address,uint24,uint96)";
        uint256 index = IAssetInstance(addresses[_addrNr]).getOffersIndex(
            _from
        );
        Asset_Structs.Offer memory offer = IAssetInstance(addresses[_addrNr])
            .getOffer(index);

        uint256 pricePerShareToPay = uint256(offer.value) +
            uint256(offer.privilegedFee) +
            uint256(offer.ownerFee);

        vm.broadcast(_by_privateKey);
        (bool ok, ) = addresses[_addrNr].call{
            value: pricePerShareToPay * _amount
        }(abi.encodeWithSignature(sig, _from, _amount, _sellLimit));
        assert(ok);
    }

    function try_buyShares_2(
        address _addr,
        uint256 _by_privateKey,
        address _from,
        uint24 _amount,
        uint96 _sellLimit
    ) public {
        string memory sig = "buyShares(address,uint24,uint96)";
        uint256 index = IAssetInstance(_addr).getOffersIndex(_from);
        Asset_Structs.Offer memory offer = IAssetInstance(_addr).getOffer(
            index
        );

        uint256 pricePerShareToPay = uint256(offer.value) +
            uint256(offer.privilegedFee) +
            uint256(offer.ownerFee);

        vm.broadcast(_by_privateKey);
        (bool ok, ) = _addr.call{value: pricePerShareToPay * _amount}(
            abi.encodeWithSignature(sig, _from, _amount, _sellLimit)
        );
        assert(ok);
    }

    function try_getOffer(uint256 _addrNr, address _from) public view {
        uint256 index = IAssetInstance(addresses[_addrNr]).getOffersIndex(
            _from
        );
        console2.log("getOffer index:", index);
        Asset_Structs.Offer memory offer = IAssetInstance(addresses[_addrNr])
            .getOffer(index);
        uint24 amount = offer.amount;
        console2.log("getOffer amount:", amount);
    }

    function try_getFees(uint256 _addrNr) public view {
        uint256 fee1 = IAssetInstance(addresses[_addrNr]).getPrivilegedFees(
            god
        );
        uint256 fee2 = IAssetInstance(addresses[_addrNr]).getPrivilegedFees(
            PrivShareholderBilbo
        );
        console2.log("try_getOffer fee1:", fee1);
        console2.log("try_getOffer fee2:", fee2);
        // uint256 feeAll = IAssetInstance(addresses[_addrNr]).getAggregatedPrivilegedFees();
        // console2.log("try_getOffer feeAll:", feeAll);
        console2.log("try_getOffer fee1+fee2:", fee1 + fee2);
    }

    function try_getBalances(uint256 _addrNr) public view {
        uint256 balances1 = IAssetInstance(addresses[_addrNr]).getBalance(god);
        uint256 balances2 = IAssetInstance(addresses[_addrNr]).getBalance(
            PrivShareholderBilbo
        );
        console2.log("try_getOffer balances1:", balances1);
        console2.log("try_getOffer balances2:", balances2);
    }

    function try_getLicense(uint256 _addrNr, uint256 _index) public view {
        uint256 arrayLength = IAssetInstance(addresses[_addrNr])
            .getLicensesLength();
        console2.log("try_getLicense arrayLength:", arrayLength);
        Asset_Structs.License memory license = IAssetInstance(
            addresses[_addrNr]
        ).getLicense(_index);
        console2.log("try_getLicense isActive:", license.active);
        console2.log(
            "try_getLicense licenseHash:",
            uint256(license.licenseHash)
        );
        console2.log("try_getLicense value:", license.value);
    }

    /// @dev Creates three offers from normal users.
    /// @param _assetAddr Specifies which asset address to choose from addresses array
    /// @param _numberOfLicenses Specifies number of new licenses to be created.
    function try_createLicenses(
        uint256 _assetAddr,
        uint256 _numberOfLicenses
    ) public {
        (
            address _thisPrivShareholder,
            uint256 _thisPrivShareholderKey
        ) = _getCurrentPrivShareholder(_assetAddr);
        _thisPrivShareholder;
        string memory sig = "putNewLicense(bytes32,uint224)";
        bytes32 _licenseHashBase = 0x3000000000000000000000000000000000000000000000000000000000000000;
        bytes32 _newLicenseHash;
        uint256 _licenseValue = testLicenseValue;
        StandardLicense memory _newLicense;
        vm.startBroadcast(_thisPrivShareholderKey);
        for (uint i = 0; i < _numberOfLicenses; i++) {
            _newLicenseHash = bytes32(
                uint256(_licenseHashBase) +
                    IAssetInstance(addresses[_assetAddr]).getLicensesLength()
            );
            (bool ok, ) = addresses[_assetAddr].call(
                abi.encodeWithSignature(sig, _newLicenseHash, _licenseValue)
            );
            assert(ok);
            _newLicense = StandardLicense({
                licenseHash: _newLicenseHash,
                licenseValue: _licenseValue
            });
        }

        vm.stopBroadcast();
    }

    function try_activateLicense(uint256 _addrNr) public {
        bytes32 _licenseHash = 0x3000000000000000000000000000000000000000000000000000000000000001;
        vm.startBroadcast(privateKeyMark);
        string memory sig = "activateLicense(bytes32)";
        (bool ok, ) = addresses[_addrNr].call(
            abi.encodeWithSignature(sig, _licenseHash)
        );
        assert(ok);
        vm.stopBroadcast();
    }

    /// @dev Creates three offers from normal users.
    /// @param _assetAddr Specifies which asset address to choose from addresses array
    /// @param _licensePos Specifies which Asset_Structs.License from a Asset to choose to sign.
    function try_signLicense(uint256 _assetAddr, uint256 _licensePos) public {
        uint256 _len = IAssetInstance(addresses[_assetAddr])
            .getLicensesLength();
        if (_len == 1) {
            return;
        }
        if (_len < _licensePos) {
            return;
        }
        Asset_Structs.License memory _choosenLicense = IAssetInstance(
            addresses[_assetAddr]
        ).getLicense(_licensePos);
        vm.startBroadcast(privateKeyMark);
        string memory sig = "signLicense(bytes32)";
        (bool ok, ) = addresses[_assetAddr].call{value: _choosenLicense.value}(
            abi.encodeWithSignature(sig, _choosenLicense.licenseHash)
        );
        assert(ok);
        vm.stopBroadcast();
    }

    /// @dev Creates three offers from normal users.
    /// @param _assetAddr Specifies which asset address to choose from addresses array
    /// @param _licenseHash Specifies license hash.
    /// @param _licenseValue Specifies value to pay.
    function try_signSpecificLicense(
        uint256 _assetAddr,
        bytes32 _licenseHash,
        uint256 _licenseValue
    ) public {
        vm.startBroadcast(privateKeyMark);
        string memory sig = "signLicense(bytes32)";
        (bool ok, ) = addresses[_assetAddr].call{value: _licenseValue}(
            abi.encodeWithSignature(sig, _licenseHash)
        );
        assert(ok);
        vm.stopBroadcast();
    }

    /// @dev Creates three offers from normal users.
    /// @param _assetAddr Specifies which asset address to choose from addresses array
    /// @param _userAddr Specifies which user's dividends are checked.
    function try_CheckDividend(
        uint256 _assetAddr,
        address _userAddr
    ) public view returns (bool areThere) {
        (uint256 value, uint256 howMany) = IAssetInstance(addresses[_assetAddr])
            .getDividendToPay(_userAddr);
        howMany;
        if (value > 0) {
            areThere = true;
        } else {
            areThere = false;
        }
    }

    function try_payDividend(uint256 _addrNr, address _addr) public {
        vm.startBroadcast(privateKeyBilbo);
        string memory sig = "payDividend(address)";
        (bool ok, ) = addresses[_addrNr].call{gas: 500_000}(
            abi.encodeWithSignature(sig, _addr)
        );
        assert(ok);
        vm.stopBroadcast();
    }

    function try_payFees(uint _assetAddr) public {
        vm.startBroadcast(privateKeyBilbo);
        IAssetInstance(addresses[_assetAddr]).payEarndFeesToAllPrivileged{
            gas: 500_000
        }();
        vm.stopBroadcast();
    }

    /// @dev Creates three offers from normal users.
    /// @param _assetAddr Specifies which asset address to choose from addresses (look at starage values) array
    /// @param _colectFees Determines if fees from privileged are collected in the end.
    /// @param _userEndWithDividend Determines if one of users ends with a dividend to collect.
    function callBunchOfBuyShares(
        uint _assetAddr,
        bool _colectFees,
        bool _userEndWithDividend
    ) public {
        (
            address _thisPrivShareholder,
            uint256 _thisPrivShareholderKey
        ) = _getCurrentPrivShareholder(_assetAddr);

        if (_assetAddr == 0) {
            _thisPrivShareholder = PrivShareholderBilbo;
            _thisPrivShareholderKey = privateKeyBilbo;
        } else if (_assetAddr == 1) {
            _thisPrivShareholder = PrivShareholderVoldemort;
            _thisPrivShareholderKey = privateKeyVoldemort;
        }

        try_createOffer(_assetAddr, _thisPrivShareholderKey);
        bool _result = try_CheckDividend(_assetAddr, _thisPrivShareholder);
        if (_result) {
            try_payDividend(_assetAddr, _thisPrivShareholder);
        }
        try_payFees(_assetAddr);
        for (uint i = 0; i < 4; i++) {
            try_buyShares(
                _assetAddr,
                privateKeyJanice, //by(privateKey)
                _thisPrivShareholder, //from(address)
                standardBuyValues.amount,
                standardBuyValues.newSellLimit
            );
        }
        try_buyShares(
            _assetAddr,
            privateKeyMark, //by(privateKey)
            InvestorJanice, //from(address)
            standardBuyValues.amount,
            standardBuyValues.newSellLimit
        );
        try_buyShares(
            _assetAddr,
            privateKeyBob, //by(privateKey)
            InvestorJanice, //from(address)
            standardBuyValues.amount,
            standardBuyValues.newSellLimit
        );
        if (_colectFees) {
            try_payFees(_assetAddr);
        }
        if (_userEndWithDividend) {
            if (
                IAssetInstance(addresses[_assetAddr]).getLicensesLength() == 0
            ) {
                try_createLicenses(_assetAddr, 2);
            }
            try_signLicense(_assetAddr, 1);
            try_payDividend(_assetAddr, InvestorBob);
            try_payDividend(_assetAddr, InvestorMark);
        }
    }

    function run() public {
        // _createTestAsset(
        //     // payable(address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512)),
        //     payable(address(0x8A791620dd6260079BF849Dc5567aDC3F2FdC318)),
        //     1
        // );
        // _createTestAsset(
        //     // payable(address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512)),
        //     payable(address(0x8A791620dd6260079BF849Dc5567aDC3F2FdC318)),
        //     2
        // );
        // _createTestAssetFullShareholders(
        //     payable(address(0x59562521C316c300EAc9860f8f46869C28acd489))
        // );
        // callBunchOfBuyShares(0, false, true);
        // callBunchOfBuyShares(1, false, true);
        // callBunchOfBuyShares(0, true);
        // try_signLicense(0, 0);
        // try_signSpecificLicense(
        //     0,
        //     0x3000000000000000000000000000000000000000000000000000000000000001,
        //     testLicenseValue
        // );
        // try_getOffer(0, PrivShareholderBilbo);
        // try_getFees(0);
        // try_getBalances(0);
        // try_createLicenses(0, 2);
        // for (uint i = 0; i < 5; i++) {
        //     try_signLicense(0);
        // }
        // try_CheckDividend(0, god);
        // try_CheckDividend(0, PrivShareholderBilbo);
        // console2.log(IAssetInstance(addresses[0]).getBalance(god));
        // try_payDividend(0, god);
        // try_getLicense(0, 1); //(addr index), ( license index)
        // try_getLicense(0, 2); //(addr index), ( license index)
        // try_getLicense(0, 3); //(addr index), ( license index)
        // try_buyShares_2(
        //     0x94099942864EA81cCF197E9D71ac53310b1468D8,
        //     privateKeyMark,
        //     god,
        //     2000,
        //     standardBuyValues.newSellLimit
        // );
        // try_createOffer(1, privateKeyVoldemort);
        // try_createOffer_2(1, privateKeyVoldemort, 26666, 1e12);
        try_buyShares(0, privateKeyMark, god, 4000, 2e12);
    }
}
