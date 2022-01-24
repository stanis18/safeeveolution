// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.4.11;

contract ERC20 {
  uint public totalSupply;
  function allowance(address owner, address spender) public returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public;
  function balanceOf(address who) public returns (uint);
  function transfer(address to, uint value)  public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}