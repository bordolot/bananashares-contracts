// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

library Asset_Structs {
    // ---------------------
    //    Structs
    // ---------------------

    struct Author {
        /// @dev The name of Privileged Shareholder.
        string name;
    }
    struct Offer {
        /// @dev The address of the offer's owner and creator. (20bytes)
        address from;
        /// @dev The base price for a share set by the owner of an offer. (12bytes)
        uint96 value;
        /// @dev The value added to the base price for a share as a fee for the protocol. (12bytes)
        uint96 ownerFee;
        /// @dev The value added to the base price for a share as a fee for the Provileged Shareholders. (12bytes)
        uint96 privilegedFee;
        /// @dev The number of shares to sell in the offer. (3bytes)
        uint24 amount;
    }
    struct Payment {
        /// @dev The hash of a License.
        bytes32 licenseHash;
        /// @dev The amount in Ether that was paid to purchase a License.
        uint224 paymentValue;
        /// @dev The address that made a `Payment`.
        address payer;
        /// @dev The date when a Payment was created.
        uint48 date;
    }
    struct License {
        /// @dev The hash of a `License`.
        bytes32 licenseHash;
        /// @dev The amount in Ether that needs to paid to purchase a `License`.
        uint224 value;
        /// @dev The switch that indicates if a `License` is availabe to purchase.
        bool active;
    }
    struct GlobalSettings {
        /// @dev The value used to calcutate `privilegedFee`.
        uint24 commission_for_privileged;
        /// @dev The value used to calcutate `ownerFee`.
        uint24 commission_for_protocol;
        /// @dev The mininum price per share in the `Offer`.
        uint96 min_sell_offer;
    }
}
