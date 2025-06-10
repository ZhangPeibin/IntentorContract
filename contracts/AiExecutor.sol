// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IIntentRequest.sol";
import "./interfaces/IIntentValidator.sol";
import "./interfaces/IFee.sol";
import "./interfaces/IAiExecutor.sol";
import "./lib/TransferHelper.sol"; 
import "./interfaces/IDex.sol";

contract AiExecutor is OwnableUpgradeable ,ReentrancyGuardUpgradeable ,IAiExecutor  {


    IIntentValidator public override aiValidator;
    IFee public override fee;
    IDex public dex;

    mapping(uint256 => address) public chainToRouter;

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
        emit AiValidatorUpdated(address(0), _aiValidator);
        fee = IFee(_fee);
        emit FeeUpdated(address(0), _fee);
    }

    function execute(
        IIntentRequest.IntentReq memory intentReq,
        address receiver
    ) external payable nonReentrant returns (bytes memory) {
        
        require(intentReq.chainId == block.chainid, "Invalid chain ID");

        // Validate user balance and allowance
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
        uint256 feeAmount = fee.collectFee(msg.sender,intentReq.fromToken, intentReq.amount);
        address feeRecipient = fee.feeRecipient();
        require(feeRecipient != address(0), "Fee recipient not set");
        if(intentReq.fromToken == address(0)) {
            require(msg.value >= feeAmount, "Insufficient fee amount sent");
            TransferHelper.safeTransferETH(feeRecipient, feeAmount);
        } else {
            TransferHelper.safeTransferFrom(
                intentReq.fromToken,
                msg.sender,
                address(this),
                intentReq.amount
            );
            TransferHelper.safeTransfer(intentReq.fromToken, feeRecipient, feeAmount);
        }   
        // Update user nonce
        // Execute the intent
        return "";
    }

    receive() external payable {

    }

}
