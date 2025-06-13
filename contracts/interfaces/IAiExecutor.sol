// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IIntentRequest.sol";
import "./IFee.sol";
interface IAiExecutor {
    
    enum ValidationResult {
        INSUFFICIENT_BALANCE,
        ALLOWANCE_NOT_ENOUGH,
        NONE
    }

    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    event FeeUpdated(address indexed previousFee, address indexed newFee);
    event AiValidatorUpdated(
        address indexed previousValidator,
        address indexed newValidator
    );

    event ExecuteValidateFailed(
        address indexed executor,
        IIntentRequest.IntentReq intentReq,
        ValidationResult result
    );

    event FeeAmountUpdated(
        address indexed token,
        address indexed feeRecipient,
        uint256 feeAmount
    );

    function fee() external view returns (IFee);

    function execute(
        IIntentRequest.IntentReq memory intentReq,
        address receiver
    ) external payable returns (bytes memory);

    function validate(
        IIntentRequest.IntentReq memory intentReq
    ) external view returns (bool success, ValidationResult result);
}
