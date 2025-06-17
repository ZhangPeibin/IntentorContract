// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

interface IIntentRequest {
    
    struct IntentReq {
        address receiver;
        uint256 amountMinout;
        bool exactInput;
        string intent;
        string platform;
        address fromToken;
        address toToken;
        uint256 amount;
        uint32 chainId;
    }
}