// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.4.24;

import "./IERC20.sol";
import "./SafeMath.sol";


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
/// @notice  invariant  totalSupply_  ==  __verifier_sum_uint(balances_)
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances_;

  mapping (address => mapping (address => uint256)) private allowed_;

  uint256 private totalSupply_;

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  /**
  * @dev Total number of tokens in existence
  */
  /// @notice postcondition supply == totalSupply_
  function totalSupply() public view returns (uint256 supply) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  /// @notice postcondition balances_[_owner] == balance
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances_[_owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  /// @notice postcondition allowed_[_owner][_spender] == remaining
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256 remaining)
  {
    return allowed_[_owner][_spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  /// @notice  postcondition ( ( balances_[msg.sender] ==  __verifier_old_uint (balances_[msg.sender] ) - _value  && msg.sender  != _to ) ||   ( balances_[msg.sender] ==  __verifier_old_uint ( balances_[msg.sender]) && msg.sender  == _to ) &&  success )   || !success
  /// @notice  postcondition ( ( balances_[_to] ==  __verifier_old_uint ( balances_[_to] ) + _value  && msg.sender  != _to ) ||   ( balances_[_to] ==  __verifier_old_uint ( balances_[_to] ) && msg.sender  == _to ) &&  success )   || !success
  /// @notice  emits  Transfer 
  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_value <= balances_[msg.sender]);
    require(_to != address(0));

    balances_[msg.sender] = balances_[msg.sender].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  /// @notice  postcondition (allowed_[msg.sender ][ _spender] ==  _value  &&  success) || ( allowed_[msg.sender ][ _spender] ==  __verifier_old_uint ( allowed_[msg.sender ][ _spender] ) && !success )    
  /// @notice  emits  Approval
  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0));

    allowed_[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  /// @notice  postcondition ( ( balances_[_from] ==  __verifier_old_uint (balances_[_from] ) - _value  &&  _from  != _to ) ||   ( balances_[_from] ==  __verifier_old_uint ( balances_[_from] ) &&  _from== _to ) &&  success )   || !success
  /// @notice  postcondition ( ( balances_[_to] ==  __verifier_old_uint ( balances_[_to] ) + _value  &&  _from  != _to ) ||   ( balances_[_to] ==  __verifier_old_uint ( balances_[_to] ) &&  _from  ==_to ) &&  success )   || !success
  /// @notice  postcondition ( allowed_[_from ][msg.sender] ==  __verifier_old_uint (allowed_[_from ][msg.sender] ) - _value && success) || ( allowed_[_from ][msg.sender] ==  __verifier_old_uint (allowed_[_from ][msg.sender] ) && !success) ||  _from  == msg.sender
  /// @notice  postcondition  allowed_[_from ][msg.sender]  <= __verifier_old_uint (allowed_[_from ][msg.sender] ) ||  _from  == msg.sender
  /// @notice  emits  Transfer 
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool success)
  {
    require(_value <= balances_[_from]);
    require(_value <= allowed_[_from][msg.sender]);
    require(_to != address(0));

    balances_[_from] = balances_[_from].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  /// @notice  emits  Approval 
  function increaseAllowance(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    require(_spender != address(0));

    allowed_[msg.sender][_spender] = (
      allowed_[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  /// @notice  emits  Approval
  function decreaseAllowance(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    require(_spender != address(0));

    allowed_[msg.sender][_spender] = (
      allowed_[msg.sender][_spender].sub(_subtractedValue));
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param _account The account that will receive the created tokens.
   * @param _amount The amount that will be created.
   */
  /// @notice  emits  Transfer
  function _mint(address _account, uint256 _amount) internal {
    require(_account != address(0));
    totalSupply_ = totalSupply_.add(_amount);
    balances_[_account] = balances_[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  /// @notice  emits  Transfer
  function _burn(address _account, uint256 _amount) internal {
    require(_account != address(0));
    require(_amount <= balances_[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances_[_account] = balances_[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal _burn function.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
    /// @notice  emits  Transfer 
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed_[_account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed_[_account][msg.sender] = allowed_[_account][msg.sender].sub(
      _amount);
    _burn(_account, _amount);
  }
}