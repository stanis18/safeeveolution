// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC3156FlashBorrower, IERC3156FlashLender } from "../interfaces/IERC3156.sol";
import "./interfaces/AaveFlashBorrowerLike.sol";
import "./interfaces/LendingPoolLike.sol";
import "./interfaces/LendingPoolAddressesProviderLike.sol";
import "./libraries/AaveDataTypes.sol";


/**
 * @author Alberto Cuesta Cañada
 * @dev ERC-3156 wrapper for Aave flash loans.
 */
contract AaveERC3156 is IERC3156FlashLender, AaveFlashBorrowerLike {
    using SafeMath for uint256;

    LendingPoolLike public lendingPool;

    mapping(address => address) public underlyingToAsset;

    constructor(LendingPoolAddressesProviderLike provider) {
        lendingPool = LendingPoolLike(provider.getLendingPool());
    }

    /**
     * @dev Loan `value` tokens to `receiver`, which needs to return them plus fee to this contract within the same transaction.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 value, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency.
     * @param value The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(address receiver, address token, uint256 value, bytes calldata data) external override {
        address receiverAddress = address(this);

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);

        uint256[] memory values = new uint256[](1);
        values[0] = value;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory wrappedData = abi.encode(data, msg.sender, receiver);
        uint16 referralCode = 0;

        lendingPool.flashLoan(
            receiverAddress,
            tokens,
            values,
            modes,
            onBehalfOf,
            wrappedData,
            referralCode
        );
    }

    /// @dev Aave flash loan callback. It sends the value borrowed to `receiver`, and expects that the value plus the fee will be transferred back.
    function executeOperation(
        address[] calldata tokens,
        uint256[] calldata values,
        uint256[] calldata fees,
        address initiator,
        bytes calldata wrappedData
    )
        external override returns (bool)
    {
        require(msg.sender == address(lendingPool), "Callbacks only allowed from Lending Pool");
        require(initiator == address(this), "Callbacks only initiated from this contract");

        (bytes memory data, address sender, address receiver) = abi.decode(wrappedData, (bytes, address, address));

        // Send the tokens to the original receiver using the ERC-3156 interface
        IERC20(tokens[0]).transfer(sender, values[0]);
        IERC3156FlashBorrower(receiver).onFlashLoan(sender, tokens[0], values[0], fees[0], data);

        // Approve the LendingPool contract allowance to *pull* the owed amount
        IERC20(tokens[0]).approve(address(lendingPool), values[0].add(fees[0]));

        return true;
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param value The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 value) external view override returns (uint256) {
        AaveDataTypes.ReserveData memory reserveData = lendingPool.getReserveData(token);
        require(reserveData.aTokenAddress != address(0), "Unsupported currency");
        return value.mul(9).div(10000); // lendingPool.FLASHLOAN_PREMIUM_TOTAL()
    }

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function flashSupply(address token) external view override returns (uint256) {
        AaveDataTypes.ReserveData memory reserveData = lendingPool.getReserveData(token);
        return reserveData.aTokenAddress != address(0) ? IERC20(token).balanceOf(reserveData.aTokenAddress) : 0;
    }
}