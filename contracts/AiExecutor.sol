// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFee.sol";
import "./interfaces/IAiExecutor.sol";
import "./lib/TransferHelper.sol";
import "./interfaces/IDex.sol";
import "./util/Errors.sol";

contract AiExecutor is
    IAiExecutor,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IFee public fee;

    mapping(DEX => address) public dexToRouter;

    function __AIExecutor_init(
        address admin,
        address feeAddress
    ) external initializer {
        __Ownable_init(admin);
        __ReentrancyGuard_init();
        emit AdminUpdated(address(0), admin);
        require(feeAddress != address(0), "Invalid fee address");
        fee = IFee(feeAddress);
        emit FeeUpdated(address(0), feeAddress);
    }

    function execute(
        IntentReq calldata req
    ) external payable override nonReentrant returns (uint256) {
        address router = dexToRouter[req.dex];
        if (router == address(0)) revert Errors.UnSupportedDex();
        address token0 = req.fromToken;
        address token1 = req.toToken;
        if (token0 == token1) revert Errors.SameToken();
        uint256 amount = req.amount;
        if (amount == 0) revert Errors.ZeroAmount();

        (uint256 feeAmount, uint256 restAmount, address feeRecipient) = _calculateFee(
            token0,
            amount
        );

        uint256 value = 0;
        if (token0 == address(0)) {
            if (msg.value < amount) revert Errors.InsufficientETH();
            TransferHelper.safeTransferETH(feeRecipient, feeAmount);
            value = msg.value - feeAmount;
        } else {
            _transferERC20Tokens(token0, amount, feeAmount, feeRecipient);
        }

        IDex.SwapParam memory swapParam = IDex.SwapParam({
            tokenIn: token0,
            tokenOut: token1,
            amountIn: restAmount,
            amountOutMinimum: req.amountMinout,
            refundTo: msg.sender,
            poolFee: req.poolFee,
            exactInput: req.exactInput
        });

        fee.updateUserNonce(msg.sender);
        amount = IDex(router).swap{value: value}(swapParam);
        emit Executed(msg.sender, token0, token1, restAmount, amount, msg.sender);
        return amount;
    }

    function _transferERC20Tokens(
        address token0,
        uint256 amount,
        uint256 feeAmount,
        address feeRecipient
    ) internal {
        IERC20 fromToken = IERC20(token0);

        //check user's balance
        if (fromToken.balanceOf(msg.sender) < amount) {
            revert Errors.InsufficientToken();
        }

        //check user's allowance
        uint256 allowance = fromToken.allowance(msg.sender, address(this));
        if (allowance < amount) {
            revert Errors.InsufficientAllowance();
        }

        TransferHelper.safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            amount
        );
        TransferHelper.safeTransfer(token0, feeRecipient, feeAmount);
    }

    function addDexRouter(DEX dex, address router) external override onlyOwner {
        address oldRouter = dexToRouter[dex];
        dexToRouter[dex] = router;
        emit DexRouterUpdated(oldRouter, router, dex);
    }

    function removeDexRouter(DEX dex) external override onlyOwner {
        address oldRouter = dexToRouter[dex];
        delete dexToRouter[dex];
        emit DexRouterRemoved(oldRouter, dex);
    }

    function _calculateFee(
        address fromToken,
        uint256 amount
    )
        internal
        returns (uint256 feeAmount, uint256 restAmount, address feeRecipient)
    {
        feeRecipient = fee.feeRecipient();
        feeAmount = fee.collectFee(msg.sender, fromToken, amount);
        restAmount = amount - feeAmount;
        emit FeeAmount(fromToken, feeRecipient, feeAmount);
    }

    receive() external payable {}
}
