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
    IDex public dex;

    mapping(uint256 => address) public chainToRouter;

    constructor() {
        _disableInitializers();
    }

    function __AIExecutor_init(
        address admin,
        address _fee
    ) external initializer {
        __Ownable_init(admin);
        emit AdminUpdated(address(0), admin);
        require(_fee != address(0), "Invalid fee address");
        fee = IFee(_fee);
        emit FeeUpdated(address(0), _fee);
    }

    function execute(
        IIntentRequest.IntentReq memory intentReq,
        address receiver
    ) external payable nonReentrant returns (bytes memory) {
        require(intentReq.chainId == block.chainid, "Invalid chain ID");

        // Validate user balance and allowance
        (bool success, ValidationResult result) = validate(
            intentReq
        );
        if (!success) {
            emit ExecuteValidateFailed(msg.sender, intentReq, result);
            revert(string(abi.encode(result)));
        }

        //collect fee
        uint256 feeAmount = fee.collectFee(
            msg.sender,
            intentReq.fromToken,
            intentReq.amount
        );
        address feeRecipient = fee.feeRecipient();
        emit FeeAmountUpdated(intentReq.fromToken, feeRecipient, feeAmount);
        require(feeRecipient != address(0), "Fee recipient not set");
        if (intentReq.fromToken == address(0)) {
            require(msg.value >= feeAmount, "Insufficient fee amount sent");
            TransferHelper.safeTransferETH(feeRecipient, feeAmount);
        } else {
            TransferHelper.safeTransferFrom(
                intentReq.fromToken,
                msg.sender,
                address(this),
                intentReq.amount
            );
            TransferHelper.safeTransfer(
                intentReq.fromToken,
                feeRecipient,
                feeAmount
            );
        }
        // Update user nonce
        // Execute the intent
        return "";
    }

    /**
     * @dev Validates the intent request.
     * @param intentReq The intent request to validate.
     * @return success A boolean indicating if the validation was successful.
     * @return result The validation result, which can be one of the ValidationResult enum values.
     */
    function validate(
        IIntentRequest.IntentReq memory intentReq
    ) public view override returns (bool success, ValidationResult result) {
        require(intentReq.chainId == block.chainid, "Invalid chain ID");

        address fromTokenAddress = intentReq.fromToken;
        if (fromTokenAddress == address(0)) {
            if (msg.sender.balance < intentReq.amount) {
                return (false, ValidationResult.INSUFFICIENT_BALANCE);
            }
        } else {
            IERC20Metadata fromToken = IERC20Metadata(fromTokenAddress);

            uint8 decimals = fromToken.decimals();
            uint256 amountInWei = intentReq.amount * (10 ** decimals);

            if (fromToken.balanceOf(msg.sender) < amountInWei) {
                return (false, ValidationResult.INSUFFICIENT_BALANCE);
            }

            // Check if the allowance is sufficient
            uint256 allowance = fromToken.allowance(msg.sender, address(this));
            if (allowance < amountInWei) {
                return (false, ValidationResult.ALLOWANCE_NOT_ENOUGH);
            }
        }

        return (true, ValidationResult.NONE);
    }

    receive() external payable {}
}
