// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "../lib/forge-std/src/console.sol";
// The base of the smart contract to implement the standards functionalities like minting, burning, transfering the tokens.
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
// It is imported in order to define who is elligible to call the mint, transfer or burn function.
import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
// Ownable is to assign the contract to certain address so it would belong to THE PERSON, who deployed it.
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RebaseToken is ERC20, Ownable, AccessControl {
    error RebaseToken__InvalidInterestRate();
    error RebaseToken__InvalidMintAndBurnRole();

    event NewInterestRate(uint256 rate);

// The last time a user updated their balance to mint accrued intrest
    mapping(address => uint256) private s_lastUpdatedTimestamp;
    // Key-value mapping of user to interest rate
    mapping(address => uint256) private addressToInterest;

    // Used to handle fixed-point calculations
    uint256 private constant PRECISION_FACTOR = 1e18;

    // This is the global interest rate of the token - when users mint or receive tokens via transferral, this is the interest rate they will get.
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8; // 0.000005%

    // Create a new role identifier for the minter role
    bytes32 private constant MINT_AND_BURN_ROLE =
        keccak256("MINT_AND_BURN_ROLE");


    constructor(
    ) Ownable(msg.sender) ERC20("RebaseToken", "RBT") {}

    // This function is created to grant the role to an address, that will be used to mint and burn the token.
    // This function is only callable by the owner of the contract.
    function grantMintAndBurnRole(address _account) external onlyOwner {
     _grantRole(MINT_AND_BURN_ROLE, _account);
  
    }

 // This function provides the address of the contract owner.
function getContractsOwnership() external view returns (address) {
        return owner();
    }


    // The function is created to set the interest rate of the token.
    // The function is only callable by the owner of the contract.

    // IMPORTANT: The interest rate should be less than the global interest rate. Meaning it should only decrease.
    function setInterestRate(uint256 rate) external onlyOwner {
        // Here the condition is checking, whether the provided value as the parameter of rate is less or equal current interest rate.
        // If this is the case the code will be reverted.
        if (rate >= s_interestRate) {
            revert RebaseToken__InvalidInterestRate();
        }
        // Otherwise the interest rate will be updated, and the event will be emited 😎

        s_interestRate = rate;

        emit NewInterestRate(rate);
    }

    // Returns the PRINCIPAL balance of certain user's address. The principal balance is the
    // most recently updated and stored balance, which does not consider the perpetually accruing interest that has not yet been minted.

    // What it means is that the principleBalanceOf function is simply returning the balance of the user, without considering the interest rate.
    // So given a user with a balance of 100 tokens, the principleBalanceOf function will return 100 tokens, regardless of the current interest rate.

    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    // In this case however the balanceOf function is returning the balance of the user, but it is also considering the interest rate.
    // So given a user with a balance of 100 tokens, and an interest rate of 5%, the balanceOf function will return 105 tokens.

    function balanceOf(address _user) public view override returns (uint256) {
       
       uint256 currentPrincipleBalance = super.balanceOf(_user);

       if(currentPrincipleBalance == 0) {
            return 0;
        }
       
        return
            (currentPrincipleBalance * calculateInterest(_user)) /
            PRECISION_FACTOR;
    }

    // This function is responsible for both assigning the freshly minted tokens to the user's address, that has been passed.
    // And also to increase the amount of the tokens available.
    // It is only possible to be called by the granted user, who has possibility to mint and burn token.
    function mint(
        address to,
        uint256 amount,
        uint256 _userInterestRate
    ) public
     onlyRole(MINT_AND_BURN_ROLE) {
        // This line here is minting the accrued interest for the user, who is passed as the parameter.
        _mintAccruedInterest(to);
        // This line here is assigning the interest rate to the user, who is passed as the parameter.
        // It's done either for the bridging purposes or for the case, when the user is depositing.
        addressToInterest[to] = _userInterestRate;
        _mint(to, amount);
    }

    // This internal function is responsible for minting the accrued interest for the user.
    // It accumulates all the interest that has been accrued since the last time it was minted.
    // So, given a user with a balance of 100 tokens, and an interest rate of 5%, the balanceOf function will return 105 tokens.
    // The function will mint the 5 tokens, and the user's balance will be updated to 105 tokens.
    // The next time the function is called, it will mint the interest on the 105 tokens, and so on.
    // So let's say in the next year the accrued intrest will start from 105 tokens and not 100.
    // This is a thing called compound interest, and it is a very powerful tool.
    function _mintAccruedInterest(address to) internal onlyOwner {
        // Here we get the previous balance of the user, who is passed as the parameter.
        // This is the balance before the interest is minted.
        uint256 previousPrincipleBalance = super.balanceOf(to);

        // Here we get the interest rate of the user, who is passed as the parameter.
        // And it's calculated by multiplying the interest rate with the time elapsed since the last update.
        // It returns simply the returns the tokens * (tokens * interest), which is the updated current state;
        uint256 currentBalance = balanceOf(to);

        // Then we get the substraction of it and we get the difference between the current balance and the previous balance.
        // So in essence, we get the amount of tokens, that we need to mint in our protocol.
        uint256 balanceIncrease = currentBalance - previousPrincipleBalance;

        // This function mints the appropriate amount of token to the user's address.
        // It is important to note that the mint function is only callable by the granted user, who has possibility to mint and burn token.
        // The _mint function is not only called for the purposes of the supply growth but also to increase the amount of tokens available.
        _mint(to, balanceIncrease);

        // In the end we update the last updated timestamp of the user, who is passed as the parameter.
        // This is the timestamp of the last time the interest was minted.

        s_lastUpdatedTimestamp[to] = block.timestamp;
    }

    // This function is responsible for calculating the interest rate of the user, who is passed as the parameter.
    // it finally returns the interest rate of the user, who is passed as the parameter.
    // This intrest grows linearly, so it is not a compound interest.
    function calculateInterest(
        address _user
    ) internal view returns (uint256 linearIntrest) {
        // Here we get how much time has passed since the last update of the user's balance.
        // This is the time elapsed since the last update.
        uint256 timeElapsed = block.timestamp - s_lastUpdatedTimestamp[_user];
        console.log(timeElapsed);
        // Here we get the interest rate of the user, who is passed as the parameter.
        // And it's calculated by multiplying the interest rate with the time elapsed since the last update.
        // So given a user with a balance of 100 tokens, and an interest rate of 5%, and the time elapsed of 1 year, the balanceOf function will return 105 tokens.

        linearIntrest =
            PRECISION_FACTOR +
            (addressToInterest[_user] * timeElapsed);
    }

    // This function burnes the tokens of the user, who is passed as the parameter.
    function burn(
        address from,
        uint256 value
    ) public onlyRole(MINT_AND_BURN_ROLE) {

        // This line here is minting the accrued interest for the user, who is passed as the parameter.
        // It's done to make sure that the user is not losing any interest, that has been accrued since the last time it was minted.
        _mintAccruedInterest(from);
        // This line here is burning the tokens of the user, who is passed as the parameter.
        _burn(from, value);
    }


    // This function is responsible for transferring the tokens from one user to another.
    function transfer(
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        // The amount is accumulated, meaning updated to the current state of accumulated/accrued interest of the user.
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }

        // Here we use the _mintAccruedInterest function to mint the accrued interest for the user, who is passed as the parameter.
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);

        // In case the balance of the recipient is 0, we assign the interest rate of the sender to the recipient.
        if (balanceOf(_recipient) == 0) {
            addressToInterest[_recipient] = addressToInterest[msg.sender];
        }
        // Finally we return the boolean value of the transfer function, which is inherited from the ERC20 contract.
        return super.transfer(_recipient, _amount);
    }

    // It does the same thing as the transfer function, but it also mint the accrued interest for the recipient.
    function transferFrom(
        address _from,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        // The amount is accumulated, meaning updated to the current state of accumulated/accrued interest of the user.
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }

        _mintAccruedInterest(_from);
        _mintAccruedInterest(_recipient);

        // In case the balance of the recipient is 0, we assign the interest rate of the sender to the recipient.
        if (balanceOf(_recipient) == 0) {
            addressToInterest[_recipient] = addressToInterest[_from];
        }

        // Finally we return the boolean value of the transfer function, which is inherited from the ERC20 contract.
        return super.transferFrom(_from, _recipient, _amount);
    }
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

        // This function gets the interest rate of the user, who is passed as the parameter.
    function getUserInterestRate(address user) external view returns (uint256) {
        return addressToInterest[user];
    }
}

    // Here we get the current interest rate available for the user, who is passed as the parameter.