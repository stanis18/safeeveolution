// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity 0.4.18;

import "./IERC20.sol";

/// @notice  invariant  _totalSupply  ==  __verifier_sum_uint(balances)
contract ERC20Token is IERC20 {

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    /// @notice  postcondition ( ( balances[msg.sender] ==  __verifier_old_uint (balances[msg.sender] ) - _value  && msg.sender  != _to ) || ( balances[msg.sender] ==  __verifier_old_uint ( balances[msg.sender]) && msg.sender  == _to ) &&  success ) || !success
    /// @notice  postcondition ( ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) + _value  && msg.sender  != _to ) || ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) && msg.sender  == _to ) &&  success ) || !success
    /// @notice  emits Transfer 
    function transfer(address _to, uint _value)
        public
        returns (bool success) 
    {
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]); 
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice  postcondition ( ( balances[_from] ==  __verifier_old_uint (balances[_from] ) - _value  &&  _from  != _to ) || ( balances[_from] ==  __verifier_old_uint ( balances[_from] ) &&  _from == _to ) &&  success ) || !success
    /// @notice  postcondition ( ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) + _value  &&  _from  != _to ) || ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) &&  _from  == _to ) &&  success ) || !success
    /// @notice  postcondition ( allowed[_from ][msg.sender] ==  __verifier_old_uint (allowed[_from ][msg.sender] ) - _value ) || ( allowed[_from ][msg.sender] ==  __verifier_old_uint (allowed[_from ][msg.sender] ) && !success) ||  _from  == msg.sender
    /// @notice  postcondition  allowed[_from ][msg.sender]  <= __verifier_old_uint (allowed[_from ][msg.sender] ) ||  _from  == msg.sender
    /// @notice  emits  Transfer
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool success) 
    {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]); 
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice  postcondition (allowed[msg.sender ][ _spender] ==  _value  &&  success) || ( allowed[msg.sender ][ _spender] ==  __verifier_old_uint ( allowed[msg.sender ][ _spender] ) && !success )    
    /// @notice  emits  Approval
    function approve(address _spender, uint _value) 
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice postcondition balances[_owner] == balance
    function balanceOf(address _owner)
        public
        view
        returns (uint balance)
    {
        return balances[_owner];
    }

    /// @notice postcondition allowed[_owner][_spender] == remaining
    function allowance(address _owner, address _spender) 
        public
        view
        returns (uint remaining)
    {
        return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public _totalSupply;
}