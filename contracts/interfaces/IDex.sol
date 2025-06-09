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

    function router() external view returns (address);
    function weth() external view returns (address);

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bool exactInput
    ) external payable returns (uint256 amountOut);

    function _swapETHForTokens(
        address tokenOut,
        uint256 amountOutMin
    ) external payable returns (uint256 amountOut);

}