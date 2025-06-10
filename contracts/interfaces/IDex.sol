// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDex {
    event Swap(
        address indexed sender,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    event SwapWhitelistUpdated(
        address indexed account,
        bool status
    );

    event RouterUpdated(
        address indexed oldRouter,
        address indexed newRouter
    );

    event WethUpdated(
        address indexed oldWeth,
        address indexed newWeth
    );


    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum,
        bool exactInput
    ) external returns (uint256 amountOut);
}
