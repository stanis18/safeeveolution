// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.5.0;


interface UniswapV2FactoryLike {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}