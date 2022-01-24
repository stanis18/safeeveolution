/*
   Copyright 2017 Nexus Development, LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.4.8;


import "./IERC20.sol";

/// @notice  invariant  _supply  ==  __verifier_sum_uint(_balances)
contract DSToken is IERC20 {

      mapping( address => uint ) _balances;
    mapping( address => mapping( address => uint ) ) _approvals;
    uint _supply;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);    

    constructor( uint initial_balance ) public {
        _balances[msg.sender] = initial_balance;
        _supply = initial_balance;
    }

    /// @notice postcondition supply == _supply
    function totalSupply() public returns (uint supply) {
        return _supply;
    }

    /// @notice postcondition _balances[who] == value
    function balanceOf( address who ) public returns (uint value) {
        return _balances[who];
    }

    /// @notice  postcondition ( ( _balances[msg.sender] ==  __verifier_old_uint (_balances[msg.sender] ) - value  && msg.sender  != to ) ||   ( _balances[msg.sender] ==  __verifier_old_uint ( _balances[msg.sender]) && msg.sender  == to ) &&  ok )   || !ok
    /// @notice  postcondition ( ( _balances[to] ==  __verifier_old_uint ( _balances[to] ) + value  && msg.sender  != to ) ||   ( _balances[to] ==  __verifier_old_uint ( _balances[to] ) && msg.sender  == to ) &&  ok )   || !ok
    /// @notice  emits  Transfer 
    function transfer( address to, uint value) public returns (bool ok) {
        if( _balances[msg.sender] < value ) {
            revert();
        }
        if( !safeToAdd(_balances[to], value) ) {
            revert();
        }
        _balances[msg.sender] -= value;
        _balances[to] += value;
        emit Transfer( msg.sender, to, value );
        return true;
    }

    /// @notice  postcondition ( ( _balances[from] ==  __verifier_old_uint (_balances[from] ) - value  &&  from  != to ) ||   ( _balances[from] ==  __verifier_old_uint ( _balances[from] ) &&  from== to ) &&  ok )   || !ok
    /// @notice  postcondition ( ( _balances[to] ==  __verifier_old_uint ( _balances[to] ) + value  &&  from  != to ) ||   ( _balances[to] ==  __verifier_old_uint ( _balances[to] ) &&  from  ==to ) &&  ok )   || !ok
    /// @notice  postcondition  (_approvals[from ][msg.sender] ==  __verifier_old_uint (_approvals[from ][msg.sender] ) - value)  || (_approvals[from ][msg.sender] ==  __verifier_old_uint (_approvals[from ][msg.sender] ) && !ok) || from  == msg.sender
    /// @notice  postcondition  _approvals[from ][msg.sender]  <= __verifier_old_uint (_approvals[from ][msg.sender] ) ||  from  == msg.sender
    /// @notice  emits  Transfer
    function transferFrom( address from, address to, uint value) public returns (bool ok) {
        // if you don't have enough balance, throw
        if( _balances[from] < value ) {
            revert();
        }
        // if you don't have approval, throw
        if( _approvals[from][msg.sender] < value ) {
            revert();
        }
        if( !safeToAdd(_balances[to], value) ) {
            revert();
        }
        // transfer and return true
        _approvals[from][msg.sender] -= value;
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer( from, to, value );
        return true;
    }

    /// @notice  postcondition (_approvals[msg.sender ][ spender] ==  value  &&  ok) || ( _approvals[msg.sender ][ spender] ==  __verifier_old_uint ( _approvals[msg.sender ][ spender] ) && !ok )    
    /// @notice  emits  Approval
    function approve(address spender, uint value) public returns (bool ok) {
        _approvals[msg.sender][spender] = value;
        emit Approval( msg.sender, spender, value );
        return true;
    }

    // @notice postcondition _approvals[owner][spender] == _allowance
    function allowance(address owner, address spender) public returns (uint _allowance) {
        return _approvals[owner][spender];
    }
    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }

    function assert(bool x) internal {
        if (!x) revert();
    }

    function burn(uint x)  public {
        assert(_balances[msg.sender] - x <= _balances[msg.sender]);
        _balances[msg.sender] -= x;
    }
    function mint(uint x)  public {
        assert(_balances[msg.sender] + x >= _balances[msg.sender]);
        _balances[msg.sender] += x;
    }
}
