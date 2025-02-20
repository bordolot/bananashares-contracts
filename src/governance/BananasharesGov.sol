// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;
import {console} from "../../lib/forge-std/src/Test.sol";
import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 *  @title The main contract responsible for handling protocol governance.
 *
 *  It uses `BananasharesGovTimelock` to handle the queuing and execution of winning proposals.
 *  It uses `BananasharesToken` to determine voting power.
 *
 *  `GovernorSettings` are specified during deployment. Their values are set to:
 *  _votigDelay = VOTING_DELAY = 43200; // 1 day
 *  _proposalThreshold = PROPOSAL_THRESHOLD = 50_000_000 * 10 ** 18; // 5% of MAX_SUPPLY
 *  _votingPeriod = VOTIG_PERIOD = 302400; // 1 week
 *
 *  `GovernorVotesQuorumFraction` are specified during deployment. Their values are set to:
 *  _quorumFraction = QUORUM_FRACTION = 51; // 51%
 *
 *  VOTING_DELAY, PROPOSAL_THRESHOLD, VOTIG_PERIOD, QUORUM_FRACTION are constants specified
 *  in the `BananasharesDeploySettings.sol` file and used in the deployment script.
 *
 */

contract BananasharesGov is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    struct ProposalInputData {
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        string description;
    }

    /// @dev Assigns the proposalId to an index.
    mapping(uint256 => uint256) public proposalIdIndex;
    /// @dev The list of proposalIds.
    uint256[] private proposalIds;
    /// @dev Assigns a ProposalInputData to the proposalId.
    mapping(uint256 => ProposalInputData) public proposalInputDatas;

    constructor(
        IVotes _token,
        TimelockController _timelock,
        uint48 _votigDelay,
        uint256 _proposalThreshold,
        uint32 _votingPeriod,
        uint256 _quorumFraction
    )
        Governor("BananasharesGovernor")
        //for the Ethereum 1 block is created in 12 s
        //for the Optimism 1 block is created in 2 s
        GovernorSettings(_votigDelay, _votingPeriod, _proposalThreshold)
        GovernorVotes(_token)
        //set quorum fraction
        GovernorVotesQuorumFraction(_quorumFraction)
        GovernorTimelockControl(_timelock)
    {}

    //////////////////////////////////////////////////////////////
    //
    // The following functions are overrides required by parent contracts.
    //
    function votingDelay()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(
        uint256 blockNumber
    )
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        // uint256 quorumNumber = super.quorum(blockNumber);
        // console.log("quorumNumber: ", quorumNumber);
        return super.quorum(blockNumber);
    }

    function state(
        uint256 proposalId
    )
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function proposalNeedsQueuing(
        uint256 proposalId
    ) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.proposalNeedsQueuing(proposalId);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return
            super._queueOperations(
                proposalId,
                targets,
                values,
                calldatas,
                descriptionHash
            );
    }

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(
            proposalId,
            targets,
            values,
            calldatas,
            descriptionHash
        );
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    //
    // END OF
    // "The following functions are overrides required by parent contracts."
    //
    /////////////////////////////////////////////////////////////////

    /// @notice Returns a specific proposalId.
    function getProposalId(
        uint256 _index
    ) public view returns (uint256 proposalId) {
        proposalId = proposalIds[_index];
    }

    /// @notice Returns a specific description.
    function getProposalTargets(
        uint256 _proposalId
    ) public view returns (address[] memory targets) {
        targets = proposalInputDatas[_proposalId].targets;
    }

    /// @notice Returns a specific description.
    function getProposalValues(
        uint256 _proposalId
    ) public view returns (uint256[] memory values) {
        values = proposalInputDatas[_proposalId].values;
    }

    /// @notice Returns a specific description.
    function getProposalCalldatas(
        uint256 _proposalId
    ) public view returns (bytes[] memory calldatas) {
        calldatas = proposalInputDatas[_proposalId].calldatas;
    }

    /// @notice Returns a specific description.
    function getProposalDescription(
        uint256 _proposalId
    ) public view returns (string memory description) {
        description = proposalInputDatas[_proposalId].description;
    }

    /// @notice Returns a specific description.
    function getNumberOfProposals() public view returns (uint256 number) {
        number = proposalIds.length;
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor) returns (uint256) {
        uint256 proposalId = super.propose(
            targets,
            values,
            calldatas,
            description
        );
        proposalIds.push(proposalId);
        ProposalInputData memory proposalInputData;
        proposalInputData.targets = targets;
        proposalInputData.values = values;
        proposalInputData.calldatas = calldatas;
        proposalInputData.description = description;
        proposalInputDatas[proposalId] = proposalInputData;
        return proposalId;
    }
}
