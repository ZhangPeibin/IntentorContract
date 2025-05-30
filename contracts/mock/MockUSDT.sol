// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDT is ERC20 {
    string public _name = "Mock USDT";
    string public _symbol = "USDT";
    uint8 public _decimals = 18;
  
    constructor(uint256 initialSupply) ERC20(_name, _symbol) {
        _mint(msg.sender, initialSupply * (10 ** uint256(_decimals)));
    }

    function mint() external {
        _mint(msg.sender, 1000 * (10 ** uint256(_decimals)));
    }
}