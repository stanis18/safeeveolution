// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./registry.sol";

contract Proxy {

    /* variables */

    /* functions */

    Registry registry;
    bytes32 spec;
    address implementation;
    address author;

    constructor(Registry _registry, bytes32 _spec, address _implementation /* constructor parameters */) public {
        require(_spec != bytes32(0));
        registry = _registry;
        spec = _spec;
        author = msg.sender;

        /*constructor initialization */

        _upgrade(_implementation);
    }

    function upgrade(address new_implementation) public {
        _upgrade(new_implementation);
    }

    function _upgrade(address new_implementation) internal {
        require(msg.sender == author);
        bytes32 spec_id = registry.get_spec(new_implementation);
        require(spec_id == spec);
        implementation = new_implementation;
    }
    
}