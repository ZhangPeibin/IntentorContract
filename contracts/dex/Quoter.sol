// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IQuoter.sol";
import "../interfaces/IUniQuoter.sol";
import "../lib/Errors.sol";
import "../lib/Enum.sol";
import "./Pool.sol";
import "../Fee.sol";

contract Quoter is IQuoter, Ownable {
    struct DexInfo {
        address quoter;
        address factory;
    }

    mapping(Enum.DEX => DexInfo) public dexInfos;
    constructor(address admin) Ownable(admin) {}

    function quoteExactInput(
        QuoterParams calldata params
    ) external override returns (uint256 amountOut, uint24 poolFee) {
        if (params.tokenIn == address(0)) revert Errors.EmptyToken0();
        if (params.tokenOut == address(0)) revert Errors.EmptyToken1();

        DexInfo memory dexInfo = dexInfos[params.dex];
        if (dexInfo.quoter == address(0)) revert Errors.EmptyQuoter();
        if (dexInfo.factory == address(0)) revert Errors.EmptyFactory();

        if ( Enum.DEX.UNI == params.dex) {
            poolFee = _poolFee(
                dexInfo.factory,
                params.tokenIn,
                params.tokenOut
            );
            try
                IUniQuoter(dexInfo.quoter).quoteExactInputSingle(
                    IUniQuoter.QuoteExactInputSingleParams({
                        tokenIn: params.tokenIn,
                        tokenOut: params.tokenOut,
                        amountIn: params.amount,
                        fee: poolFee,
                        sqrtPriceLimitX96: 0
                    })
                )
            returns (uint256 _amountOut, uint160, uint32, uint256) {
                amountOut = _amountOut;
            } catch (bytes memory data) {
                revert(string(data));
            }
        } else {
            revert Errors.UnSupportedDex();
        }
        return (amountOut, poolFee);
    }

    function quoteExactOutput(
        QuoterParams calldata params
    ) external override returns (uint256 amountIn, uint24 poolFee) {
        if (params.tokenIn == address(0)) revert Errors.EmptyToken0();
        if (params.tokenOut == address(0)) revert Errors.EmptyToken1();

        DexInfo memory dexInfo = dexInfos[params.dex];
        if (dexInfo.quoter == address(0)) revert Errors.EmptyQuoter();
        if (dexInfo.factory == address(0)) revert Errors.EmptyFactory();

        if ( Enum.DEX.UNI == params.dex) {
            poolFee = _poolFee(
                dexInfo.factory,
                params.tokenIn,
                params.tokenOut
            );
            try
                IUniQuoter(dexInfo.quoter).quoteExactOutputSingle(
                    IUniQuoter.QuoteExactOutputSingleParams({
                        tokenIn: params.tokenIn,
                        tokenOut: params.tokenOut,
                        amount: params.amount,
                        fee: poolFee,
                        sqrtPriceLimitX96: 0
                    })
                )
            returns (uint256 _amountIn, uint160, uint32, uint256) {
                amountIn = _amountIn;
            } catch (bytes memory data) {
                revert(string(data));
            }
        } else {
            revert Errors.UnSupportedDex();
        }
        return (amountIn, poolFee);
    }

    function setDexInfo(
        Enum.DEX dex,
        address quoter,
        address factory
    ) external override onlyOwner {
        if (quoter == address(0)) revert Errors.EmptyQuoter();
        if (factory == address(0)) revert Errors.EmptyFactory();
        DexInfo memory dexInfo = DexInfo({quoter: quoter, factory: factory});
        dexInfo.quoter = quoter;
        dexInfos[dex] = dexInfo;
        emit QuoterUpdated(quoter, dex);
    }

    function poolFee(
        address factory,
        address token0,
        address token1
    ) external view returns (uint24) {
        return _poolFee(factory, token0, token1);
    }

    function _poolFee(
        address factory,
        address token0,
        address token1
    ) internal view returns (uint24) {
        (address pool, uint24 fee) = Pool.getPool(factory, token0, token1);
        if (pool == address(0)) revert Errors.PoolNotFound();
        return fee;
    }
}
