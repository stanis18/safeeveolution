// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;


interface LendingPoolAddressesProviderLike {
    function getLendingPool() external view returns (address);
}