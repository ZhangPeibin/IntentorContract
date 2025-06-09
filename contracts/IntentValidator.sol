// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "hardhat/console.sol";
import "./interfaces/IIntentRequest.sol";
import "./interfaces/IIntentValidator.sol";

contract IntentValidator is OwnableUpgradeable , IIntentValidator {


    address public override aiExecutor;

    constructor()  {
        _disableInitializers();
    }


    function __IntentValidator_init(address admin) external initializer{
        __Ownable_init(admin);
        emit AdminUpdated(address(0), msg.sender);
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

            require(aiExecutor != address(0), "AI Executor not set");

            // Check if the allowance is sufficient
            uint256 allowance = fromToken.allowance(msg.sender, aiExecutor);
            console.log("From Token Allowance: %s", allowance);
            if (allowance < amountInWei) {
                return (false, ValidationResult.ALLOWANCE_NOT_ENOUGH);
            }
        }

        return (true, ValidationResult.NONE);
    }




    function setAiExecutor(address _aiExecutor) external onlyOwner {
        require(_aiExecutor != address(0), "Invalid AI Executor address");
        address previousExecutor = aiExecutor;
        aiExecutor = _aiExecutor;
        emit AiExecutorUpdated(previousExecutor, _aiExecutor);
    }

    function getAiExecutor() external view returns (address) {
        return aiExecutor;
    }
}
