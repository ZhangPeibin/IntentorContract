// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IFee.sol";

contract Fee is IFee, Ownable, ReentrancyGuard {
    // Address that receives the fees
    address public feeRecipient;

    address public aiExecutor;

    // record of fees collected by each token
    mapping(address => uint256) public feesCollected;

    // Fee structure , 10 = 0.1% for base token, 20 = 0.2% for ERC20 tokens
    // 100 = 1% max fee
    uint256 BASE_TOKEN_FEE = 10;
    uint256 ERC20_TOKEN_FEE = 20;
    uint256 MAX_FEE = 100; // 1% max fee
    uint256 constant FEE_DENOMINATOR = 10000; // 100% = 10000

    modifier onlyAIExecutor() {
        require(msg.sender == aiExecutor, "Caller is not the AI Executor");
        _;
    }

    constructor(address _admin, address _feeRecipien) Ownable(_admin) {
        require(_feeRecipien != address(0), "Invalid fee recipient address");
        emit FeeRecipientUpdated(address(0), _feeRecipien);
        feeRecipient = _feeRecipien;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient address");
        address previousRecipient = feeRecipient;
        emit FeeRecipientUpdated(previousRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Get the current fee recipient address.
     * @return The address of the fee recipient.
     */
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    /**
     * @dev Set the AI executor address.
     * @param _aiExecutor The address of the AI executor.
     */
    function setAIExecutor(address _aiExecutor) external onlyOwner {
        require(_aiExecutor != address(0), "Invalid AI Executor address");
        address previousExecutor = aiExecutor;
        emit AIExecutorUpdated(previousExecutor, _aiExecutor);
        aiExecutor = _aiExecutor;
    }

    /**
     * @dev Get the current AI executor address.
     * @return The address of the AI executor.
     */
    function getAIExecutor() external view returns (address) {
        return aiExecutor;
    }

    /**
     * @dev Calculate the fee based on the token type and amount.
     * @param fromToken The address of the token being used for the transaction.
     * @param amount The amount of tokens being transferred.
     * @return The calculated fee in the smallest unit of the token.
     */
    function getFee(
        address fromToken,
        uint256 amount
    ) public view returns (uint256) {
        require(amount > 0, "Amount must be greater than zero");
        uint256 baseFee = fromToken == address(0)
            ? BASE_TOKEN_FEE
            : ERC20_TOKEN_FEE;
        uint256 fee = (amount * baseFee) / FEE_DENOMINATOR;
        return fee > MAX_FEE ? MAX_FEE : fee;
    }

    /**
     * @dev Collect the fee for a transaction.
     * @param fromToken The address of the token being used for the transaction.
     * @param amount The amount of tokens being transferred.
     * @return The collected fee in the smallest unit of the token.
     */
    function collectFee(
        address fromToken,
        uint256 amount
    ) public nonReentrant onlyAIExecutor returns (uint256) {
        require(amount > 0, "Amount must be greater than zero");
        uint256 fee = getFee(fromToken, amount);
        require(fee < amount, "Fee cannot be greater than amount");
        emit FeeCollected(fromToken, fee, msg.sender);
        feesCollected[fromToken] += fee;
        return fee;
    }

    receive() external payable {
        // Optionally track incoming native token as fees
        if (msg.value > 0) {
            feesCollected[address(0)] = feesCollected[address(0)] + msg.value;
            emit FeeCollected(address(0), msg.value, msg.sender);
        }
    }
}
