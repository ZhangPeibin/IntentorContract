// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library Errors {

    error UnSupportedDex();

    error EmptyQuoter();
    error EmptyFactory();

    error EmptyToken0();
    error EmptyToken1();

    error PoolNotFound();

    error InvalidChainId();

    error InsufficientETH();

    error InsufficientToken();

    error InsufficientAllowance();

    error SameToken();

    error ZeroAmount();

}