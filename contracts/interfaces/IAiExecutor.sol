// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.28;

import "./IIntentValidator.sol";
import "./IFee.sol";
interface IAiExecutor {

    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    event FeeUpdated(address indexed previousFee, address indexed newFee);
    event AiValidatorUpdated(address indexed previousValidator, address indexed newValidator);

    event ExecuteValidateFailed(
        address indexed executor,
        IIntentRequest.IntentReq intentReq,
        IIntentValidator.ValidationResult result
    );

    function aiValidator() external view returns (IIntentValidator);
    function fee() external view returns (IFee);

    function execute(IIntentRequest.IntentReq memory intentReq, address receiver) external payable returns (bytes memory);
}