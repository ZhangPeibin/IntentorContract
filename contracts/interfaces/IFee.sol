// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


interface IFee {
    event EtherFeeUpdated(uint256 indexed previousFee, uint256 indexed newFee);
    event FeeRecipientUpdated(address indexed previousRecipient, address indexed newRecipient);
    event AIExecutorUpdated(address indexed previousExecutor, address indexed newExecutor);
    event FeeCollected(address indexed fromToken, uint256 amount, address indexed collector);
    event FeeAmountTickSpacingUpdated(uint256 indexed tickSpacing, uint24 fee);
    event UserNonceUpdated(address indexed user, uint256 newNonce);

    function etherFee() external view returns (uint256);
    function setEtherFee(uint256 _etherFee) external;

    function feesCollected(address token) external view returns (uint256);
    function feeAmountTickSpacing(uint256 tickSpacing) external view returns (uint24 );
    function userNonce(address user) external view returns (uint256);

    function aiExecutor() external view returns (address);
    function feeRecipient() external view returns (address);
    function setFeeRecipient(address _feeRecipient) external;

    function estimateFee(address sender, address fromToken, uint256 amount) external view returns (uint256);
    function collectFee(address sender, address fromToken, uint256 amount) external returns (uint256 feeAmount);
    function updateUserNonce(address user) external;
    function setAIExecutor(address _aiExecutor) external;
}