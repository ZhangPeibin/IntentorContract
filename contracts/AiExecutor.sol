// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IIntentRequest.sol";
import "./interfaces/IFee.sol";
import "./interfaces/IAiExecutor.sol";
import "./lib/TransferHelper.sol";
import "./interfaces/IDex.sol";

contract AiExecutor is
    IAiExecutor,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IFee public override fee;

    mapping(bytes32 => address) public dexToRouter;


    modifier onlySupportedDex(string memory _dex) {
        require(
            dexToRouter[keccak256(abi.encodePacked(_dex))] != address(0),
            "DEX not supported"
        );
        _;
    }
    
    function __AIExecutor_init(
        address admin,
        address _feeAdress
    ) external initializer {
        __Ownable_init(admin);
        __ReentrancyGuard_init();
        emit AdminUpdated(address(0), admin);
        require(_feeAdress != address(0), "Invalid fee address");
        fee = IFee(_feeAdress);
        emit FeeUpdated(address(0), _feeAdress);
    }

    function execute(
        IIntentRequest.IntentReq memory intentReq
    ) external payable override nonReentrant onlySupportedDex(intentReq.platform) returns (uint256 amount) {
        require(intentReq.chainId == block.chainid, "Invalid chain ID");

        // Validate user balance and allowance
        (bool success, ValidationResult result) = validate(
            intentReq,
            msg.value
        );
        if (!success) {
            emit ExecuteValidateFailed(msg.sender, intentReq, result);
            revert(string(abi.encode(result)));
        }

        bytes32 key = keccak256(abi.encodePacked(intentReq.platform));
        address router = dexToRouter[key];
        require(router != address(0), "No router configed");
        uint256 feeAmount = _fee(intentReq.fromToken, intentReq.amount, router);
        uint256 finallyAmount = intentReq.amount - feeAmount;
        address refundTo = getRefundTo(intentReq.receiver);
        IDex.SwapParam memory swapParam = IDex.SwapParam({
            tokenIn: intentReq.fromToken,
            tokenOut: intentReq.toToken,
            amountIn: finallyAmount,
            amountOutMinimum: intentReq.amountMinout,
            refundTo: refundTo,
            exactInput: intentReq.exactInput
        });

        amount = IDex(router).swap{value: msg.value - feeAmount}(swapParam);
        emit Executed(
            msg.sender,
            intentReq.fromToken,
            intentReq.toToken,
            finallyAmount,
            amount,
            refundTo
        );
        return amount;
    }

    /**
     * @dev Validates the intent request.
     * @param intentReq The intent request to validate.
     * @return success A boolean indicating if the validation was successful.
     * @return result The validation result, which can be one of the ValidationResult enum values.
     */
    function validate(
        IIntentRequest.IntentReq memory intentReq,
        uint256 msgValue
    ) public view override returns (bool success, ValidationResult result) {
        require(intentReq.chainId == block.chainid, "Invalid chain ID");

        address fromTokenAddress = intentReq.fromToken;
        if (fromTokenAddress == address(0)) {
            if (msgValue < intentReq.amount) {
                return (false, ValidationResult.INSUFFICIENT_BALANCE);
            }
        } else {
            uint256 amount = intentReq.amount;
            IERC20Metadata fromToken = IERC20Metadata(fromTokenAddress);
            if (fromToken.balanceOf(msg.sender) < amount) {
                return (false, ValidationResult.INSUFFICIENT_BALANCE);
            }

            // Check if the allowance is sufficient
            uint256 allowance = fromToken.allowance(msg.sender, address(this));
            if (allowance < amount) {
                return (false, ValidationResult.ALLOWANCE_NOT_ENOUGH);
            }
        }

        return (true, ValidationResult.NONE);
    }

    function addDexRouter(
        string calldata _dex,
        address router
    ) external override onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(_dex));
        address oldRouter = dexToRouter[key];
        dexToRouter[key] = router;
        emit DexRouterUpdated(oldRouter, router, key);
    }

    function removeDexRouter(string calldata _dex) external override onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(_dex));
        address oldRouter = dexToRouter[key];
        require(oldRouter != address(0), "Router does not exist");
        delete dexToRouter[key];
        emit DexRouterRemoved(oldRouter, key);
    }

    function getRouterByDex(
        string calldata _dex
    ) external view override returns (address) {
        bytes32 key = keccak256(abi.encodePacked(_dex));
        return dexToRouter[key];
    }

    function getRefundTo(address receiver) internal view returns (address) {
        return receiver == address(0) ? msg.sender : receiver;
    }

    function _fee(
        address fromToken,
        uint256 amount,
        address router
    ) internal returns (uint256) {
        address feeRecipient = fee.feeRecipient();
        uint256 feeAmount = fee.collectFee(msg.sender, fromToken, amount);
        emit FeeAmount(fromToken, feeRecipient, feeAmount);
        require(feeRecipient != address(0), "Fee recipient not set");
        if (fromToken == address(0)) {
            TransferHelper.safeTransferETH(feeRecipient, feeAmount);
        } else {
            TransferHelper.safeTransferFrom(
                fromToken,
                msg.sender,
                address(this),
                amount
            );
            TransferHelper.safeTransfer(fromToken, feeRecipient, feeAmount);
            TransferHelper.safeApprove(fromToken, router, amount - feeAmount);
        }
        return feeAmount;
    }

    receive() external payable {}
}
