// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.28;

import "../lib/Enum.sol";

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {

    struct QuoterParams {
        uint256 amount;
        address tokenIn;
        address tokenOut;
        Enum.DEX dex; 
    }

    event QuoterUpdated(address indexed quoter, Enum.DEX indexed dex);

    function quoteExactInput(
        QuoterParams calldata params
    ) external returns (uint256 amountOut,uint24 poolFee);

    function quoteExactOutput(
        QuoterParams calldata params
    ) external returns (uint256 amountIn, uint24 poolFee);

    function setDexInfo(Enum.DEX dex, address quoter, address factory) external;

     function poolFee( address factory,
        address token0,
        address token1
    ) external view returns (uint24) ;
}
