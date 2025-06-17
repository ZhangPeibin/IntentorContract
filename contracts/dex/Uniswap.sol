// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/TransferHelper.sol";
import "../interfaces/ISwapRouter.sol";
import "./Basedex.sol";
import "../interfaces/IWETH.sol";

contract Uniswap is Basedex, ReentrancyGuard {
    constructor(
        address _router,
        address _weth
    ) Basedex(msg.sender, _router, _weth) {}

    function swap(
        SwapParam memory swapParam
    )
        external
        payable
        override
        nonReentrant
        onlyWhitelisted
        returns (uint256 amountOut)
    {
        require(swapParam.tokenIn != swapParam.tokenOut, "TokenIn and TokenOut must be different");

        require(swapParam.amountIn > 0, "Amount must be greater than zero");
        require(swapParam.refundTo != address(0), "Refund address cannot be zero");

        address inputToken = swapParam.tokenIn == address(0) ? weth : swapParam.tokenIn;
        address outputToken =swapParam.tokenOut == address(0) ? weth : swapParam.tokenOut;

        _handleInput(inputToken, swapParam.amountIn, swapParam.refundTo);

        TransferHelper.safeApprove(inputToken, router, swapParam.amountIn);

        //swap exactInput tokenIn for unkown tokenOut
        if (swapParam.exactInput) {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: inputToken,
                    tokenOut: outputToken,
                    fee: poolFee,
                    recipient: address(this),
                    amountIn: swapParam.amountIn,
                    amountOutMinimum: swapParam.amountOutMinimum,
                    sqrtPriceLimitX96: 0
                });

            try ISwapRouter(router).exactInputSingle(params) returns (
                uint256 amountOutReceived
            ) {
                amountOut = amountOutReceived;
                _handleOutput(outputToken, amountOut,swapParam. refundTo);
            } catch {
                _refund(inputToken, swapParam.amountIn,swapParam.refundTo);

                revert("Swap failed");
            }
            // The call to `exactInputSingle` executes the swap.
        } else {
            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
                .ExactOutputSingleParams({
                    tokenIn: inputToken,
                    tokenOut: outputToken,
                    fee: poolFee,
                    recipient: address(this),
                    amountOut: swapParam.amountOutMinimum,
                    amountInMaximum: swapParam.amountIn,
                    sqrtPriceLimitX96: 0
                });

            try ISwapRouter(router).exactOutputSingle(params) returns (
                uint256 amountInUsed
            ) {
                amountOut = swapParam.amountOutMinimum;
                _handleOutput(outputToken, amountOut, swapParam.refundTo);
                // Refund any unused input token
                if (amountInUsed < swapParam.amountIn) {
                    _refund(inputToken, swapParam.amountIn - amountInUsed, swapParam.refundTo);
                }
            } catch {
                _refund(inputToken, swapParam.amountIn, swapParam.refundTo);
                revert("Swap failed");
            }
        }

        // Emit the Swap event
        emit Swapped(msg.sender, swapParam.tokenIn, swapParam.tokenOut, swapParam.amountIn, amountOut, swapParam.exactInput);

        return amountOut;
    }

    function _handleInput(
        address inputToken,
        uint256 amountIn,
        address refundTo
    ) internal {
        if (inputToken == weth) {
            require(msg.value >= amountIn, "Insufficient ETH sent");
            IWETH(inputToken).deposit{value: amountIn}();
            if (msg.value > amountIn) {
                TransferHelper.safeTransferETH(refundTo, msg.value - amountIn);
            }
        } else {
            TransferHelper.safeTransferFrom(
                inputToken,
                msg.sender,
                address(this),
                amountIn
            );
        }
    }

    function _handleOutput(
        address outputToken,
        uint256 amountOut,
        address refundTo
    ) internal {
        if (outputToken == weth) {
            IWETH(outputToken).withdraw(amountOut);
            TransferHelper.safeTransferETH(refundTo, amountOut);
        } else {
            TransferHelper.safeTransfer(outputToken, refundTo, amountOut);
        }
    }

    function _refund(address token, uint256 amount, address to) private {
        if (token == weth) {
            IWETH(weth).withdraw(amount);
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }

        emit Refunded(to, token, amount);
    }

    receive() external payable {
        require(msg.sender == weth || msg.value == 0, "Only WETH can send ETH");
        emit ReceivedETH(msg.sender, msg.value);
    }
}
