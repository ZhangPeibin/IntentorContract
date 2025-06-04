// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


interface IFee {
    event FeeRecipientUpdated(address indexed previousRecipient, address indexed newRecipient);
    event AIExecutorUpdated(address indexed previousExecutor, address indexed newExecutor);
    event FeeCollected(address indexed fromToken, uint256 amount, address indexed collector);

    function collectFee(address fromToken, uint256 amount) external returns (uint256 feeAmount);

    function setFeeRecipient(address _feeRecipient) external;
    function getFeeRecipient() external view returns (address);
    function setAIExecutor(address _aiExecutor) external;
    function getAIExecutor() external view returns (address);
}