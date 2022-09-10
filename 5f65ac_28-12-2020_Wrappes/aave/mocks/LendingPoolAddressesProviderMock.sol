// SPDX-License-Identifier: GPL-3.0-or-later
// Derived from https://github.com/aave/protocol-v2/tree/master/contracts/protocol
pragma solidity >= 0.5.0;



contract LendingPoolAddressesProviderMock {

  address public getLendingPool;

  constructor (address lendingPool) {
    getLendingPool = lendingPool;
  }
}