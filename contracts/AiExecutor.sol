// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IIntentRequest.sol";
import "./validator/IIntentValidator.sol";
import "./fee/IFee.sol";
import {SafeTransferLib} from "./lib/SafeTransferLib.sol"; // Ensure SafeTransferLib is imported correctly
// Ensure IntentReq is imported or defined
// If IIntentRequest.sol defines IntentReq, this import is sufficient.
// Otherwise, define the struct here or correct the import.

contract AiExecutor is OwnableUpgradeable {

    using SafeTransferLib for address;
    using SafeTransferLib for IERC20;

    IIntentValidator public aiValidator;
    IFee public fee;

    mapping(uint256 => address) public chainToRouter;

    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    event ExecuteValidateFailed(
        address indexed executor,
        IIntentRequest.IntentReq intentReq,
        IIntentValidator.ValidationResult result
    );
    constructor() {
        _disableInitializers();
    }

    function __AIExecutor_init(
        address admin,
        address _fee,
        address _aiValidator
    ) external initializer {
        __Ownable_init(admin);
        emit AdminUpdated(address(0), admin);
        require(_fee != address(0), "Invalid fee address");
        require(_aiValidator != address(0), "Invalid AI validator address");
        aiValidator = IIntentValidator(_aiValidator);
        fee = IFee(_fee);
    }

    function execute(
        IIntentRequest.IntentReq memory intentReq,
        address receiver
    ) external payable returns (bytes memory) {
        //
        require(intentReq.chainId == block.chainid, "Invalid chain ID");

        (bool success,IIntentValidator.ValidationResult result) = aiValidator.validate(intentReq);
        if(!success) {
            emit ExecuteValidateFailed(
                msg.sender,
                intentReq,
                result
            );
            revert(string(abi.encode(result)));
        }   

        //collect fee
        uint256 feeAmount = fee.collectFee(intentReq.fromToken, intentReq.amount);
        address feeRecipient = fee.getFeeRecipient();
        require(feeRecipient != address(0), "Fee recipient not set");
        if(intentReq.fromToken == address(0)) {
            require(msg.value >= feeAmount, "Insufficient fee amount sent");
            feeRecipient.safeTransferETH(feeAmount);
        } else {
            IERC20 fromToken = IERC20(intentReq.fromToken);
            fromToken.safeTransferFrom(msg.sender, address(this), intentReq.amount);
            fromToken.safeTransfer(feeRecipient, feeAmount);
        }   

        // Execute the intent
        return "";
    }

    receive() external payable {

    }

}
