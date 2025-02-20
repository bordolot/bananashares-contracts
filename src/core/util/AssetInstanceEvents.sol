//SPDX-License-Identifier:BUSL-1.1

pragma solidity 0.8.23;

interface AssetInstanceEvents {
    // -----------------
    //    Events
    // -----------------

    /// @notice Emitted during buyShares().
    /// @param  from The address of the offer's owner.
    /// @param  value The price per share in the offer.
    /// @param  to The address of the user that bought the shares.
    /// @param  amount The number of shares bought in the transaction.
    event SharesBought(
        address indexed from,
        uint256 value,
        address indexed to,
        uint256 amount
    );

    /// @notice Emitted during makeSellOffer().
    /// @param  from The address of the Privileged Shareholder who created the Offer.
    /// @param  amount The amount of shares that are for sale.
    /// @param  value The price for each share in this Offer.
    event SellOfferPut(address indexed from, uint256 amount, uint256 value);

    /// @notice Emitted during cancelOffer().
    /// @param  from Address of the Privileged Shareholder that cancelled the Offer.
    event OfferCancelled(address indexed from);

    /// @notice Emitted during withdraw().
    /// @param  user Address of the user who decided to withdraw their Ether.
    /// @param  amount Amount of Ether that has been withdrawn.
    event Withdrawal(address indexed user, uint256 amount);

    /// @notice Emitted during changeOffer().
    /// @param  from Address of the shareholder that decided to change their Offer.
    /// @param  value New Price for each share in the Offer.
    event OfferChanged(address indexed from, uint256 value);

    /// @notice Emitted during payDividend().
    /// @param  holder Address of the shareholder that collects their share in the Payments for licenses.
    /// @param  value Accumulated Ether from the Payments for the address.
    /// @param  numberOfPayments Number of Payments from which the dividend have been collected.
    event DividendPaid(
        address indexed holder,
        uint256 value,
        uint256 numberOfPayments
    );

    /// @notice Emitted during payDividend().
    /// @param  holder Address of the shareholder that collects thier share in the Payments for licenses.
    /// @param  value Accumulated Ether from the payments before the function had to be halted due to lack of gas.
    /// @param  numberOfPaymentsLeft Number of payments from which the user has still dividends to be collected.
    event DividendPaidOnlyPartly(
        address indexed holder,
        uint256 value,
        uint256 numberOfPaymentsLeft
    );

    /// @notice Emitted during payEarndFeesToAllPrivileged().
    /// @param  value The value in Ether that has been paid proportionally to each Privileged Shareholder as a fee for trading shares.
    event EarndFeesToAllPrivileged(uint256 value);

    /// @notice Emitted during payEarndFeesToAllPrivileged().
    event GasLimitTooLow();

    /// @notice Emitted during putNewLicense().
    /// @param creator Address of the Privileged Shareholder that saves a new license.
    event NewLicenseCreated(address indexed creator);

    /// @notice Emitted during activateLicense().
    /// @param  remover Address of the Privileged Shareholder that set active status of the licenses to false.
    /// @param  licenseHash Hash of the deactivated license.
    event LicenseDeactivated(address indexed remover, bytes32 licenseHash);

    /// @notice Emitted during activateLicense().
    /// @param  activator Address of the Privileged Shareholder that set active status of the licenses to true.
    /// @param  licenseHash Hash of the activated license.
    event LicenseActivated(address indexed activator, bytes32 licenseHash);

    /// @notice Emitted during signLicense().
    /// @param  payer Address of the user that creates a new Payment for the license.
    /// @param  licenseHash The hash of the bought license.
    event NewPayment(address indexed payer, bytes32 licenseHash);

    /**
     * @notice Emitted during BananasharesToken Minting.
     * @param  address_1 The address that receives `tokens_mined_1`.
     * @param  address_2 The address that receives `tokens_mined_2`.
     * @param  tokens_mined_1 The amount of tokens minted for `address_1`.
     * @param  tokens_mined_2 The amount of tokens minted for `address_2`.
     */
    event GovTokensMinted(
        address indexed address_1,
        address indexed address_2,
        uint256 tokens_mined_1,
        uint256 tokens_mined_2
    );

    event GasUsage(uint256 gas);
}
