// SPDX-License-Identifier: BULS-1.1

pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {Actors} from "./Utils/Actors.sol";
import {CreateAssetInstance} from "../core/Utils/CreateAssetInstance.sol";

import {BananasharesToken} from "../../src/governance/BananasharesToken.sol";
import {IBananasharesToken} from "../../src/governance/IBananasharesToken.sol";
import {BananasharesGov} from "../../src/governance/BananasharesGov.sol";
import {BananasharesGovTimelock} from "../../src/governance/BananasharesGovTimelock.sol";

import {AssetInstanceProxy} from "../../src/core/AssetInstanceProxy.sol";
import {AssetInstance} from "../../src/core/AssetInstance.sol";
import {AssetFactoryProxy} from "../../src/core/AssetFactoryProxy.sol";
import {AssetFactory} from "../../src/core/AssetFactory.sol";
import {IAssetFactory} from "../../src/core/util/IAssetFactory.sol";
import {IAssetInstance} from "../../src/core/util/IAssetInstance.sol";
import {Asset_Structs} from "../../src/core/util/AssetInstanceStructs.sol";

//BananasharesToken
// {
//   "CLOCK_MODE()": "4bf5d7e9",
//   "DOMAIN_SEPARATOR()": "3644e515",
//   "allowance(address,address)": "dd62ed3e",
//   "approve(address,uint256)": "095ea7b3",
//   "balanceOf(address)": "70a08231",
//   "checkpoints(address,uint32)": "f1127ed8",
//   "clock()": "91ddadf4",
//   "decimals()": "313ce567",
//   "delegate(address)": "5c19a95c",
//   "delegateBySig(address,uint256,uint256,uint8,bytes32,bytes32)": "c3cda520",
//   "delegates(address)": "587cde1e",
//   "eip712Domain()": "84b0196e",
//   "getPastTotalSupply(uint256)": "8e539e8c",
//   "getPastVotes(address,uint256)": "3a46b1a8",
//   "getVotes(address)": "9ab24eb0",
//   "mint(address,uint256)": "40c10f19",
//   "name()": "06fdde03",
//   "nonces(address)": "7ecebe00",
//   "numCheckpoints(address)": "6fcfff45",
//   "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)": "d505accf",
//   "symbol()": "95d89b41",
//   "totalSupply()": "18160ddd",
//   "transfer(address,uint256)": "a9059cbb",
//   "transferFrom(address,address,uint256)": "23b872dd"
// }

interface IOwnableUpgradeable {
    function transferOwnership(address newOwner) external;
    function owner() external view returns (address);
}

