// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IFee.sol";

contract Fee is IFee, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    uint256 immutable FEE_DENOMINATOR = 10000; 


    // Address that receives the fees
    address public override feeRecipient;

    address public override aiExecutor;

    // record of fees collected by each token
    mapping(address => uint256) public override feesCollected;

    // Fee amounts for different token types
    mapping(uint256 => uint24) public override feeAmountTickSpacing;


    mapping (address => uint256) public override userNonce;

    modifier onlyAIExecutor() {
        require(msg.sender == aiExecutor, "Caller is not the AI Executor");
        _;
    }


    function __Fee_inint(address _admin, address _feeRecipient) external initializer { 
        __Ownable_init(_admin);
        __ReentrancyGuard_init();
        require(_feeRecipient != address(0), "Invalid fee recipient address");
        emit FeeRecipientUpdated(address(0), _feeRecipient);
        feeRecipient = _feeRecipient;

        feeAmountTickSpacing[500] = 10; // Example: 0.1% fee for 500 tick spacing
        emit FeeAmountTickSpacingUpdated(500, 10);
        feeAmountTickSpacing[1000] = 20; // Example: 0.2% fee for 1000 tick spacing 
        emit FeeAmountTickSpacingUpdated(1000, 20);
        feeAmountTickSpacing[2000] = 30; // Example: 0.3% fee for 2000 tick spacing
        emit FeeAmountTickSpacingUpdated(2000, 30);
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
        uint256 _userNonce = userNonce[sender];
        uint24 feeTick = feeAmountTickSpacing[500]; // Default to 500 tick spacing
        if ( _userNonce > 500 && _userNonce <= 1000) {
            feeTick = feeAmountTickSpacing[1000]; // Use 1000 tick spacing
        } else if (_userNonce > 1000) {
            feeTick = feeAmountTickSpacing[2000]; // Use 2000 tick spacing  
        }

 
        uint256 fee = (amount * feeTick) / FEE_DENOMINATOR;
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
        uint256 fee = estimateFee(sender,fromToken, amount);
        require(fee < amount, "Fee cannot be greater than amount");
        emit FeeCollected(fromToken, fee, msg.sender);
        feesCollected[fromToken] += fee;
        return fee;
    }

    function updateUserNonce(address user) external override onlyAIExecutor {
        userNonce[user] += 1;  
        emit UserNonceUpdated(user, userNonce[user]);
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

    receive() external payable {
        // Optionally track incoming native token as fees
        if (msg.value > 0) {
            feesCollected[address(0)] = feesCollected[address(0)] + msg.value;
            emit FeeCollected(address(0), msg.value, msg.sender);
        }
    }
}
