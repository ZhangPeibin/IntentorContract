// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDex.sol";

abstract contract Basedex is IDex, Ownable {
    uint24 public constant poolFee = 3000;

    address public immutable router;
    address public immutable weth;

    mapping(address => bool) public isSwapWhitelist;

    constructor(address admin, address _router, address _weth) Ownable(admin) {
        require(_router != address(0), "Invalid router address");
        require(_weth != address(0), "Invalid WETH address");
        router = _router;
        emit RouterUpdated(address(0), _router);
        weth = _weth;
        emit WethUpdated(address(0), _weth);
    }

    modifier onlyWhitelisted() {
        require(isSwapWhitelist[msg.sender], "Not whitelisted for swaps");
        _;
    }

    function setSwapWhitelist(
        address[] calldata accounts,
        bool status
    ) external onlyOwner override {
        for (uint256 i = 0; i < accounts.length; i++) {
            isSwapWhitelist[accounts[i]] = status;
            emit SwapWhitelistUpdated(accounts[i], status);
        }
    }

    function setSwapWhitelistSingle(
        address account,
        bool status
    ) external override onlyOwner {
        isSwapWhitelist[account] = status;
        emit SwapWhitelistUpdated(account, status);
    }

    function isWhitelisted(address account) external view override returns (bool) {
        return isSwapWhitelist[account];
    }

    function swap(
        SwapParam memory swapParam
    ) external payable virtual returns (uint256 amountOut);
}
