// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.28;

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IBaseQuoter {
    struct QuoterParams {
        string dex;
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
    }

    error UnSupportDex();
    event QuoterUpdated(address indexed quoter, string dex);

    function quoterFromDex(
        string calldata dex
    ) external view returns (address quoter);

    function updateQuoter(string calldata dex, address quoter) external;

    function quoteExactInput(
        QuoterParams memory params
    ) external returns (uint256 amountOut);

    function quoteExactOutput(
        QuoterParams memory params
    ) external returns (uint256 amountIn);
}
