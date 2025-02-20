// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 *  @title The contract responsible for queuing and executing winning proposals.
 *
 *  `BananasharesGov` has been given the roles: EXECUTOR_ROLE, PROPOSER_ROLE, CANCELLER_ROLE
 *
 *  minDelay = TIMELOCK_MIN_DELAY = 86400; // 1 day in seconds
 *  TIMELOCK_MIN_DELAY is a constant specified
 *  in the `BananasharesDeploySettings.sol` file and used in the deployment script.
 *
 */
contract BananasharesGovTimelock is TimelockController {
    // minDelay is how long you have to wait before executing
    // proposers is the list of addresses that can propose
    // executors is the list of addresses that can execute
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {}
}
