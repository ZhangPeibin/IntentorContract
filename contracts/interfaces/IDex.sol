// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDex {
  
    event SwapWhitelistUpdated(address indexed account, bool status);

    event RouterUpdated(address indexed oldRouter, address indexed newRouter);

    event WethUpdated(address indexed oldWeth, address indexed newWeth);

    event ReceivedETH(address indexed from, uint256 amount);
    event Refunded(address indexed to, address indexed token, uint256 amount);
    event Swapped(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        bool exactInput
    );

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address refundTo,
        bool exactInput
    ) external payable returns (uint256 amountOut);
}
