// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "hardhat/console.sol";
import "../interfaces/IIntentRequest.sol";
import "./IIntentValidator.sol";

contract IntentValidator is Ownable , IIntentValidator {

    mapping(uint256 => address) public chainToExecutor;

    constructor(address admin) Ownable(admin) {
        console.log("IntentValidator contract deployed");
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
        console.log("Validating intent request:");
        console.log("Intent: %s", intentReq.intent);
        console.log("Platform: %s", intentReq.platform);
        console.log("From Token: %s", intentReq.fromToken);
        console.log("To Token: %s", intentReq.toToken);
        console.log("Amount: %s", intentReq.amount);
        console.log("Chain ID: %s", intentReq.chainId);

        require(chainToExecutor[intentReq.chainId] != address(0), "No validator set for this chain");

        address fromTokenAddress = intentReq.fromToken;
        if (fromTokenAddress == address(0)) {
            if (msg.sender.balance < intentReq.amount) {
                return (false, ValidationResult.INSUFFICIENT_BALANCE);
            }
        } else {
            IERC20 fromToken = IERC20(fromTokenAddress);
            IERC20Metadata fromTokenMetadata = IERC20Metadata(fromTokenAddress);

            uint8 decimals = fromTokenMetadata.decimals();
            console.log("From Token Decimals: %s", decimals);
            uint256 amountInWei = intentReq.amount * (10 ** decimals);

            console.log("Amount in Wei: %s", amountInWei);
            console.log(
                "From Token Balance: %s",
                fromToken.balanceOf(msg.sender)
            );
            if (fromToken.balanceOf(msg.sender) < amountInWei) {
                return (false, ValidationResult.INSUFFICIENT_BALANCE);
            }
            console.log("Checking allowance for From Token",fromTokenAddress);
            console.log('from',msg.sender, "to", chainToExecutor[intentReq.chainId]);
            // Check if the allowance is sufficient
            uint256 allowance = fromToken.allowance(msg.sender, chainToExecutor[intentReq.chainId]);
            console.log("From Token Allowance: %s", allowance);
            if (allowance < amountInWei) {
                return (false, ValidationResult.ALLOWANCE_NOT_ENOUGH);
            }
        }

        return (true, ValidationResult.NONE);
    }

    function setChainWithExecutor(
        uint256 chainId,
        address validatorAddress
    ) external onlyOwner {
        _setChainWithExecutor(chainId, validatorAddress);
    }

    function getExecutor(uint256 chainId) external view returns (address) {
        address validatorAddress = chainToExecutor[chainId];
        require(
            validatorAddress != address(0),
            "No validator set for this chain"
        );
        return validatorAddress;
    }

    function setChainWithExecutor(
        uint256[] memory chainIds,
        address[] memory validatorAddresses
    ) external onlyOwner {
        require(
            chainIds.length == validatorAddresses.length,
            "Chain IDs and validator addresses length mismatch"
        );
        for (uint256 i = 0; i < chainIds.length; i++) {
            _setChainWithExecutor(chainIds[i], validatorAddresses[i]);
        }
    }

    function _setChainWithExecutor(
        uint256 chainId,
        address validatorAddress
    ) internal onlyOwner {
        require(
            validatorAddress != address(0),
            "Validator address cannot be zero"
        );
        require(chainId > 0, "Chain ID must be greater than zero");
        chainToExecutor[chainId] = validatorAddress;
        console.log(
            "Validator set for chain ID %s: %s",
            chainId,
            validatorAddress
        );
    }
}
