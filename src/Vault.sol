// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "../lib/forge-std/src/Console.sol";
import "./intefaces/IRebaseToken.sol";

// The purpose of this contract is to act as a vault for the rebase token
// It allows users to deposit ether and receive rebase tokens in return
// It also allows users to redeem their rebase tokens for ether
// The contract uses the IRebaseToken interface to interact with the rebase token contract
// Why don't we use the RebaseToken itsself ?
// Because we want to keep the logic of the vault separate from the logic of the rebase token
// This allows us to change the implementation of the rebase token without affecting the vault
contract Vault {
    // Errors
    error Vault__RedeemFailed();

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    // State variables
    IRebaseToken public immutable i_rebaseToken;

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    // allows the contract to receive rewards
    receive() external payable {}

    function deposit() external payable {

        console.log("Interest rate: ", i_rebaseToken.getInterestRate());
        // Here we are assuming that the user is sending ether to the contract
        // And we mint the rebase token to the user's address, calculated based on the current interest rate and especially the msg.value, so the user can get the amount of rebase token as the ether he sent
    

        i_rebaseToken.mint(
            msg.sender,
            msg.value,
            i_rebaseToken.getInterestRate()
        );
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev redeems rebase token for the underlying asset
     * @param _amount the amount being redeemed
     *
     */
    function redeem(uint256 _amount) external {
        // Here we check if the user is trying to redeem the maximum amount of rebase token he has, if so we set the _amount to be the balance of the user
        // This is to prevent the user from having to calculate the balance of his rebase token and then redeem it
        if (_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        // Here we check if the user has enough rebase token to redeem
        i_rebaseToken.burn(msg.sender, _amount);
        // executes redeem of the underlying asset
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}
