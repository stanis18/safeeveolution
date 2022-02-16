pragma solidity >=0.5.0 <0.9.0;

contract Registry {
    address maintainer;
    mapping (address => bytes32) verified_addrs;

    constructor() public {
        maintainer = msg.sender;
    }

    function new_mapping(address addr, bytes32 spec_id) public {
        if (msg.sender == maintainer && spec_id != bytes32(0)) {
            verified_addrs[addr] = spec_id;
        }
    }

    function get_spec(address addr) view public returns (bytes32) {
        return verified_addrs[addr];
    }

}