//SPDX-License-Identifier:BUSL-1.1

pragma solidity 0.8.23;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

contract AssetFactoryMods {
    /**
     * @dev The switches for the `nonReentrant` modifier.
     */
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /**
     * @dev Storage slot where the `_status` value for the `nonReentrant` modifier is stored.
     * This is the keccak-256 hash of "AssetFactoryMods.nonReentrant._status" subtracted by 1.
     */
    bytes32 internal constant _status_ADDRESS_SLOT =
        0x5206f8f04163e00d1e6d2e8ebcf846b0e2bc0eb93ddaaadf84bcbedf4a4976bd;

    // -----------------
    //    Errors
    // -----------------
    /**
     * @dev Unauthorized context call.
     */
    error UnauthorizedCallContext();

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    // -----------------
    //    Modifiers
    // -----------------

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    constructor() {
        StorageSlot.getUint256Slot(_status_ADDRESS_SLOT).value = NOT_ENTERED;
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (StorageSlot.getUint256Slot(_status_ADDRESS_SLOT).value == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        StorageSlot.getUint256Slot(_status_ADDRESS_SLOT).value = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        StorageSlot.getUint256Slot(_status_ADDRESS_SLOT).value = NOT_ENTERED;
    }
}
