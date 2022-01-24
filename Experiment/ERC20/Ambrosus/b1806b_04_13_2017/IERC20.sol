// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.4.8;

/// @title ERC20 Token Protocol
/// @author Melonport AG <team@melonport.com>
/// @notice See https://github.com/ethereum/EIPs/issues/20
contract IERC20 {

    function totalSupply() public returns (uint256 totalSupply) {}
    function balanceOf(address _owner) public returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) public returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
    function approve(address _spender, uint256 _value) public returns (bool success) {}
    function allowance(address _owner, address _spender) public returns (uint256 remaining) {}


}