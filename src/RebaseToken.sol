// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract RebaseToken is ERC20 {

    error RebaseToken__InvalidInterestRate();
    

    event NewInterestRate(uint256 rate);

    uint256 private s_interestRate=5e10;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {

    }

    function setInterestRate(uint256 rate) external {
        if(rate > s_interestRate) {
            revert RebaseToken__InvalidInterestRate();
        }
        s_interestRate = rate;
        emit NewInterestRate(rate);
        
    }
}