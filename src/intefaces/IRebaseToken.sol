// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// This is the interface for the RebaseToken contract
// It defines the functions that the RebaseToken contract must implement
// and allows other contracts to interact with it without needing to know the details of its implementation
interface IRebaseToken {
    function mint(address _to, uint256 _amount, uint256 _rate) external;

    function burn(address _from, uint256 _amount) external;

    function balanceOf(address _account) external view returns (uint256);

    function getUserInterestRate(
        address _account
    ) external view returns (uint256);

    function getInterestRate() external view returns (uint256);

    function grantMintAndBurnRole(address _account) external;
}
