pragma solidity >= 0.5.0;

interface IVatDaiFlashLoanReceiver {
    
    function onVatDaiFlashLoan(
        address initiator,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);

}