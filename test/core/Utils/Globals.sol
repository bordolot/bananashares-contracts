//SPDX-License-Identifier: NONE
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {AssetInstanceConst} from "../../../src/core/util/AssetInstanceConst.sol";
import {AssetFactoryConst} from "../../../src/core/util/AssetFactoryConst.sol";
import {BananasharesDeploySettings} from "../../../script/BananasharesDeploySettings.sol";

contract Globals is
    AssetInstanceConst,
    AssetFactoryConst,
    Test,
    BananasharesDeploySettings
{
    struct TestAsset {
        string nameOfAsset;
        string[] authors;
        address[] shareholderAddress;
        uint24[] shares;
        bytes32 assetHash;
    }

    struct StandardOffer {
        uint24 amount;
        uint96 value;
    }

    struct StandardBuyValues {
        uint24 amount;
        uint96 newSellLimit;
    }

    struct Proposal {
        address[] _targets;
        uint256[] _values;
        bytes[] _calldatas;
        string _description;
    }

    // Protocol constants
    // read from AssetInstanceConst

    // Deployment settings
    // read from BananasharesDeploySettings

    // Tests constants
    uint24 constant ACCEPTABLE_REMINDER = 100;
    uint24 constant FIRST_SHAREHOLDER_MAX_SHARES = 600_000;
    uint256 constant ETHER_FOR_ACTOR = 100 ether;

    // Tests Foundry statefull and stateless fuzzing
    uint8 constant NUMBER_OF_ASSETS_IN_TEST_CALL = 1;
    uint96 constant MAX_SELL_OFFER = type(uint96).max;
    uint24 constant MIN_AMOUNT_IN_OFFER = 1;
    // uint24 constant MAX_AMOUNT_IN_OFFER = 10;
    /// @dev 20 means that 20% of all calls should be performed by privileged shareholders.
    /// @dev This value should be set between 0 and 100.
    uint8 constant PRIVILEGED_ALL_RATIO = 20;
    /// @dev 40 means that 40% of calls made by not a privileged users should be performed by normal shareholders. The rest calls are made by 'fresh' users.
    /// @dev A fresh user is an address that does not own any shares.
    /// @dev This value should be set between 0 and 100.
    uint8 constant NORMAL_FRESH_RATIO = 70;
    /// @dev 70 means that 70% of _amount in buyShares() calls are set correct.
    /// @dev This value should be set between 0 and 100.
    uint8 constant HOW_OFTEN_CORRECT_AMOUNT = 70;
    /// @dev 80 means that 80% of msg.value in buyShares() calls are set correct.
    /// @dev This value should be set between 0 and 100.
    uint8 constant HOW_OFTEN_CORRECT_MSGVALUE = 80;
    /// @dev 90 means that 90% of _sellLimit in buyShares() calls are set correct.
    /// @dev This value should be set between 0 and 100.
    uint8 constant HOW_OFTEN_CORRECT_SELLLIMIT = 90;
    /// @dev 90 means that 90% of _amount in withdraw() calls are set correct.
    /// @dev This value should be set between 0 and 100.
    uint8 constant HOW_OFTEN_CORRECT_WITHDRAW = 90;
    /// @dev 70 means that 70% of calls are moved over `WITHDRAW_LOCK_PERIOD`.
    /// @dev This value should be set between 0 and 100.
    uint8 constant HOW_OFTEN_BLOCK_NR_MOVED_ABOVE_LOCK_PERIOD = 70;
    /// @dev 10 means that 10% of _licenseHash in putNewLicense() will be already created if there any active licenses.
    /// @dev This value should be set between 0 and 100.
    uint8 constant HOW_OFTEN_CREATED_LICENSE = 90;
    /// @dev 80 means that 80% likelihood of setting correct msg.value in signLicense().
    /// @dev This value should be set between 0 and 100.
    uint8 constant HOW_OFTEN_CORRECT_LICENSE_VALUE = 80;
    /// @dev 60 means that 60% likelihood of setting correct _addr in payDividend().
    /// @dev This value should be set between 0 and 100.
    uint8 constant HOW_OFTEN_CORRECT_DIVIDEND_RECEIVER = 60;
    /// @dev 10 means that 10% likelihood of setting in a range that can cause DividendPaidOnlyPartly or GasLimitTooLow event in payDividend() or payEarndFeesToAllPrivileged().
    /// @dev This value should be set between 0 and 100.
    uint8 constant HOW_OFTEN_GAS_IS_SET_LOW = 10;

    //Other constants
    /// @dev look at PRIVILEGED_ALL_RATIO
    uint8 constant THRESHOLD_1 =
        uint8((type(uint8).max / 100) * PRIVILEGED_ALL_RATIO);
    /// @dev look at NORMAL_FRESH_RATIO
    uint8 constant THRESHOLD_2 =
        uint8(((type(uint8).max - THRESHOLD_1) / 100) * NORMAL_FRESH_RATIO);
    /// @dev look at HOW_OFTEN_CORRECT_AMOUNT
    uint8 constant THRESHOLD_AMOUNT =
        uint8((type(uint8).max / 100) * HOW_OFTEN_CORRECT_AMOUNT);
    /// @dev look at HOW_OFTEN_CORRECT_MSGVALUE
    uint8 constant THRESHOLD_MSGVALUE =
        uint8((type(uint8).max / 100) * HOW_OFTEN_CORRECT_MSGVALUE);
    /// @dev look at HOW_OFTEN_CORRECT_SELLLIMIT
    uint8 constant THRESHOLD_SELLLIMIT =
        uint8((type(uint8).max / 100) * HOW_OFTEN_CORRECT_SELLLIMIT);
    /// @dev look at HOW_OFTEN_CORRECT_WITHDRAW
    uint8 constant THRESHOLD_WITHDRAW =
        uint8((type(uint8).max / 100) * HOW_OFTEN_CORRECT_WITHDRAW);
    /// @dev look at HOW_OFTEN_BLOCK_NR_MOVED_ABOVE_LOCK_PERIOD
    uint8 constant THRESHOLD_BLOCK_NR_MOVED =
        uint8(
            (type(uint8).max / 100) * HOW_OFTEN_BLOCK_NR_MOVED_ABOVE_LOCK_PERIOD
        );
    /// @dev look at HOW_OFTEN_CREATED_LICENSE
    uint8 constant THRESHOLD_CREATED_LICENSE =
        uint8((type(uint8).max / 100) * HOW_OFTEN_CREATED_LICENSE);
    /// @dev look at HOW_OFTEN_CORRECT_LICENSE_VALUE
    uint8 constant THRESHOLD_LICENSE_VALUE =
        uint8((type(uint8).max / 100) * HOW_OFTEN_CORRECT_LICENSE_VALUE);
    /// @dev look at HOW_OFTEN_CORRECT_DIVIDEND_RECEIVER
    uint8 constant THRESHOLD_DIVIDEND_RECEIVER =
        uint8((type(uint8).max / 100) * HOW_OFTEN_CORRECT_DIVIDEND_RECEIVER);
    /// @dev look at HOW_OFTEN_GAS_IS_SET_LOW
    uint8 constant THRESHOLD_GAS_IS_SET_LOW =
        uint8((type(uint8).max / 100) * HOW_OFTEN_GAS_IS_SET_LOW);

    /// @dev Constant for HandlersS-Less.sol in bounding gas limit for transaction. It adds and subtract from GAS_LIMIT or GAS_LIMIT_FEES.
    uint24 constant GAS_LIMIT_RANGE = 1_000;

    function _uintToString(
        uint8 _input
    ) internal pure returns (string memory result) {
        bytes memory buffer = new bytes(1);
        buffer[0] = bytes1(_input);
        result = string(buffer);
    }

    function _uintToStringFull(
        uint256 value
    ) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _splitString(
        string memory str
    ) internal pure returns (string[] memory) {
        // Count the number of _words in the string.
        uint256 _wordCount = 1;
        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == " ") {
                _wordCount++;
            }
        }

        // Initialize an array to hold the _words.
        string[] memory _words = new string[](_wordCount);

        uint256 _wordIndex = 0;
        bytes memory _word = new bytes(bytes(str).length);

        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] != " ") {
                _word[_wordIndex] = bytes(str)[i];
                _wordIndex++;
            } else {
                _words[--_wordCount] = string(_word);
                _word = new bytes(bytes(str).length);
                _wordIndex = 0;
            }
        }
        _words[--_wordCount] = string(_word);

        return _words;
    }

    /// @notice This is one of two methods of creating random seed in tests.
    /// @dev You must each test with `--ffi` flag
    /// @dev Put in your code `uint256 pcTimestamp = _generateSeed();`
    /// @dev The alternative is to run before each test `export RANDOM_SEED=$(date +%s)` in your console
    /// @dev Put in your code `uint256 pcTimestamp = vm.envUint("RANDOM_SEED");`
    function _generateSeed() internal returns (uint256) {
        string[] memory cmds = new string[](3);
        bytes memory output;

        cmds[0] = "bash";
        cmds[1] = "-c"; // Allows passing a single command as an argument
        cmds[2] = "date +%s"; // Directly get the Unix timestamp
        output = vm.ffi(cmds);

        require(output.length <= 32, "Data too long to fit into uint256");

        uint256 seed = 0;
        for (uint256 i = 0; i < output.length; i++) {
            seed |= uint256(uint8(output[i])) << (8 * (output.length - 1 - i));
        }

        return seed;
    }
}
