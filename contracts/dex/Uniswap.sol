// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IDex.sol";
import "../lib/TransferHelper.sol"; 
import "../interfaces/ISwapRouter.sol";

contract Uniswap is IDex {


    address public immutable override router;
    address public immutable override weth;

    constructor(address _router, address _weth) {
        require(_router != address(0), "Invalid router address");
        require(_weth != address(0), "Invalid WETH address");
        router = _router;
        weth = _weth;
    }


    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bool exactInput
    ) external payable override returns (uint256 amountOut) {
        require(tokenIn != address(0) || tokenOut != address(0), "Both tokenIn and tokenOut cannot be zero address"); 
        require(tokenIn != tokenOut,"TokenIn and TokenOut must be different");
        require(amountIn > 0, "Amount must be greater than zero");

        //swap exactInput tokenIn for unkown tokenOut
        if (exactInput) {
             TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
             TransferHelper.safeApprove(tokenIn, router, amountIn),
            ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: DAI,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
        }

        // Emit the Swap event
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountIn);

        return amountIn;
    }
}
