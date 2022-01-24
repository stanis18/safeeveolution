// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity 0.4.8;

import "./SafeMath.sol";
import "./ERC20Token.sol";
/// @notice  invariant  totalSupply_  ==  __verifier_sum_uint(balances)
contract FoodToken is ERC20, SafeMath {

    string public constant name = "FOOD Token";
    string public constant symbol = "FDT";
    uint public constant decimals = 18;

    constructor() public{
      totalSupply_ = 0;
    }
    
    function grant(address wallet, uint amount) public{
      totalSupply_ += amount;
      balances[wallet] = amount;
    }

}
