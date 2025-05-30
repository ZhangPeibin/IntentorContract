// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

interface IIntentRequest {
    
    struct IntentReq {
        string intent;
        string platform;
        address fromToken;
        address toToken;
        uint256 amount;
        uint32 chainId;
    }
}