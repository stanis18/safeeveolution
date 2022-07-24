// SPDX-License-Identifier: agpl-3.0
pragma solidity >= 0.5.0;
pragma experimental ABIEncoderV2;


contract LendingPoolAddressesProviderMock {

  address public getLendingPool;

  constructor (address lendingPool) {
    getLendingPool = lendingPool;
  }
}