// SPDX-License-Identifier: GPL-3.0-or-later
// Derived from https://github.com/yieldprotocol/fyDai
pragma solidity >= 0.5.0;


library SafeCast {
    /// @dev Safe casting from uint256 to uint128
    function toUint128(uint256 x) internal pure returns(uint128) {
        require(
            x <= type(uint128).max,
            "SafeCast: Cast overflow"
        );
        return uint128(x);
    }

    /// @dev Safe casting from uint256 to int256
    function toInt256(uint256 x) internal pure returns(int256) {
        require(
            x <= uint256(type(int256).max),
            "SafeCast: Cast overflow"
        );
        return int256(x);
    }
}