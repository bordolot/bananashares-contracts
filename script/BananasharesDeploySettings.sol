// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.23;

contract BananasharesDeploySettings {
    /// Stored in AssetFactory, applied to all AssetInstances.
    uint24 constant COMMITSION_FOR_PRIVILEGED = 500; // 5%
    uint24 constant COMMITSION_FOR_OWNER = 200; // 2%
    uint96 constant MIN_SELL_OFFER = 1e12; // in WEI

    // Governance
    uint48 constant VOTING_DELAY = 43200; // 1 day
    uint256 constant PROPOSAL_THRESHOLD = 50_000_000 * 10 ** 18; // 5% of MAX_SUPPLY
    uint32 constant VOTIG_PERIOD = 302400; // 1 week
    uint256 constant QUORUM_FRACTION = 51; // 51%

    // Timelock
    // One day in seconds is the difference between block.timestamp (Ready to execute) and block.timestamp (Queued).
    uint256 constant TIMELOCK_MIN_DELAY = 86400; // 1 day in seconds

    // Bananashares Taken
    uint256 constant TOKENS_FOR_FOUNDER = 300_000_000 * 10 ** 18; // 30% of MAX_SUPPLY
}
