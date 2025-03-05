//SPDX-License-Identifier:BUSL-1.1

pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IBananasharesToken is IERC20, IERC20Permit, IVotes, IAccessControl {
    error ProtocolReachedMaxSupply();
    event TokenMinted(address beneficiary, uint256 amount);
    function MAX_SUPPLY() external view returns (uint256);
    function mint(address beneficiary, uint256 value) external;
    function getAvailableToMint() external view returns (uint256);
}
