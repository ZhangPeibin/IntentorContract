// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.28;

interface IUniswapPool {
    function liquidity() external view returns (uint128);
}