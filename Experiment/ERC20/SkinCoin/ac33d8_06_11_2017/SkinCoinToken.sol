// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.4.11;
import "./SafeMath.sol";
import "./ERC20.sol";
import "./Spender.sol";


contract SkinCoin is ERC20 {
  string public constant name = "SkinCoin";
  string public constant symbol = "SKIN";
  uint public constant decimals = 6;

  uint public totalSupply;
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  // Constructor
  constructor() public {
      totalSupply = 1000000000000000;
      balances[msg.sender] = totalSupply; // Send all tokens to owner
  }

   ///@notice emits Transfer
  function burn(uint _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Transfer(msg.sender, address(0), _value);
    return true;
  }


  /* Approve and then communicate the approved contract in a single tx */
  ///@notice emits Approval
  function approveAndCall(address _spender, uint _value) public {    
      TokenSpender spender = TokenSpender(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value);
      }
  }

  mapping (address => mapping (address => uint)) allowed;

   /// @notice  postcondition ( ( balances[_from] ==  __verifier_old_uint (balances[_from] ) - _value  &&  _from  != _to ) ||   ( balances[_from] ==  __verifier_old_uint ( balances[_from] ) &&  _from== _to ) &&  success )   || !success
  /// @notice  postcondition ( ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) + _value  &&  _from  != _to ) ||   ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) &&  _from  ==_to ) &&  success )   || !success
  /// @notice  postcondition  (allowed[_from ][msg.sender] ==  __verifier_old_uint (allowed[_from ][msg.sender] ) - _value && success) || (allowed[_from ][msg.sender] ==  __verifier_old_uint (allowed[_from ][msg.sender] ) && !success) || _from  == msg.sender
  /// @notice  postcondition  allowed[_from ][msg.sender]  <= __verifier_old_uint (allowed[_from ][msg.sender] ) ||  _from  == msg.sender
  /// @notice  emits  Transfer
  function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) returns (bool success) {
    uint256 _allowance = allowed[_from][msg.sender];
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    
    return true;
  }

  /// @notice  postcondition (allowed[msg.sender ][ _spender] ==  _value  &&  success) || ( allowed[msg.sender ][ _spender] ==  __verifier_old_uint ( allowed[msg.sender ][ _spender] ) && !success )    
  /// @notice  emits  Approval
  function approve(address _spender, uint _value) public returns (bool success)  {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);

    return true;
  }

  /// @notice postcondition allowed[_owner][_spender] == remaining
  function allowance(address _owner, address _spender) public returns (uint remaining) {
    return allowed[_owner][_spender];
  }

   using SafeMath for uint;
  
  mapping(address => uint) balances;
  
  /*
   * Fix for the ERC20 short address attack  
  */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  /// @notice  postcondition ( ( balances[msg.sender] ==  __verifier_old_uint (balances[msg.sender] ) - _value  && msg.sender  != _to ) ||   ( balances[msg.sender] ==  __verifier_old_uint ( balances[msg.sender]) && msg.sender  == _to ) &&  success )   || !success
  /// @notice  postcondition ( ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) + _value  && msg.sender  != _to ) ||   ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) && msg.sender  == _to ) &&  success )   || !success
  /// @notice  emits  Transfer 
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   /// @notice postcondition balances[_owner] == balance
  function balanceOf(address _owner) public returns (uint balance) {
    return balances[_owner];
  }
}






