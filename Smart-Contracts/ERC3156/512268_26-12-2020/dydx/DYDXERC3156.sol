// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >= 0.5.0;


import "./SafeMath.sol";
import "./IERC20.sol";
import { IERC3156FlashBorrower, IERC3156FlashLender } from "../interfaces/IERC3156.sol";
import "./interfaces/SoloMarginLike.sol";
import "./interfaces/DYDXFlashBorrowerLike.sol";
import "./libraries/DYDXDataTypes.sol";


contract DYDXERC3156 is IERC3156FlashLender, DYDXFlashBorrowerLike {
    using SafeMath for uint256;

    uint256 internal NULL_ACCOUNT_ID = 0;
    uint256 internal NULL_MARKET_ID = 0;
    DYDXDataTypes.AssetAmount internal NULL_AMOUNT = DYDXDataTypes.AssetAmount({
        sign: false,
        denomination: DYDXDataTypes.AssetDenomination.Wei,
        ref: DYDXDataTypes.AssetReference.Delta,
        value: 0
    });
    bytes internal NULL_DATA = "";

    SoloMarginLike public soloMargin;
    mapping(address => uint256) public tokenAddressToMarketId;
    mapping(address => bool) public tokensRegistered;

    constructor (SoloMarginLike soloMargin_) public {
        soloMargin = soloMargin_;
        uint256 marketId = 0;
        while (true) {
            address token = soloMargin.getMarketTokenAddress(marketId);
            if (token != address(0)) {
                tokenAddressToMarketId[token] = marketId;
                tokensRegistered[token] = true;
                IERC20(token).approve(address(soloMargin), uint256(-1));            
            } else {
                break;
            }
            marketId++;
        }
    }

    function flashSupply(address token) external view  returns (uint256) {
        return tokensRegistered[token] == true ? IERC20(token).balanceOf(address(soloMargin)) : 0;
    }

    function flashFee(address token, uint256 amount) public view  returns (uint256) {
        require(tokensRegistered[token], "Unsupported currency");
        // Add 1 wei for markets 0-1 and 2 wei for markets 2-3
        return marketIdFromTokenAddress(token) < 2 ? 1 : 2;
    }

    function flashLoan(address receiver, address token, uint256 amount, bytes memory data) external  {
        DYDXDataTypes.ActionArgs[] memory operations = new DYDXDataTypes.ActionArgs[](3);
        operations[0] = getWithdrawAction(token, amount);
        operations[1] = getCallAction(abi.encode(data, msg.sender, receiver, token, amount));
        operations[2] = getDepositAction(token, amount.add(flashFee(token, amount)));
        DYDXDataTypes.AccountInfo[] memory accountInfos = new DYDXDataTypes.AccountInfo[](1);
        accountInfos[0] = getAccountInfo();

        soloMargin.operate(accountInfos, operations);
    }

    function callFunction(
        address innerSender,
        DYDXDataTypes.AccountInfo memory accountInfo,
        bytes memory wrappedData
    )
    public 
    {
        require(msg.sender == address(soloMargin), "Callback only from SoloMargin");
        require(innerSender == address(this), "FlashLoan only from this contract");

        (bytes memory data, address sender, address receiver, address token, uint256 amount) = 
            abi.decode(wrappedData, (bytes, address, address, address, uint256));

        // Transfer to `receiver`
        require(IERC20(token).transfer(receiver, amount), "Transfer failed");

        IERC3156FlashBorrower(receiver).onFlashLoan(sender, token, amount, flashFee(token, amount), data);
    }

    function getAccountInfo() internal view returns (DYDXDataTypes.AccountInfo memory) {
        return DYDXDataTypes.AccountInfo({
            owner: address(this),
            number: 1
        });
    }

    function getWithdrawAction(address token, uint256 amount)
    internal
    view
    returns (DYDXDataTypes.ActionArgs memory)
    {
        return DYDXDataTypes.ActionArgs({
            actionType: DYDXDataTypes.ActionType.Withdraw,
            accountId: 0,
            amount: DYDXDataTypes.AssetAmount({
                sign: false,
                denomination: DYDXDataTypes.AssetDenomination.Wei,
                ref: DYDXDataTypes.AssetReference.Delta,
                value: amount
            }),
            primaryMarketId: marketIdFromTokenAddress(token),
            secondaryMarketId: NULL_MARKET_ID,
            otherAddress: address(this),
            otherAccountId: NULL_ACCOUNT_ID,
            data: NULL_DATA
        });
    }

    function getDepositAction(address token, uint256 repaymentAmount)
    internal
    view
    returns (DYDXDataTypes.ActionArgs memory)
    {
        return DYDXDataTypes.ActionArgs({
            actionType: DYDXDataTypes.ActionType.Deposit,
            accountId: 0,
            amount: DYDXDataTypes.AssetAmount({
                sign: true,
                denomination: DYDXDataTypes.AssetDenomination.Wei,
                ref: DYDXDataTypes.AssetReference.Delta,
                value: repaymentAmount
            }),
            primaryMarketId: marketIdFromTokenAddress(token),
            secondaryMarketId: NULL_MARKET_ID,
            otherAddress: address(this),
            otherAccountId: NULL_ACCOUNT_ID,
            data: NULL_DATA
        });
    }

    function getCallAction(bytes memory data_)
    internal
    view
    returns (DYDXDataTypes.ActionArgs memory)
    {
        return DYDXDataTypes.ActionArgs({
            actionType: DYDXDataTypes.ActionType.Call,
            accountId: 0,
            amount: NULL_AMOUNT,
            primaryMarketId: NULL_MARKET_ID,
            secondaryMarketId: NULL_MARKET_ID,
            otherAddress: address(this),
            otherAccountId: NULL_ACCOUNT_ID,
            data: data_
        });
    }

    function marketIdFromTokenAddress(address token) internal view returns (uint256) {
        return tokenAddressToMarketId[token];
    }
}