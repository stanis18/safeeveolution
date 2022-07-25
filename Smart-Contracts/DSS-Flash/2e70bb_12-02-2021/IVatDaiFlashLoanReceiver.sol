pragma solidity >= 0.5.0;

interface IVatDaiFlashLoanReceiver {

    /**
    * Must transfer _amount + _fee back to the flash loan contract when complete.
    */
    function onVatDaiFlashLoan(
        address initiator,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);

}