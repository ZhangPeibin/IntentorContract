// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/TransferHelper.sol";
import "../interfaces/ISwapRouter.sol";
import "./Basedex.sol";


contract Uniswap is Basedex, ReentrancyGuard {
    constructor(
        address _router,
        address _weth
    ) Basedex(msg.sender, _router, _weth) {}

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum,
        bool exactInput
    ) external  override nonReentrant onlyWhitelisted returns (uint256 amountOut) {
        require(tokenIn != address(0) && tokenOut != address(0), "Invalid token addresses");
        require(tokenIn != tokenOut, "TokenIn and TokenOut must be different");
        require(amountIn > 0, "Amount must be greater than zero");

        //swap exactInput tokenIn for unkown tokenOut
        if (exactInput) {
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                amountIn
            );
            TransferHelper.safeApprove(tokenIn, router, amountIn);
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    fee: poolFee,
                    recipient: msg.sender,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMinimum,
                    sqrtPriceLimitX96: 0
                });

            try ISwapRouter(router).exactInputSingle(params) returns (
                uint256 amountOutReceived
            ) {
                amountOut = amountOutReceived;
            } catch {
                TransferHelper.safeTransfer(tokenIn, msg.sender, amountIn);
                revert("Swap failed");
            }
             emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
            // The call to `exactInputSingle` executes the swap.
        }

        // Emit the Swap event

        return amountOut;
    }
}
