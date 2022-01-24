// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.5.2;

import "./IERC20.sol";
import "./SafeMath.sol";


/// @notice  invariant  _totalSupply  ==  __verifier_sum_uint(_balances)
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

   
    /// @notice postcondition supply == _totalSupply
    function totalSupply() public view returns (uint256 supply) {
        return _totalSupply;
    }

   
    /// @notice postcondition _balances[owner] == balance
    function balanceOf(address owner) public view returns (uint256 balance) {
        return _balances[owner];
    }


    /// @notice postcondition _allowed[owner][spender] == remaining
    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return _allowed[owner][spender];
    }

    
    /// @notice  postcondition ( ( _balances[msg.sender] ==  __verifier_old_uint (_balances[msg.sender] ) - value  && msg.sender  != to ) ||   ( _balances[msg.sender] ==  __verifier_old_uint ( _balances[msg.sender]) && msg.sender  == to ) &&  success )   || !success
    /// @notice  postcondition ( ( _balances[to] ==  __verifier_old_uint ( _balances[to] ) + value  && msg.sender  != to ) ||   ( _balances[to] ==  __verifier_old_uint ( _balances[to] ) && msg.sender  == to ) &&  success )   || !success
    /// @notice  emits  Transfer 
    function transfer(address to, uint256 value) public returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }

    
    /// @notice  postcondition (_allowed[msg.sender ][ spender] ==  value  &&  success) || ( _allowed[msg.sender ][ spender] ==  __verifier_old_uint ( _allowed[msg.sender ][ spender] ) && !success )    
    /// @notice  emits  Approval
    function approve(address spender, uint256 value) public returns (bool success) {
        _approve(msg.sender, spender, value);
        return true;
    }

    
    /// @notice  postcondition ( ( _balances[from] ==  __verifier_old_uint (_balances[from] ) - value  &&  from  != to ) ||   ( _balances[from] ==  __verifier_old_uint ( _balances[from] ) &&  from== to ) &&  success )   || !success
    /// @notice  postcondition ( ( _balances[to] ==  __verifier_old_uint ( _balances[to] ) + value  &&  from  != to ) ||   ( _balances[to] ==  __verifier_old_uint ( _balances[to] ) &&  from  ==to ) &&  success )   || !success
    /// @notice  postcondition  (_allowed[from ][msg.sender] ==  __verifier_old_uint (_allowed[from ][msg.sender] ) - value && success) || (_allowed[from ][msg.sender] ==  __verifier_old_uint (_allowed[from ][msg.sender] ) && !success) || from  == msg.sender
    /// @notice  postcondition  _allowed[from ][msg.sender]  <= __verifier_old_uint (_allowed[from ][msg.sender] ) ||  from  == msg.sender
    /// @notice  emits  Transfer
    /// @notice  emits  Approval
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    
    /// @notice  emits  Approval
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

   
    /// @notice  emits  Approval 
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    
    /// @notice  emits  Transfer
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

 
    /// @notice  emits  Transfer
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    
    /// @notice  emits  Transfer
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

  
    /// @notice  emits  Approval
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    
    /// @notice  emits  Approval 
    /// @notice  emits  Transfer
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}
