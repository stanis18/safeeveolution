// SPDX-License-Identifier: LGPL-3.0-or-later
// use the flash loan EIP to receive tokens and then call arbitrary actions
pragma solidity >= 0.5.0;

import {IERC20} from "./IERC20.sol";

// import {ArgobytesClone} from "./ArgobytesClone.sol";
import {Address} from "./Address.sol";
import {ArgobytesAuth} from "./ArgobytesAuth.sol";
import {Address2} from "./Address2.sol";
import {IERC3156FlashBorrower} from "./IERC3156FlashBorrower.sol";
import {IERC3156FlashLender} from "./IERC3156FlashLender.sol";

contract ArgobytesFlashBorrower is IERC3156FlashBorrower {

    // because we make heavy use of delegatecall, we want to make sure our storage is durable
    bytes32 FLASH_BORROWER_POSITION;
    struct FlashBorrowerStorage {
        IERC3156FlashLender lender;
        address pending_target;
        bool pending_loan;
        bytes pending_calldata;
        bytes pending_return;
    }
    function flashBorrowerStorage() internal view returns (FlashBorrowerStorage memory s) {
        bytes32 position = FLASH_BORROWER_POSITION;
        // assembly {
        //     s.slot := position
        // }
    }

    function setLender(address new_lender) external {
        FlashBorrowerStorage memory s = flashBorrowerStorage();
        s.lender = IERC3156FlashLender(new_lender);
        // TODO: emit an event
    }

    /// @dev Initiate a flash loan
    function flashBorrow(
        address token,
        uint256 amount,
        address pending_target,
        ArgobytesAuth.CallType call_type,
        bytes memory pending_calldata
    ) public returns (bytes memory returned) {
        FlashBorrowerStorage memory s = flashBorrowerStorage();

        // check auth this if.. 
        // if (msg.sender != owner()) {
        //     requireAuth(action.target, call_type, action.target_calldata.toBytes4());
        // }

        // we could pass the calldata to the lender and have them pass it back, but that seems less safe
        // use storage so that no one can change it
        s.pending_target = pending_target;
        s.pending_loan = true;
        s.pending_calldata = pending_calldata;

        s.lender.flashLoan(this, token, amount, "");
        // s.pending_loan is changed to false

        // copy the call's returned value to return it from this function
        returned = s.pending_return;

        // clear the pending values
        s.pending_target = address(0);
        s.pending_calldata = "";
        s.pending_return = "";
    }
    
    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns(bytes32) {
       FlashBorrowerStorage memory s = flashBorrowerStorage();

        // auth
        // pending_loan is like the opposite of a re-entrancy guard
        require(
            s.pending_loan,
            "FlashBorrower !pending_loan"
        );
        require(
            msg.sender == address(s.lender),
            "FlashBorrower !lender"
        );
        require(
            initiator == address(this),
            "FlashBorrower !initiator"
        );

        // clear pending_loan now in case the delegatecall tries to do something sneaky
        // though i think storing things in state will protect things better
        s.pending_loan = false;

        require(
            Address.isContract(s.pending_target),
            "ArgobytesProxy.execute BAD_TARGET"
        );

        // uncheckedDelegateCall is safe because we just checked that `target` is a contract
        // emit an event with the response?
        bytes memory returned;
        // if (call_type == ArgobytesAuth.CallType.DELEGATE) {
        //     returned = Address2.uncheckedDelegateCall(
        //         s.pending_target,
        //         s.pending_calldata,
        //         "FlashLoanBorrower.onFlashLoan !delegatecall"
        //     );
        // } else {
        //     revert("wip");
        // }

        // since we can't return the call's return from here, we store it in state
        s.pending_return = returned;

        // approve paying back the loan
        IERC20(token).approve(address(s.lender), amount + fee);

        // return their special response
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
