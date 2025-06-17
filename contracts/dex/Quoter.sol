// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IBaseQuoter.sol";
import "../interfaces/IUniQuoter.sol";

contract Quoter is IBaseQuoter, Ownable {
    bytes32 private constant UNI = keccak256(abi.encodePacked("uni"));

    mapping(bytes => address) public dexToQuoter;

    constructor(address admin) Ownable(admin) {}
    

    function quoteExactInput(
        QuoterParams memory params
    ) external override returns (uint256 amountOut) {
        require(params.tokenIn != address(0), "TokenIn cannot be zero");
        require(params.tokenOut != address(0), "TokenOut cannot be zero");
        bytes memory key = abi.encodePacked(params.dex);
        address quoter = dexToQuoter[key];
        require(quoter != address(0), "Quoter not found for dex");

        if (UNI == keccak256(key)) {
            try
                IUniQuoter(quoter).quoteExactInputSingle(
                    IUniQuoter.QuoteExactInputSingleParams({
                        tokenIn: params.tokenIn,
                        tokenOut: params.tokenOut,
                        amountIn: params.amount,
                        fee: params.fee,
                        sqrtPriceLimitX96: 0
                    })
                )
            returns (uint256 _amountOut, uint160, uint32, uint256) {
                amountOut = _amountOut;
            } catch {
                revert("Quote failed");
            }
        }else {
            revert UnSupportDex();
        }
        return amountOut;
    }

    function quoteExactOutput(
        QuoterParams memory params
    ) external override returns (uint256 amountIn) {
        require(params.tokenIn != address(0), "TokenIn cannot be zero");
        require(params.tokenOut != address(0), "TokenOut cannot be zero");

        bytes memory key = abi.encodePacked(params.dex);
        address quoter = dexToQuoter[key];
        require(quoter != address(0), "Quoter not found for dex");

        if (UNI == keccak256(key)) {
            try
                IUniQuoter(quoter).quoteExactOutputSingle(
                    IUniQuoter.QuoteExactOutputSingleParams({
                        tokenIn: params.tokenIn,
                        tokenOut: params.tokenOut,
                        amount: params.amount,
                        fee: params.fee,
                        sqrtPriceLimitX96: 0
                    })
                )
            returns (uint256 _amountIn, uint160, uint32, uint256) {
                amountIn = _amountIn;
            } catch {
                revert("Quote failed");
            }
        }else {
            revert UnSupportDex();
        }
        return amountIn;
    }

    function updateQuoter(
        string calldata dex,
        address quoter
    ) external override onlyOwner {
        require(bytes(dex).length != 0, "Dex  cannot be zero");
        require(quoter != address(0), "Quoter address cannot be zero");
        bytes memory key = abi.encodePacked(dex);
        dexToQuoter[key] = quoter;
        emit QuoterUpdated(quoter, dex);
    }

    function quoterFromDex(
        string calldata dex
    ) external view override returns (address quoter) {
        bytes memory key = abi.encodePacked(dex);
        quoter = dexToQuoter[key];
    }
}
