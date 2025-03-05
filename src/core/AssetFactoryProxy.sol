// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AssetFactoryStorage} from "./util/AssetFactoryStorage.sol";
import {Asset_Structs} from "./util/AssetInstanceStructs.sol";

/**
 *  @title The main contract of the Bananashares protocol.
 *
 *  `AssetFactoryProxy` is responsible for:
 *  - Creating new `AssetInstanceProxy` contracts.
 *  - Collecting protocol fees.
 *  - Storing the implementation for `AssetInstanceProxy`.
 *  - Redirecting Bananashares token minting orders to the `BananasharesToken` contract.
 *  - Defining `GlobalSettings`.
 *
 *
 *  _commission_for_privileged = COMMITSION_FOR_PRIVILEGED = 200
 *      _commission_for_privileged/BIPS = 2%
 *
 *  _commission_for_protocol = COMMITSION_FOR_OWNER = 0
 *      _commission_for_protocol/BIPS = 0%
 *
 *  _min_sell_offer = MIN_SELL_OFFER = 1e12
 *      $3000 for a full asset
 *      adopted exchange rate: $3000/ETH
 *      1 ETH for a full asset
 *      _min_sell_offer = 1 ETH / TOTAL_SUPPLY = 1_000_000_000_000 [WEI per share]
 *
 *  COMMITSION_FOR_PRIVILEGED, COMMITSION_FOR_OWNER, MIN_SELL_OFFER are constants specified
 *  in the `BananasharesDeploySettings.sol` file and used in the deployment script.
 *
 */

contract AssetFactoryProxy is ERC1967Proxy, AssetFactoryStorage {
    constructor(
        address _implementation,
        bytes memory _data,
        uint24 _commission_for_privileged,
        uint24 _commission_for_protocol,
        uint96 _min_sell_offer
    ) ERC1967Proxy(_implementation, _data) {
        // `bananasharesTokenAddr` must be specified in the implementation
        // bananasharesTokenAddr = _bananasharesTokenAddr;
        protocolDeploymentBlockNr = block.number;
        globalSettings = Asset_Structs.GlobalSettings({
            commission_for_privileged: _commission_for_privileged,
            commission_for_protocol: _commission_for_protocol,
            min_sell_offer: _min_sell_offer
        });
    }
    receive() external payable {}
}
