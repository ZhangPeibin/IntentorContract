// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDex {
    
    struct SwapParam {
        uint256 amountIn;
        uint256 amountOutMinimum;
        address tokenIn; // 20 bytes
        address tokenOut; // 20 bytes
        address refundTo; 
        uint24 poolFee;
        bool exactInput;
    }

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

    function setSwapWhitelist(
        address[] calldata accounts,
        bool status
    ) external;

    function setSwapWhitelistSingle(
        address account,
        bool status
    ) external; 

    function isWhitelisted(address account) external view returns (bool);

    function swap(
        SwapParam memory swapParam
    ) external payable returns (uint256 amountOut);
}
