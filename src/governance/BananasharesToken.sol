// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import {IBananasharesToken} from "./IBananasharesToken.sol";

/**
 *  @title The main contract for the governance voting token.
 *
 *  ## Distribution plan:
 *  1. Official Deployment of Bananashares Token on Mainnet.
 *      |
 *      -- Minting of 300_000_000 for the protocol founder that is 30% of `MAX_SUPPLY`.
 *
 *  2. Gathering funds for smart contracts audits and further development.
 *      |
 *      -- Minting of 100_000_000 for external investors that is 10% of `MAX_SUPPLY`.
 *
 *  3. Official Deployment of the protocol contracts on Mainnet.
 *      |
 *      -- Minting of 600_000_000 for initial users that is 60% of `MAX_SUPPLY`.
 *
 *
 *  ## Minting mechanism for initial users:
 *
 *  A PRIVILEGED ----- Creates ------> `AssetInstanceProxy`
 *  SHAREHOLDER      a sell offer.
 *
 *
 *  A REGULAR ------ Buys X shares --> `AssetInstanceProxy`--> `AssetFactoryProxy` -----||
 *  SHAREHOLDER        from the
 *  WANNABE      privileged shareholder.
 *
 *          ||--| 1st Year:                    |-----||
 *              | Mints Y = X/`FIRST_DIVISOR`  |
 *              | after 1st Year:              |
 *              | Mints Y = X/`SECOND_DIVISOR` |
 *              --------------------------------
 *
 *          ||--------| Mints Y/2 Bananashares tokens   |-----|
 *                |   | for the privileged shareholder. |     |
 *                |   -----------------------------------     |
 *                |                                           |--->`BananasharesToken`
 *                |                                           |
 *                |                                           |
 *                ----| Mints Y/2 Bananashares tokens   |-----|
 *                    | for the regular shareholder     |
 *                    -----------------------------------
 *
 *  `FIRST_DIVISOR` and `SECOND_DIVISOR` are specified in `AssetFactoryConst`.
 *
 *  Each `AssetInstanceProxy` has a limit on the number of tokens available to mint.
 *  the limit:  `TOTAL_SUPPLY`/ `FIRST_DIVISOR`( or `SECOND_DIVISOR`)
 *  `TOTAL_SUPPLY` is taken from `AssetConst`
 *
 *  ## AccessControl politics
 *  1. Official Deployment of Bananashares Token on Mainnet.
 *      |
 *      -- The `ADMIN_ROLE` is granted to the protocol founder.
 *      -- The protocol founder grants the `MINT_ROLE` to the AssetFactoryProxy.
 *
 *  2. Official Deployment of Protocol Contracts on Mainnet.
 *      |
 *      -- Start of the minting process.
 *
 *  3. Bananashares Token hits `MAX_SUPPLY`
 *      |
 *      -- The protocol founder will have their ADMIN_ROLE revoked.
 *      -- The AssetFactoryProxy will have its MINT_ROLE revoked.
 *
 */

contract BananasharesToken is
    ERC20,
    ERC20Permit,
    ERC20Votes,
    AccessControl,
    IBananasharesToken
{
    uint256 constant GOV_TOKEN_DECIMALS = 10 ** 18;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * GOV_TOKEN_DECIMALS;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    constructor(
        uint256 _tokenForFounder
    ) ERC20("Bananashares", "BSS") ERC20Permit("Bananashares") {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MINT_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
        _update(address(0), msg.sender, _tokenForFounder);
        _delegate(msg.sender, msg.sender);
        /// @todo Should I override `transfer` to automatically call `delegate`?
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    )
        public
        view
        override(IERC20Permit, ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }

    function mint(
        address beneficiary,
        uint256 value
    ) external onlyRole(MINT_ROLE) {
        uint256 _availableValue = _availableToMint();
        if (_availableValue == 0) {
            revert ProtocolReachedMaxSupply();
        }
        uint256 _valueToMint = value * GOV_TOKEN_DECIMALS;
        if (value >= _availableValue) {
            _valueToMint = _availableValue;
        }
        _update(address(0), beneficiary, _valueToMint);
        _delegate(beneficiary, beneficiary);
    }

    function _availableToMint() internal view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    // function getMaxSupply() external pure returns (uint256) {
    //     return MAX_SUPPLY;
    // }

    function getAvailableToMint() external view returns (uint256) {
        return _availableToMint();
    }
}
