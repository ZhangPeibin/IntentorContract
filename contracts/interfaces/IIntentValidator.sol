// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IIntentRequest.sol";

interface IIntentValidator {
    enum ValidationResult {
        INSUFFICIENT_BALANCE,
        ALLOWANCE_NOT_ENOUGH,
        NONE
    }

    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    event AiExecutorUpdated(address indexed previousExecutor, address indexed newExecutor);


    function aiExecutor() external view returns (address);
    /**
     * @dev Validates the intent request.
     * @param intentReq The intent request to validate.
     * @return success A boolean indicating if the validation was successful.
     * @return result The validation result, which can be one of the ValidationResult enum values.
     */
    function validate(
        IIntentRequest.IntentReq memory intentReq
    ) external view returns (bool success, ValidationResult result);
}