// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.5.0;


interface YieldFlashBorrowerLike {
    function executeOnFlashMint(uint256 fyDaiAmount, bytes memory data) external;
}