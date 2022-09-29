// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.5.0;


import "./IERC20.sol";
import "./SafeMath.sol";
import { IERC3156FlashBorrower } from "./IERC3156.sol";
import "./AaveFlashBorrowerLike.sol";
import "./LendingPoolLike.sol";
import "./LendingPoolAddressesProviderLike.sol";

/**
 * @author Alberto Cuesta Cañada
 * @dev ERC-3156 wrapper for Aave flash loans.
 */
contract AaveERC3156 is AaveFlashBorrowerLike {
    using SafeMath for uint256;

    LendingPoolLike public lendingPool;

    mapping(address => address) public underlyingToAsset;

    constructor(LendingPoolAddressesProviderLike provider) public {
        lendingPool = LendingPoolLike(provider.getLendingPool());
    }

    
    function flashLoan(address receiver, address token, uint256 value, bytes calldata data) external  {
        address receiverAddress = address(this);

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);

        uint256[] memory values = new uint256[](1);
        values[0] = value;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory wrappedData;
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

    function executeOperation(
        address[] calldata tokens,
        uint256[] calldata values,
        uint256[] calldata fees,
        address initiator,
        bytes calldata wrappedData
    )
        external  returns (bool)
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

    
    function flashFee(address token, uint256 value) external view  returns (uint256) {
        ReserveData memory reserveData;
        require(reserveData.aTokenAddress != address(0), "Unsupported currency");
        return value.mul(9).div(10000); // lendingPool.FLASHLOAN_PREMIUM_TOTAL()
    }

    
    function flashSupply(address token) external view  returns (uint256) {
        ReserveData memory reserveData;
        return reserveData.aTokenAddress != address(0) ? IERC20(token).balanceOf(reserveData.aTokenAddress) : 0;
    }

    struct ReserveData {
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 currentLiquidityRate;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint8 id;
    }

    struct ReserveConfigurationMap {
        uint256 data;
    }
}