contract Test_Unit_Gov is Test, Actors, CreateAssetInstance {
    BananasharesToken bananasharesToken;
    BananasharesGovTimelock bananasharesGovTimelock;
    BananasharesGov bananasharesGov;

    AssetFactory factoryImplementation;
    AssetInstance assetImplementation;
    AssetFactoryProxy assetFactory;
    // AssetInstanceProxy assetInstance;

    uint256 minDelay;
    address[] proposers;
    address[] executors;

    /// Variables used to create a local AssetInstance.
    string[] localAuthors;
    address[] localAddresses;
    uint24[] localShares;

    uint256 seed;

    enum VoteType {
        Against,
        For,
        Abstain
    }

    modifier clearLocalVars() {
        _;
        _clearLocalVariables(localAuthors.length);
    }

    function setUp() public {
        _dealEtherToActors();
        _deployProtocol();
        /// consider using `seed = _generateSeed();`
        seed = 1234;
        // _showCodeSizes();
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   helpFunctions                            //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function _deployProtocol() internal {
        vm.startPrank(addrFounder);

        // the governance part
        bananasharesToken = new BananasharesToken(TOKENS_FOR_FOUNDER);

        minDelay = TIMELOCK_MIN_DELAY;
        bananasharesGovTimelock = new BananasharesGovTimelock(
            minDelay,
            proposers,
            executors,
            addrFounder
        );

        bananasharesGov = new BananasharesGov(
            bananasharesToken,
            bananasharesGovTimelock,
            VOTING_DELAY,
            PROPOSAL_THRESHOLD,
            VOTIG_PERIOD,
            QUORUM_FRACTION
        );

        bananasharesGovTimelock.grantRole(
            bananasharesGovTimelock.EXECUTOR_ROLE(),
            address(bananasharesGov)
        );
        bananasharesGovTimelock.grantRole(
            bananasharesGovTimelock.PROPOSER_ROLE(),
            address(bananasharesGov)
        );
        bananasharesGovTimelock.grantRole(
            bananasharesGovTimelock.CANCELLER_ROLE(),
            address(bananasharesGov)
        );
        bananasharesGovTimelock.revokeRole(
            bananasharesGovTimelock.DEFAULT_ADMIN_ROLE(),
            addrFounder
        );

        // the core part

        factoryImplementation = new AssetFactory(
            address(bananasharesToken),
            block.number
        );

        bytes memory _calldata = abi.encodeWithSelector(
            AssetFactory.initialize.selector,
            addrFounder
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

        assetImplementation = new AssetInstance(address(assetFactory));

        IAssetFactory(address(assetFactory)).setAssetInstanceImplementation(
            address(assetImplementation)
        );

        IOwnableUpgradeable(address(assetFactory)).transferOwnership(
            address(bananasharesGovTimelock)
        );

        vm.stopPrank();

        // vm.startPrank(address(bananasharesGovTimelock));
        // assetImplementation = new AssetInstance(address(assetFactory));
        // IAssetFactory(address(assetFactory)).setAssetInstanceImplementation(
        //     address(assetImplementation)
        // );
        // vm.stopPrank();
    }

    function _showCodeSizes() internal {
        uint256 _size;
        address _contractAddress;
        address _localAsset;

        _contractAddress = address(bananasharesGov);
        assembly {
            _size := extcodesize(_contractAddress)
        }
        console.log("BananasharesGov length:", _size);
        _contractAddress = address(factoryImplementation);
        assembly {
            _size := extcodesize(_contractAddress)
        }
        console.log("AssetFactory length:", _size);
        _contractAddress = address(assetFactory);
        assembly {
            _size := extcodesize(_contractAddress)
        }
        console.log("AssetFactoryProxy length:", _size);
        _contractAddress = address(assetImplementation);
        assembly {
            _size := extcodesize(_contractAddress)
        }
        console.log("AssetInstance length:", _size);

        localAuthors.push("_showCodeSizes_1");
        localAddresses.push(makeAddr("_showCodeSizes"));
        localShares.push(TOTAL_SUPPLY);
        _localAsset = _createSpecificAssetLocally(
            address(assetFactory),
            "_showCodeSizes",
            localAuthors,
            localAddresses,
            localShares,
            bytes32(keccak256("_showCodeSizes"))
        );
        assembly {
            _size := extcodesize(_localAsset)
        }
        console.log("AssetInstanceProxy length:", _size);
    }

    function _mintBananasharesTokensByBuyoutOfAssetShares(
        address _regularUser,
        address _assetAddr
    ) internal returns (uint256) {
        uint256 _govTokensBefore;
        uint256 _govTokensMinted;
        _govTokensBefore = IERC20(address(bananasharesToken)).balanceOf(
            _regularUser
        );

        _putAllSharesInOffers(_assetAddr, MIN_SELL_OFFER);
        _buyOutAllSharesInOffersByOneUser(
            _assetAddr,
            _regularUser,
            MIN_SELL_OFFER
        );
        _govTokensMinted =
            IERC20(address(bananasharesToken)).balanceOf(_regularUser) -
            _govTokensBefore;

        return _govTokensMinted;
    }

    function testCheckRolesInBananasharesGovTimelock() public view {
        bool result_1;
        result_1 = IAccessControl(address(bananasharesGovTimelock)).hasRole(
            0x00,
            addrFounder
        );
        vm.assertEq(result_1, false);
        result_1 = IAccessControl(address(bananasharesGovTimelock)).hasRole(
            0x00,
            address(bananasharesGovTimelock)
        );
        vm.assertEq(result_1, true);
        result_1 = IAccessControl(address(bananasharesGovTimelock)).hasRole(
            keccak256("PROPOSER_ROLE"),
            address(bananasharesGov)
        );
        vm.assertEq(result_1, true);
        result_1 = IAccessControl(address(bananasharesGovTimelock)).hasRole(
            keccak256("EXECUTOR_ROLE"),
            address(bananasharesGov)
        );
        vm.assertEq(result_1, true);
    }

    function _clearLocalVariables(uint256 _howMany) internal {
        for (uint i = 0; i < _howMany; i++) {
            localAuthors.pop();
            localAddresses.pop();
            localShares.pop();
        }
    }

    function _createProposal(
        address _target,
        uint256 _proposeValue
    ) internal pure returns (Proposal memory, uint256) {
        bytes memory _functionToCall;
        address[] memory _targets;
        uint256[] memory _values;
        bytes[] memory _calldatas;
        string memory _description;
        uint256 _proposalId;
        Proposal memory _newProposal;

        _targets = new address[](1);
        _targets[0] = _target;

        _values = new uint256[](1);
        _values[0] = 0;

        _functionToCall = abi.encodeWithSignature(
            "setGlobalSettings(uint24,uint24,uint96)",
            uint24(COMMITSION_FOR_PRIVILEGED * _proposeValue),
            uint24(COMMITSION_FOR_OWNER * _proposeValue),
            uint96(MIN_SELL_OFFER * _proposeValue)
        );
        _calldatas = new bytes[](1);
        _calldatas[0] = _functionToCall;

        _description = "testProposal";

        _proposalId = _hashProposal(
            _targets,
            _values,
            _calldatas,
            keccak256(bytes(_description))
        );

        _newProposal = Proposal({
            _targets: _targets,
            _values: _values,
            _calldatas: _calldatas,
            _description: _description
        });
        return (_newProposal, _proposalId);
    }

    function _hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(targets, values, calldatas, descriptionHash)
                )
            );
    }

    function _transferAndDelegate(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        vm.startPrank(_from);
        IERC20(bananasharesToken).transfer(_to, _amount);
        vm.stopPrank();
        vm.startPrank(_to);
        IVotes(bananasharesToken).delegate(_to);
        vm.stopPrank();
        vm.resetGasMetering();
        return _amount;
    }

    //////////////////////////////////////////////////////////////////////////
    /////////                                                            /////
    ////////                   tests                                    //////
    ///////                                                            ///////
    //////////////////////////////////////////////////////////////////////////

    function testCheckRolesInBananasharesToken() public view {
        bool result_1;
        result_1 = IAccessControl(address(bananasharesToken)).hasRole(
            keccak256("MINT_ROLE"),
            addrFounder
        );
        vm.assertEq(result_1, false);
        result_1 = IAccessControl(address(bananasharesToken)).hasRole(
            keccak256("MINT_ROLE"),
            address(assetFactory)
        );
        vm.assertEq(result_1, true);
    }

    /// Creates sell offers where the total amount of shares to be sold equals `TOTAL_SUPPLY`.
    /// Executes a buyout of all these shares by the user `addrUser_1`.
    function testMintBananashareTokensForInitialUser() public {
        uint256 _bananasharesTokensAvailableToMint;
        uint256 _numberOfTokens;
        uint256 _numberOfVotes;
        uint256[] memory _sharesEachPrivilegedOriginallyOwned;
        address[] memory _privileged;
        uint _i;

        _createTestAssets(address(assetFactory), seed, 1);

        _bananasharesTokensAvailableToMint = IBananasharesToken(
            address(bananasharesToken)
        ).getAvailableToMint();
        /// At the start the number of minted Bananashares Tokens must equal TOKENS_FOR_FOUNDER;
        vm.assertEq(
            TOKENS_FOR_FOUNDER,
            IERC20(address(bananasharesToken)).balanceOf(addrFounder)
        );
        vm.assertEq(
            TOKENS_FOR_FOUNDER,
            IERC20(address(bananasharesToken)).totalSupply()
        );
        vm.assertEq(
            _bananasharesTokensAvailableToMint,
            (IBananasharesToken(address(bananasharesToken)).MAX_SUPPLY() -
                TOKENS_FOR_FOUNDER)
        );

        /// Perform pruchace of all shares in an AssetInstance by `addrUser_1`.
        _putAllSharesInOffers(assetsAddresses[0], MIN_SELL_OFFER);
        _privileged = IAssetInstance(address(assetsAddresses[0]))
            .getAllPrivShareholders();
        _sharesEachPrivilegedOriginallyOwned = new uint256[](
            _privileged.length
        );
        for (_i = 0; _i < _privileged.length; _i++) {
            _sharesEachPrivilegedOriginallyOwned[_i] = (
                IAssetInstance(address(assetsAddresses[0])).getShares(
                    _privileged[_i]
                )
            );
        }
        _buyOutAllSharesInOffersByOneUser(
            assetsAddresses[0],
            addrUser_1,
            MIN_SELL_OFFER
        );

        /// `_bananasharesTokensAvailableToMint` should decrease by exactly the AssetInstance's `govTokensMinted`.
        _bananasharesTokensAvailableToMint = IBananasharesToken(
            address(bananasharesToken)
        ).getAvailableToMint();
        vm.assertEq(
            _bananasharesTokensAvailableToMint,
            (IBananasharesToken(address(bananasharesToken)).MAX_SUPPLY() -
                TOKENS_FOR_FOUNDER -
                IAssetInstance(address(assetsAddresses[0]))
                    .getGovTokensMinted())
        );

        /// `addrUser_1` should hold exactly the AssetInstance's `TOTAL_SUPPLY` amount of Bananashares Tokens.
        _numberOfTokens =
            IERC20(address(bananasharesToken)).balanceOf(addrUser_1) /
            GOV_TOKEN_DECIMALS;
        _numberOfVotes =
            IVotes(address(bananasharesToken)).getVotes(addrUser_1) /
            GOV_TOKEN_DECIMALS;
        vm.assertEq(_numberOfTokens, _numberOfVotes);
        assertGe(
            _numberOfTokens,
            TOTAL_SUPPLY / FIRST_DIVISOR / 2 - _privileged.length
        );
        assertLe(
            _numberOfTokens,
            TOTAL_SUPPLY / FIRST_DIVISOR / 2 + _privileged.length
        );

        // vm.assertEq(_numberOfTokens, TOTAL_SUPPLY);
        // vm.assertEq(_numberOfVotes, TOTAL_SUPPLY);

        /// Each privileged shareholder must also receive Bananashares Tokens, the amount of which must correspond to the number of shares they originally owned.
        uint sum = _numberOfTokens;

        for (_i = 1; _i < _privileged.length; _i++) {
            _numberOfTokens =
                IERC20(address(bananasharesToken)).balanceOf(_privileged[_i]) /
                GOV_TOKEN_DECIMALS;
            _numberOfVotes =
                IVotes(address(bananasharesToken)).getVotes(_privileged[_i]) /
                GOV_TOKEN_DECIMALS;
            vm.assertEq(_numberOfTokens, _numberOfVotes);

            assertGe(
                _numberOfTokens,
                _sharesEachPrivilegedOriginallyOwned[_i] /
                    FIRST_DIVISOR /
                    2 -
                    _privileged.length
            );
            assertLe(
                _numberOfTokens,
                _sharesEachPrivilegedOriginallyOwned[_i] /
                    FIRST_DIVISOR /
                    2 +
                    _privileged.length
            );
            sum += _numberOfTokens;
        }

        uint256 _govTokensMintedInAsset = IAssetInstance(
            address(assetsAddresses[0])
        ).getGovTokensMinted();
        assertEq(_govTokensMintedInAsset, sum * GOV_TOKEN_DECIMALS);
    }

    /// Attempts to mint exact number of the Bananashares Tokens during the buyout by a regular user.
    /// takes _localAsset
    function testTryMintExactNumberOfGovTokensFirstYear()
        public
        clearLocalVars
    {
        uint256 _mintedTokensForUser;
        uint256 _mintedTokensInAsset;
        address _localAsset;

        localAuthors.push("TryMintExactNumberOfGovTokens_1");
        localAddresses.push(makeAddr("testTryMintExactNumberOfGovTokens_1"));
        localShares.push(TOTAL_SUPPLY);
        _localAsset = _createSpecificAssetLocally(
            address(assetFactory),
            "testTryMintExactNumberOfGovTokens",
            localAuthors,
            localAddresses,
            localShares,
            bytes32(keccak256("testTryMintExactNumberOfGovTokens"))
        );

        _mintedTokensForUser = _mintBananasharesTokensByBuyoutOfAssetShares(
            addrUser_1,
            _localAsset
        );
        _mintedTokensInAsset = IAssetInstance(_localAsset).getGovTokensMinted();
        assertEq(
            IERC20(address(bananasharesToken)).balanceOf(localAddresses[0]),
            _mintedTokensForUser
        );
        /// check for `FIRST_DIVISOR`
        /// In `TOTAL_SUPPLY / FIRST_DIVISOR / 2`, the `/2` is included because the second half remains with the privileged shareholder.
        assertEq(
            IERC20(address(bananasharesToken)).balanceOf(localAddresses[0]),
            ((TOTAL_SUPPLY / FIRST_DIVISOR / 2) * GOV_TOKEN_DECIMALS)
        );

        assertEq(_mintedTokensInAsset, 2 * _mintedTokensForUser);
    }

    function testTryMintExactNumberOfGovTokens_After_FirstYear()
        public
        clearLocalVars
    {
        uint256 _mintedTokensForUser;
        uint256 _mintedTokensInAsset;
        address _localAsset;

        vm.roll(block.number + EARLY_PERIOD + 1);

        localAuthors.push("TryMintExactNumberOfGovTokens_1");
        localAddresses.push(makeAddr("testTryMintExactNumberOfGovTokens_1"));
        localShares.push(TOTAL_SUPPLY);
        _localAsset = _createSpecificAssetLocally(
            address(assetFactory),
            "testTryMintExactNumberOfGovTokens",
            localAuthors,
            localAddresses,
            localShares,
            bytes32(keccak256("testTryMintExactNumberOfGovTokens"))
        );

        _mintedTokensForUser = _mintBananasharesTokensByBuyoutOfAssetShares(
            addrUser_1,
            _localAsset
        );
        _mintedTokensInAsset = IAssetInstance(_localAsset).getGovTokensMinted();
        assertEq(
            IERC20(address(bananasharesToken)).balanceOf(addrUser_1),
            _mintedTokensForUser
        );

        /// check for `SECOND_DIVISOR`
        /// In `TOTAL_SUPPLY / SECOND_DIVISOR / 2`, the `/2` is included because the second half remains with the privileged shareholder.
        assertEq(
            IERC20(address(bananasharesToken)).balanceOf(addrUser_1),
            ((TOTAL_SUPPLY / SECOND_DIVISOR / 2) * GOV_TOKEN_DECIMALS)
        );

        assertEq(_mintedTokensInAsset, 2 * _mintedTokensForUser);
    }

    /// Buy a number of shares that could lead to minting only one governance token for the buyer or the seller, although minting will not be possible.
    function testTryToMintOnlyOneGovTokenAndFail() public clearLocalVars {
        uint256 _divisor;
        uint256 _mintedTokensForUser;
        uint256 _mintedTokensInAsset;
        address _localAsset;

        _divisor = FIRST_DIVISOR;

        localAuthors.push("TryToMintOnlyOneGovTokenAndFail");
        localAddresses.push(makeAddr("testTryToMintOnlyOneGovTokenAndFail"));
        localShares.push(TOTAL_SUPPLY);
        _localAsset = _createSpecificAssetLocally(
            address(assetFactory),
            "testTryToMintOnlyOneGovTokenAndFail",
            localAuthors,
            localAddresses,
            localShares,
            bytes32(keccak256("testTryToMintOnlyOneGovTokenAndFail"))
        );

        _putAllSharesInOffers(_localAsset, MIN_SELL_OFFER);
        _buyShares(
            addrUser_1,
            _localAsset,
            localAddresses[0],
            uint24(2 * _divisor - 1),
            MIN_SELL_OFFER
        );
        /// buy transaction was successful
        assertEq(
            IAssetInstance(_localAsset).getShares(addrUser_1),
            2 * _divisor - 1
        );
        /// but minting was not
        _mintedTokensInAsset = IAssetInstance(_localAsset).getGovTokensMinted();
        assertEq(_mintedTokensInAsset, 0);
        _mintedTokensForUser = IERC20(address(bananasharesToken)).balanceOf(
            addrUser_1
        );
        assertEq(_mintedTokensForUser, 0);
        _mintedTokensForUser = IERC20(address(bananasharesToken)).balanceOf(
            localAddresses[0]
        );
        assertEq(_mintedTokensForUser, 0);

        /// Now successfully mint 1 governance token for both the buyer and the seller.
        _buyShares(
            addrUser_1,
            _localAsset,
            localAddresses[0],
            uint24(2 * _divisor),
            MIN_SELL_OFFER
        );
        _mintedTokensInAsset = IAssetInstance(_localAsset).getGovTokensMinted();
        assertEq(_mintedTokensInAsset, 2 * GOV_TOKEN_DECIMALS);
        _mintedTokensForUser = IERC20(address(bananasharesToken)).balanceOf(
            addrUser_1
        );
        assertEq(_mintedTokensForUser, 1 * GOV_TOKEN_DECIMALS);
        _mintedTokensForUser = IERC20(address(bananasharesToken)).balanceOf(
            localAddresses[0]
        );
        assertEq(_mintedTokensForUser, 1 * GOV_TOKEN_DECIMALS);
    }

    /// Tries (as addrUser_1) to create a gov proposal that changes `globalSettings` in `AssetFactoryStorage`.
    /// At first, mints enough gov tokens to create such a proposal.
    /// Then, mints enough gov tokens to win voting.
    /// For 1st year with `FIRST_DIVISOR`.
    function testTryToGetProposalPower() public {
        uint256 _proposalId;
        Proposal memory _newProposal;
        uint256 _proposeValue;
        uint256 _numberOfAssetInstance_part1;
        uint256 _numberOfAssetInstance_part2;
        uint256 _mintedTokensForUser;
        uint256 _minted;
        uint256 _state;
        address _addr;
        Asset_Structs.GlobalSettings memory _settings;

        /// first part
        _numberOfAssetInstance_part1 = 5000;
        /// second part
        _numberOfAssetInstance_part2 = 30000;
        _createTestAssetsOnlyOneShareholder(
            address(assetFactory),
            1234,
            _numberOfAssetInstance_part1 + _numberOfAssetInstance_part2
        );

        /// create a proposal draft
        _proposeValue = 2;
        (_newProposal, _proposalId) = _createProposal(
            address(assetFactory),
            _proposeValue
        );

        /// fail to propose
        vm.startPrank(addrUser_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IGovernor.GovernorInsufficientProposerVotes.selector,
                addrUser_1,
                0,
                bananasharesGov.proposalThreshold()
            )
        );
        bananasharesGov.propose(
            _newProposal._targets,
            _newProposal._values,
            _newProposal._calldatas,
            _newProposal._description
        );
        vm.stopPrank();

        /// mint almost enought number of shares to propose
        for (uint i = 0; i < _numberOfAssetInstance_part1 - 1; i++) {
            vm.deal(addrUser_1, startWalletBalance);
            _minted = _mintBananasharesTokensByBuyoutOfAssetShares(
                addrUser_1,
                assetsAddresses[i]
            );
            _mintedTokensForUser += _minted;
            (_addr, ) = IAssetInstance(assetsAddresses[i])
                .getPrivilegedShareholder(1);
            /// Improve minting by sending gov tokens from each privileged shareholder to addrUser_1
            _mintedTokensForUser += _transferAndDelegate(
                _addr,
                addrUser_1,
                _minted
            );
            vm.resetGasMetering();
        }
        vm.roll(block.number + 1);

        /// again fail to propose - one loop missing
        vm.startPrank(addrUser_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IGovernor.GovernorInsufficientProposerVotes.selector,
                addrUser_1,
                _mintedTokensForUser,
                bananasharesGov.proposalThreshold()
            )
        );
        bananasharesGov.propose(
            _newProposal._targets,
            _newProposal._values,
            _newProposal._calldatas,
            _newProposal._description
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                IGovernor.GovernorNonexistentProposal.selector,
                _proposalId
            )
        );
        _state = uint256(bananasharesGov.state(_proposalId));
        vm.stopPrank();

        /// mint just enought number of shares to propose
        _minted = _mintBananasharesTokensByBuyoutOfAssetShares(
            addrUser_1,
            assetsAddresses[_numberOfAssetInstance_part1 - 1]
        );
        _mintedTokensForUser += _minted;
        (_addr, ) = IAssetInstance(
            assetsAddresses[_numberOfAssetInstance_part1 - 1]
        ).getPrivilegedShareholder(1);
        _mintedTokensForUser += _transferAndDelegate(
            _addr,
            addrUser_1,
            _minted
        );
        vm.roll(block.number + 1);

        /// finally succesfull proposal
        vm.startPrank(addrUser_1);
        bananasharesGov.propose(
            _newProposal._targets,
            _newProposal._values,
            _newProposal._calldatas,
            _newProposal._description
        );
        vm.stopPrank();

        _state = uint256(bananasharesGov.state(_proposalId));
        assertEq(_state, uint256(IGovernor.ProposalState.Pending));

        /// vote for as addrUser_1 but fail because of lack of quorum

        vm.roll(block.number + VOTING_DELAY + 1);
        vm.startPrank(addrUser_1);
        bananasharesGov.castVote(_proposalId, uint8(VoteType.For));
        vm.stopPrank();

        vm.roll(block.number + VOTIG_PERIOD);

        _state = uint256(bananasharesGov.state(_proposalId));
        assertEq(_state, uint256(IGovernor.ProposalState.Defeated));

        /// mint more tokens to get more that 50% of availabe tokens
        /// the rest still holds `addrFounder`

        for (
            uint i = _numberOfAssetInstance_part1;
            i < _numberOfAssetInstance_part1 + _numberOfAssetInstance_part2;
            i++
        ) {
            vm.deal(addrUser_1, startWalletBalance);
            _minted = _mintBananasharesTokensByBuyoutOfAssetShares(
                addrUser_1,
                assetsAddresses[i]
            );
            _mintedTokensForUser += _minted;
            (_addr, ) = IAssetInstance(assetsAddresses[i])
                .getPrivilegedShareholder(1);
            /// Improve minting by sending gov tokens from each privileged shareholder to addrUser_1
            _mintedTokensForUser += _transferAndDelegate(
                _addr,
                addrUser_1,
                _minted
            );
            vm.resetGasMetering();
        }
        vm.roll(block.number + 1);

        seed = _generateSeed();

        assertEq(
            IERC20(address(bananasharesToken)).balanceOf(addrUser_1),
            ((_numberOfAssetInstance_part1 + _numberOfAssetInstance_part2) *
                GOV_TOKEN_DECIMALS *
                TOTAL_SUPPLY) / FIRST_DIVISOR
        );

        /// create a new proposal
        _newProposal._description = "testProposal_2";
        _proposalId = _hashProposal(
            _newProposal._targets,
            _newProposal._values,
            _newProposal._calldatas,
            keccak256(bytes(_newProposal._description))
        );
        vm.startPrank(addrUser_1);
        bananasharesGov.propose(
            _newProposal._targets,
            _newProposal._values,
            _newProposal._calldatas,
            _newProposal._description
        );
        vm.stopPrank();

        /// vote for as addrUser_1 but fail because of lack of quorum

        vm.roll(block.number + VOTING_DELAY + 1);
        vm.startPrank(addrUser_1);
        bananasharesGov.castVote(_proposalId, uint8(VoteType.For));
        vm.stopPrank();

        vm.startPrank(addrFounder);
        bananasharesGov.castVote(_proposalId, uint8(VoteType.Against));
        vm.stopPrank();

        vm.roll(block.number + VOTIG_PERIOD);

        _state = uint256(bananasharesGov.state(_proposalId));
        assertEq(_state, uint256(IGovernor.ProposalState.Succeeded));

        /// At this moment, the settings still have their old values.
        _settings = IAssetFactory(address(assetFactory)).getGlobalSettings();
        assertEq(
            _settings.commission_for_privileged,
            COMMITSION_FOR_PRIVILEGED
        );

        bananasharesGov.queue(
            _newProposal._targets,
            _newProposal._values,
            _newProposal._calldatas,
            keccak256(bytes(_newProposal._description))
        );

        _state = uint256(bananasharesGov.state(_proposalId));
        assertEq(_state, uint256(IGovernor.ProposalState.Queued));

        vm.roll(block.number + TIMELOCK_MIN_DELAY);
        vm.warp(TIMELOCK_MIN_DELAY + 1);
        bananasharesGov.execute(
            _newProposal._targets,
            _newProposal._values,
            _newProposal._calldatas,
            keccak256(bytes(_newProposal._description))
        );

        /// From this moment on, the settings should be updated.
        _settings = IAssetFactory(address(assetFactory)).getGlobalSettings();
        assertEq(
            _settings.commission_for_privileged,
            COMMITSION_FOR_PRIVILEGED * _proposeValue
        );
    }
}
