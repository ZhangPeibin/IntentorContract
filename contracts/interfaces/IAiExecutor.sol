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

    event FeeAmount(
        address indexed token,
        address indexed feeRecipient,
        uint256 feeAmount
    );

    event DexRouterUpdated(
        address indexed oldRouter,
        address indexed newRouter,
        bytes32 key
    );

    event DexRouterRemoved(address oldRouter, bytes32 indexed dexKey);


    event Executed(
        address indexed user,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOut,
        address refundTo
    );

    function fee() external view returns (IFee);

    function execute(
        IIntentRequest.IntentReq memory intentReq
    ) external payable returns (uint256 amount);

    function validate(
        IIntentRequest.IntentReq memory intentReq,
        uint256 msgValue
    ) external view returns (bool success, ValidationResult result);



    function addDexRouter(string calldata dex, address router) external;
    function removeDexRouter(string calldata dex) external;
    function getRouterByDex(
        string calldata dex
    ) external view returns (address);
}
