// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Simple {

    uint a;
    uint b;
    bool c;

    /** 
 * @notice postcondition a == _a
 @notice postcondition b == _b
 @notice postcondition c == _c 
 */ 
constructor(uint _a, uint _b, bool _c) public {
    	a = _a;
		b = _b;
		c = _c;
    }	

    /** 
 * @notice postcondition a == _a 
 */ 
function set_a(uint _a) public {
        a = _a;
    }

    /** 
 * @notice postcondition b == _b 
 */ 
function set_b(uint _b) public {
        b = _b;
    }

    /** 
 * @notice postcondition c == _c 
 */ 
function set_c(bool _c) public {
        c = _c;
    }

    /** 
 * @notice postcondition resp == _a || resp == _b 
 */ 
function get_selected() view public returns (uint resp) {
        if(c) {
            return a;
        } else {
            return b;
        }
    }
}