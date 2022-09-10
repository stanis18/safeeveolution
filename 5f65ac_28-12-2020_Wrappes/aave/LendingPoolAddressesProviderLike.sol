// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.5.0;


interface LendingPoolAddressesProviderLike {
    function getLendingPool() external view returns (address);
}