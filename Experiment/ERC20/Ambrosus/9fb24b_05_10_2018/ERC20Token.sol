// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.4.11;

import "./SafeMath.sol";

/// @title Amber Token contract
/// @author Marek Kirejczyk <marek.kirejczyk@gmail.com>
/// @notice  invariant  totalSupply_  ==  __verifier_sum_uint(balances)
contract Amber is SafeMath {

    // Constants
    string public constant name = "Food Token";
    string public constant symbol = "FOOD";
    uint public constant decimals = 18;
    uint public constant THAWING_DURATION = 63072000;
    uint public constant MAX_TOTAL_TOKEN_AMOUNT_OFFERED_TO_PUBLIC = 1000000 * 10 ** decimals; // Max amount of tokens offered to the public

    // Only changed in constructor
    uint public startTime; // Contribution start time in seconds
    uint public endTime; // Contribution end time in seconds
    address public minter;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply_;
    

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    mapping (address => uint) preallocatedBalances;

    modifier only_minter {
        assert(msg.sender == minter);
        _;
    }

    modifier is_later_than(uint x) {
        assert(now > x);
        _;
    }

    modifier max_total_token_amount_not_reached(uint amount) {
        assert(safeAdd(totalSupply_, amount) <= MAX_TOTAL_TOKEN_AMOUNT_OFFERED_TO_PUBLIC);
        _;
    }

    constructor (uint _startTime, uint _endTime) public{
      startTime = _startTime;
      endTime = _endTime;
      minter = msg.sender;
      totalSupply_ = 0;
    }
    
    function preallocateToken(address recipient, uint amount)
        external
        only_minter
        max_total_token_amount_not_reached(amount)
    {
        preallocatedBalances[recipient] = safeAdd(preallocatedBalances[recipient], amount);
        totalSupply_ = safeAdd(totalSupply_, amount);
    }
    
    function unlockBalance(address recipient) public
        is_later_than(endTime + THAWING_DURATION)
    {
        balances[recipient] = safeAdd(balances[recipient], preallocatedBalances[recipient]);
        preallocatedBalances[recipient] = 0;
    }

    function preallocatedBalanceOf(address _owner) public returns (uint balance) {
        return preallocatedBalances[_owner];
    }

    function mintLiquidToken(address recipient, uint amount)
        external
        only_minter
        max_total_token_amount_not_reached(amount)
    {
        balances[recipient] = safeAdd(balances[recipient], amount);
        totalSupply_ = safeAdd(totalSupply_, amount);
    }

    /// @notice  postcondition ( ( balances[msg.sender] ==  __verifier_old_uint ( balances[msg.sender] ) - _value  && msg.sender  != _to ) ||   ( balances[msg.sender] ==  __verifier_old_uint ( balances[msg.sender]) && msg.sender  == _to ) &&  success ) || !success
    /// @notice  postcondition ( ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) + _value  && msg.sender  != _to ) ||   ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) && msg.sender  == _to ) &&  success ) || !success
    /// @notice  emits  Transfer
    function transfer(address _to, uint256 _value) public
      is_later_than(endTime)
      returns (bool success) 
    {
      return _transfer(_to, _value);
    }

    /// @notice  postcondition ( ( balances[_from] ==  __verifier_old_uint (balances[_from] ) - _value  &&  _from  != _to ) ||   ( balances[_from] ==  __verifier_old_uint ( balances[_from] ) &&  _from== _to ) &&  success )   || !success
    /// @notice  postcondition ( ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) + _value  &&  _from  != _to ) ||   ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) &&  _from  ==_to ) &&  success )   || !success
    /// @notice  postcondition ( allowed[_from ][msg.sender] ==  __verifier_old_uint (allowed[_from ][msg.sender] ) - _value && success) || ( allowed[_from ][msg.sender] ==  __verifier_old_uint (allowed[_from ][msg.sender] ) && !success) ||  _from  == msg.sender
    /// @notice  postcondition  allowed[_from ][msg.sender]  <= __verifier_old_uint (allowed[_from ][msg.sender] ) ||  _from  == msg.sender
    /// @notice  emits  Transfer
    function transferFrom(address _from, address _to, uint256 _value) public
      is_later_than(endTime)
      returns (bool success) 
    {
      return _transferFrom(_from, _to, _value);
    }

    function setMinterAddress(address _minter) public only_minter {
      minter = _minter;
    }

    /// @notice postcondition balances[_owner] == balance
    function balanceOf(address _owner) public returns (uint256 balance) {
        return balances[_owner];
    }

    /// @notice  postcondition (allowed[msg.sender ][ _spender] ==  _value  &&  success) || ( allowed[msg.sender ][ _spender] ==  __verifier_old_uint ( allowed[msg.sender ][ _spender] ) && !success )    
    /// @notice  emits  Approval
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice postcondition allowed[_owner][_spender] == remaining
    function allowance(address _owner, address _spender) public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }



    /// @notice  emits  Transfer
    function _transfer(address _to, uint256 _value) private returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    /// @notice  emits  Transfer
    function _transferFrom(address _from, address _to, uint256 _value) private returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
}
