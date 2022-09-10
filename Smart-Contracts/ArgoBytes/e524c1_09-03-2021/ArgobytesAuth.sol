// SPDX-License-Identifier: LGPL-3.0-or-later
// base class for clone targets
// contains a very powerful "execute" function! The owner is in full control!
pragma solidity >= 0.5.0;


// import {Address} from "./Address.sol";

// import {Strings2} from "./Strings2.sol";
// import {IArgobytesAuthorizationRegistry} from "./ArgobytesAuthorizationRegistry.sol";
// import {IArgobytesFactory} from "./ArgobytesFactory.sol";
// import {Address2} from "./Address2.sol";
// import {Bytes2} from "./Bytes2.sol";

// import {ImmutablyOwnedClone} from "./ImmutablyOwnedClone.sol";

contract ArgobytesAuthEvents {
    event AuthorityTransferred(
        address indexed previous_authority,
        address indexed new_authority
    );
}

// TODO: should this be able to receive a flash loan?
contract ArgobytesAuth is ArgobytesAuthEvents {
    // using Address for address;
    // using Address2 for address;
    // using Bytes2 for bytes;

    enum CallType {
        Call,
        Delegate,
        Admin
    }

}
