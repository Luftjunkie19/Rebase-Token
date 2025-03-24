// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RebaseToken is Ownable, AccessControl, ERC20 {
    error RebaseToken__InvalidInterestRate();

    // The last time a user updated their balance to mint accrued intrest
    mapping(address => uint256) private s_lastUpdatedTimestamp;

    // Key-value mapping of user to interest rate
    mapping(address => uint256) private addressToInterest;

    event NewInterestRate(uint256 rate);

    // This is the global interest rate of the token - when users mint or receive tokens via transferral, this is the interest rate they will get.
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8;

    // Create a new role identifier for the minter role
    bytes32 private constant MINT_AND_BURN_ROLE =
        keccak256("MINT_AND_BURN_ROLE");

    // Used to handle fixed-point calculations
    uint256 private constant PRECISION_FACTOR = 1e18;

    constructor(
        string memory name,
        string memory symbol
    ) Ownable(msg.sender) ERC20(name, symbol) {}

    function grantMintAndBurnRole(address _account) external onlyOwner {
        bool success = _grantRole(MINT_AND_BURN_ROLE, _account);
        require(success, "grant role failed");
    }

    function setInterestRate(uint256 rate) external onlyOwner {
        if (rate >= s_interestRate) {
            revert RebaseToken__InvalidInterestRate();
        }
        s_interestRate = rate;
        emit NewInterestRate(rate);
    }

    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(to);
        addressToInterest[to] = s_interestRate;
        _mint(to, amount);
    }

    function _mintAccruedInterest(address to) internal onlyOwner {
        uint256 previousPrincipleBalance = super.balanceOf(to);

        uint256 currentBalance = balanceOf(to);

        uint256 balanceIncrease = currentBalance - previousPrincipleBalance;

        _mint(to, balanceIncrease);

        s_lastUpdatedTimestamp[to] = block.timestamp;
    }

    function balanceOf(address _user) public view override returns (uint256) {
        return
            (super.balanceOf(_user) * calculateInterest(_user)) /
            PRECISION_FACTOR;
    }

    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    function calculateInterest(
        address _user
    ) internal view returns (uint256 linearIntrest) {
        uint256 timeElapsed = block.timestamp - s_lastUpdatedTimestamp[_user];
        linearIntrest =
            PRECISION_FACTOR +
            (addressToInterest[_user] * timeElapsed);
    }

    function burn(address from, uint256 value) external {
        if (value == type(uint256).max) {
            value = super.balanceOf(from);
        }
        _mintAccruedInterest(from);
        _burn(from, value);
    }

    function getUserInterestRate(address user) external view returns (uint256) {
        return addressToInterest[user];
    }

    function transfer(
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }

        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);

        if (balanceOf(_recipient) == 0) {
            addressToInterest[_recipient] = addressToInterest[msg.sender];
        }

        return super.transfer(_recipient, _amount);
    }

    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    function transferFrom(
        address _from,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _mintAccruedInterest(_from);
        _mintAccruedInterest(_recipient);

        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }

        if (balanceOf(_recipient) == 0) {
            addressToInterest[_recipient] = addressToInterest[_from];
        }

        return super.transferFrom(_from, _recipient, _amount);
    }
}
