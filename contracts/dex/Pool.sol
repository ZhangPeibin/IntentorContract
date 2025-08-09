// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IUniswapV3Factory.sol";

library Pool {
    uint256 constant FEE_LENGTH = 4;
    uint24 constant FEE_LOW = 100; // 0.01%
    uint24 constant FEE_MEDIUM = 500; // 0.05%
    uint24 constant FEE_DEFAULT = 3000; // 0.3%
    uint24 constant FEE_HIGH = 10000; // 1%

    function getPool(
        address factory,
        address tokenA,
        address tokenB
    ) external view returns (address pool, uint24 fee) {
        uint24[FEE_LENGTH] memory fees = [
            FEE_DEFAULT,
            FEE_MEDIUM,
            FEE_HIGH,
            FEE_LOW
        ];
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        for (uint256 index = 0; index < FEE_LENGTH; index++) {
            pool = IUniswapV3Factory(factory).getPool(
                token0,
                token1,
                fees[index]
            );
            if (pool != address(0)) {
                return (pool, fees[index]);
            }
        }
        return (address(0), 0);
    }
}
