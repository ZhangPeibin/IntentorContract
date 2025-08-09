// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IFee.sol";

contract Fee is IFee, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    uint256 public constant FEE_DENOMINATOR = 10000;

    // Address that receives the fees
    address public override feeRecipient;

    address public override aiExecutor;

    // record of fees collected by each token
    mapping(address => uint256) public override feesCollected;

    // Fee amounts for different token types
    mapping(uint256 => uint24) public override feeAmountTickSpacing;

    mapping(address => uint256) public override userNonce;


    uint256 public nativeTokenFee ; // Example: 0.001 ETH fee for native token


    modifier onlyAIExecutor() {
        require(msg.sender == aiExecutor, "Caller is not the AI Executor");
        _;
    }

    function __Fee_init(
        address _admin,
        address _feeRecipient
    ) external initializer {
        __Ownable_init(_admin);
        __ReentrancyGuard_init();
        require(_feeRecipient != address(0), "Invalid fee recipient address");
        emit FeeRecipientUpdated(address(0), _feeRecipient);
        feeRecipient = _feeRecipient;
        nativeTokenFee = 0.00001 ether; // Default ether fee
        emit EtherFeeUpdated(0, nativeTokenFee);
        _setDefaultFeeConfig();
    }

    function updateFeeConfig(uint256 spacing, uint24 tick) external onlyOwner {
        _updateFeeTickSpacing(spacing, tick);
    }

    /**
     * @dev Calculate the fee based on the token type and amount.
     * @param fromToken The address of the token being used for the transaction.
     * @param amount The amount of tokens being transferred.
     * @return The calculated fee in the smallest unit of the token.
     */
    function estimateFee(
        address sender,
        address fromToken,
        uint256 amount
    ) public view override returns (uint256) {
        require(amount > 0, "Amount must be greater than zero");
        if (fromToken == address(0)) { 
            // If the token is native (e.g., ETH), use a fixed fee
            return nativeTokenFee; // Example: 0.001 ETH fee for native token
        }

        uint256 nonce = userNonce[sender];
        uint24 tick = feeAmountTickSpacing[500]; // Default to 500 tick spacing
        if (nonce > 1000) {
            tick = feeAmountTickSpacing[2000];
        } else if (nonce > 500) {
            tick = feeAmountTickSpacing[1000];
        } 
        uint256 fee = (amount * tick) / FEE_DENOMINATOR;
        return fee;
    }

    /**
     * @dev Collect the fee for a transaction.
     * @param fromToken The address of the token being used for the transaction.
     * @param amount The amount of tokens being transferred.
     * @return The collected fee in the smallest unit of the token.
     */
    function collectFee(
        address sender,
        address fromToken,
        uint256 amount
    ) public override nonReentrant onlyAIExecutor returns (uint256) {
        require(amount > 0, "Amount must be greater than zero");
        uint256 fee = estimateFee(sender, fromToken, amount);
        require(fee < amount, "Fee cannot exceed amount");
        emit FeeCollected(fromToken, fee, msg.sender);
        feesCollected[fromToken] += fee;
        return fee;
    }

    function updateUserNonce(address user) external override onlyAIExecutor {
        unchecked {
            userNonce[user] += 1;
        }
        emit UserNonceUpdated(user, userNonce[user]);
    }


    function setNativeTokenFee(uint256 _nativeTokenFee) external override onlyOwner {
        uint256 previousFee = nativeTokenFee;
        nativeTokenFee = _nativeTokenFee;
        emit EtherFeeUpdated(previousFee, nativeTokenFee);
    }

    function setFeeRecipient(address _feeRecipient) external override onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient address");
        address previousRecipient = feeRecipient;
        emit FeeRecipientUpdated(previousRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Set the AI executor address.
     * @param _aiExecutor The address of the AI executor.
     */
    function setAIExecutor(address _aiExecutor) external override onlyOwner {
        require(_aiExecutor != address(0), "Invalid AI Executor address");
        address previousExecutor = aiExecutor;
        emit AIExecutorUpdated(previousExecutor, _aiExecutor);
        aiExecutor = _aiExecutor;
    }

    function _setDefaultFeeConfig() internal {
        _updateFeeTickSpacing(500, 10); // 0.1%
        _updateFeeTickSpacing(1000, 20); // 0.2%
        _updateFeeTickSpacing(2000, 30); // 0.3%
    }

    function _updateFeeTickSpacing(uint256 spacing, uint24 tick) internal {
        feeAmountTickSpacing[spacing] = tick;
        emit FeeAmountTickSpacingUpdated(spacing, tick);
    }

    receive() external payable {
        // Optionally track incoming native token as fees
        if (msg.value > 0) {
            feesCollected[address(0)] = feesCollected[address(0)] + msg.value;
            emit FeeCollected(address(0), msg.value, msg.sender);
        }
    }
}
