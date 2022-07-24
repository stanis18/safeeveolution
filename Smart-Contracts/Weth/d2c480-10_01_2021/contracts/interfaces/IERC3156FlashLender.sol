// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.5.0;

interface IERC3156FlashLender {
    function flashLoan(address receiver, address token, uint256 value, bytes calldata) external;
    function flashFee(address token, uint256 value) external view returns (uint256);
    function maxFlashAmount(address token) external view returns (uint256);
}