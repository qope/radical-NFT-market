// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract  Coin is ERC20 {
    constructor() ERC20("Coin", "coin") {
        _mint(msg.sender, 100*(10**decimals()));
    }
}