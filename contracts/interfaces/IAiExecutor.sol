// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IFee.sol";
import  "../lib/Enum.sol";
interface IAiExecutor {
    struct IntentReq {
        uint256 amount; // 32bytes
        uint256 amountMinout; //32 bytes
        address fromToken; // 20 bytes
        address toToken; // 20 bytes
        uint24 poolFee;
        uint32 chainId; //  4bytes
        bool exactInput; // 1bytes
        Enum.DEX dex; // 1bytes
    }

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
        IntentReq intentReq,
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
        Enum.DEX indexed key
    );

    event DexRouterRemoved(address oldRouter, Enum.DEX indexed dex);

    event Executed(
        address indexed user,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOut,
        address refundTo
    );

    function execute(
        IntentReq memory intentReq
    ) external payable returns (uint256 amount);

    function addDexRouter(Enum.DEX dex, address router) external;
    function removeDexRouter(Enum.DEX dex) external;
}
