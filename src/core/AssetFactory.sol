// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {AssetInstanceProxy} from "./AssetInstanceProxy.sol";
import {AssetFactoryEvents} from "./util/AssetFactoryEvents.sol";
import {AssetFactoryErrors} from "./util/AssetFactoryErrors.sol";
import {AssetFactoryStorage} from "./util/AssetFactoryStorage.sol";
import {AssetFactoryMods} from "./util/AssetFactoryMods.sol";
import {Asset_Structs} from "./util/AssetInstanceStructs.sol";

import {IAssetFactory_write} from "./util/IAssetFactory_write.sol";

import {IBananasharesToken} from "../governance/IBananasharesToken.sol";

/**
 *  @title The version 0.1.0 implementation of `AssetFactoryProxy`.
 *
 */

contract AssetFactory is
    UUPSUpgradeable,
    OwnableUpgradeable,
    AssetFactoryStorage,
    AssetFactoryEvents,
    AssetFactoryErrors,
    AssetFactoryMods,
    IAssetFactory_write
{
    //////////////////////////////////////////////////////////////
    //
    // The following functions are overrides required by parent contracts.
    //

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function initialize(
        address _AssetTimelockControllerAddr
    ) public initializer {
        __Ownable_init(_AssetTimelockControllerAddr);
    }

    function reinitialize()
        public
        reinitializer(_getInitializedVersion() + 1)
        onlyOwner
    {}

    //
    // END OF
    // "The following functions are overrides required by parent contracts."
    //
    /////////////////////////////////////////////////////////////////

    constructor(
        address _bananasharesTokenAddr,
        uint256 _protocolDeploymentDate
    ) {
        bananasharesTokenAddr = _bananasharesTokenAddr;
        protocolDeploymentBlockNr = _protocolDeploymentDate;
    }

    // -----------------
    //   Modifiers
    // -----------------

    /// @notice Restricts function calls to `AssetInstanceProxy` only.
    modifier onlyAssetInstance() {
        if (AssetInstancesHashes[msg.sender] == 0) {
            revert UnauthorizedFunctionCall(msg.sender);
        }
        _;
    }

    // -----------------
    //   Write Functions
    // -----------------

    /// @notice Sends the token minting order to the BananasharesToken contract.
    /// @param _tokenReceiver_1 The address of the token receiver (regular)
    /// @param _tokenReceiver_2 The address of the token receiver (privileged)
    /// @param _numberOfAssetShares The number of shares in an `AssetFactoryProxy` sold by a privileged shareholder.
    /// @param _alreadyMinted The number of Bananashares Tokens that an `AssetFactoryProxy` has already requested to mint for its users.
    function sendTokenMintingOrder(
        address _tokenReceiver_1,
        address _tokenReceiver_2,
        uint256 _numberOfAssetShares,
        uint256 _alreadyMinted
    ) external onlyAssetInstance returns (uint256, uint256) {
        uint256 _totalValueToMint;
        uint256 _valueToMint_1;
        uint256 _valueToMint_2;
        uint256 _divisor;
        uint256 _availableToMint = IBananasharesToken(bananasharesTokenAddr)
            .getAvailableToMint() / GOV_TOKEN_DECIMALS;
        if (_availableToMint == 0) {
            return (0, 0);
        }
        if (block.number > protocolDeploymentBlockNr + EARLY_PERIOD) {
            _divisor = SECOND_DIVISOR;
        } else {
            _divisor = FIRST_DIVISOR;
        }
        if (_alreadyMinted >= TOTAL_SUPPLY / _divisor) {
            return (0, 0);
        }

        _totalValueToMint = _numberOfAssetShares / _divisor;

        if (_totalValueToMint > ((TOTAL_SUPPLY / _divisor) - _alreadyMinted)) {
            _totalValueToMint = (TOTAL_SUPPLY / _divisor) - _alreadyMinted;
        }

        if (_totalValueToMint == 0) {
            return (0, 0);
        }

        if (_availableToMint == 1) {
            IBananasharesToken(bananasharesTokenAddr).mint(_tokenReceiver_1, 1);
            return (1, 0);
        }

        if (_totalValueToMint < 2) {
            return (0, 0);
        }

        if (_totalValueToMint <= _availableToMint) {
            _valueToMint_1 = _totalValueToMint / 2;
            _valueToMint_2 = _totalValueToMint - _valueToMint_1;
            IBananasharesToken(bananasharesTokenAddr).mint(
                _tokenReceiver_1,
                _valueToMint_1
            );
            IBananasharesToken(bananasharesTokenAddr).mint(
                _tokenReceiver_2,
                _valueToMint_2
            );
            return (_valueToMint_1, _valueToMint_2);
        }
        _valueToMint_1 = _availableToMint / 2;
        _valueToMint_2 = _availableToMint - _valueToMint_1;
        IBananasharesToken(bananasharesTokenAddr).mint(
            _tokenReceiver_1,
            _valueToMint_1
        );
        IBananasharesToken(bananasharesTokenAddr).mint(
            _tokenReceiver_2,
            _valueToMint_2
        );
        return (_valueToMint_1, _valueToMint_2);
    }

    /// @notice Withdraws Ether collectd by the protocol.
    function withdraw() external onlyOwner {
        bool _result;
        (_result, ) = owner().call{value: address(this).balance}("");
        require(_result);
    }

    /**
     * @notice Sends a specific amount of Ether from the protocol's balance to a defined address.
     * @param _addr The address to send the Ether.
     * @param _amount The amount of the Ether.
     */
    function withdrawTo(
        address payable _addr,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        uint256 _fromBalance;
        bool _result;
        if (_addr == address(0)) {
            revert ZeroAddress();
        }
        _fromBalance = address(this).balance;
        if (_fromBalance < _amount) {
            revert InsufficientBalance();
        }
        (_result, ) = _addr.call{value: _amount}("");
        require(_result);
    }

    /**
     * @notice Sets a new implementation for `AssetInstanceProxy`.
     * @param _implementation The address of the implementation.
     */
    function setAssetInstanceImplementation(
        address _implementation
    ) external onlyOwner {
        if (_implementation.code.length == 0) {
            revert InvalidImplementation(_implementation);
        }
        AssetInstanceImplementation = _implementation;
    }

    /**
     * @notice Sets a new `Asset_Structs.GlobalSettings` value for `globalSettings`.
     * @param _commission_for_privileged The commission for the privileged shareholders.
     * @param _commission_for_protocol The commission for the protocol.
     * @param _min_sell_offer The minimal price per share in a new offer.
     */
    function setGlobalSettings(
        uint24 _commission_for_privileged,
        uint24 _commission_for_protocol,
        uint96 _min_sell_offer
    ) external onlyOwner {
        globalSettings = Asset_Structs.GlobalSettings({
            commission_for_privileged: _commission_for_privileged,
            commission_for_protocol: _commission_for_protocol,
            min_sell_offer: _min_sell_offer
        });
    }

    // @TODO change contract to emit name of new asset
    /**
     *  @notice Creates the new `AssetInstanceProxy` contract.
     *  @param _nameOfAsset The title of the asset.
     *  @param _initialOwners The list of privileged shareholder's names
     *  @param _shareholderAddress The list of privileged shareholder's addresses.
     *  @param _shares The list of shares assigned to each privileged shareholder.
     *  @param _assetHash The hash of the asset.
     */
    function createAssetInstance(
        string calldata _nameOfAsset,
        string[] calldata _initialOwners,
        address[] calldata _shareholderAddress,
        uint24[] calldata _shares,
        bytes32 _assetHash
    ) external {
        AssetInstanceProxy _newAssetInstance;

        if (AssetInstancesByHash[_assetHash] != address(0)) {
            revert AssetInstanceAlreadyExists(_assetHash);
        }

        try
            new AssetInstanceProxy(
                _nameOfAsset,
                _initialOwners,
                _shareholderAddress,
                _shares,
                _assetHash
            )
        returns (AssetInstanceProxy _AssetInstance) {
            _newAssetInstance = _AssetInstance;
            AssetInstancesHashes[address(_newAssetInstance)] = _assetHash;
            AssetInstancesByHash[_assetHash] = address(_newAssetInstance);
            emit AssetInstanceCreated(
                address(msg.sender),
                address(_newAssetInstance),
                _nameOfAsset
            );
        } catch Error(string memory _failReason) {
            emit AssetInstanceCreationFailure(address(msg.sender), _failReason);
        } catch (bytes memory) {
            emit AssetInstanceCreationFailure(
                address(msg.sender),
                "Low-level error occurred"
            );
        }
    }
}
