// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/intefaces/IRebaseToken.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RebaseTokenTest is Test {
    RebaseToken private rebaseToken;
    Vault private vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    uint256 public SEND_VALUE = 1e5;

     function addRewardToVault(uint256 amount) public {
        // send some rewards to the vault using the receive function
        payable(address(vault)).call{value: amount}("");
    }


        function setUp() public {
            vm.startPrank(owner);
            // Initialize the RebaseToken contract with a name and symbol
            // and set the interest rate to 5e10
            rebaseToken = new RebaseToken();

            // Initialize the Vault contract with the RebaseToken instance
            // and grant the Vault contract mint and burn roles
            vault = new Vault(IRebaseToken(address(rebaseToken)));
            rebaseToken.grantMintAndBurnRole(address(vault));
            vm.stopPrank();
        }


        function testDepositLinear(uint256 amount) public {
        
        // Deposit funds
            amount = bound(amount, SEND_VALUE, type(uint96).max);

        
            vm.startPrank(user);
            vm.deal(user, amount);
            vault.deposit{value: amount}();


    // Get the balance of the user
            uint256 startBalance = rebaseToken.balanceOf(
                user
            );
            console.log("Start balance: ", startBalance);

    // Update the timestamp to simulate the passage of time, so that the user can get the interest rate
            assertEq(startBalance, amount);

            vm.warp(block.timestamp + 1 hours);

    // Set the interest rate to 5e10
            uint256 midBalance = rebaseToken.balanceOf(
                user
            );

    // Check that the balance has increased
            assertGt(midBalance, startBalance);

            vm.warp(block.timestamp + 1 hours);

    // Check that the balance has increased again
            uint256 endBalance = rebaseToken.balanceOf(
                user
            );

            assertGt(endBalance, midBalance);

    // assertApproxEqAbs is a function that checks that the difference between two values is within a certain range
    // First param: the difference between the end balance and the mid balance
    // Second param: the difference between the mid balance and the start balance
    // Third param: the range of the difference
            assertApproxEqAbs(
                endBalance - midBalance,
                midBalance - startBalance,
                1
            );

    vm.stopPrank();
        }



                function testVaultRedeemGivenTheMaxUint256 () public{
            vm.startPrank(user);
            
            vm.deal(user, SEND_VALUE);

            vault.deposit{value: SEND_VALUE}();
            
            uint256 balance = rebaseToken.balanceOf(user);
            
            assertEq(balance, SEND_VALUE);
            
            vault.redeem(type(uint256).max);
            
            uint256 ethBalance = address(user).balance;
            
            assertEq(ethBalance, SEND_VALUE);
            assertEq(rebaseToken.balanceOf(user), 0);
            
            vm.stopPrank();
        }

function testRevertTheRedeem() public {
    // Step 1: Deposit as user and get tokens
    vm.deal(user, SEND_VALUE);
    vm.prank(user);
    vault.deposit{value: SEND_VALUE}();
    
    uint256 initialBalance = rebaseToken.balanceOf(user);
    assertEq(initialBalance, SEND_VALUE);

    // Step 2: Warp time to increase the balance due to rebase interest
    vm.warp(block.timestamp + 1 days); // Let interest accrue

    // Step 3: Get the new, higher balance after rebase
    uint256 increasedBalance = rebaseToken.balanceOf(user);
    assertGt(increasedBalance, initialBalance); // Confirm interest added

    // Step 4: Expect the redeem to fail because vault only has SEND_VALUE ETH
    vm.expectRevert(Vault.Vault__RedeemFailed.selector);
    vm.prank(user);
    vault.redeem(increasedBalance); // Try to redeem more than vault has
}



    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, SEND_VALUE, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();

        vault.redeem(amount);
uint256 balance = rebaseToken.balanceOf(user);

        assertEq(address(user).balance, amount);
        assertEq(  balance,
             0);

        vm.stopPrank();
    }

    function testRedeemAfterTimePassed(
        uint256 depositAmount,
        uint256 time
    ) public {
              time = bound(time, 1000, type(uint96).max); // this is a crazy number of years - 2^96 seconds is a lot
        depositAmount = bound(depositAmount, 1e5, type(uint96).max); // this is an Ether value of max 2^78 which is crazy

        // Deposit funds
        vm.deal(user, depositAmount);
        vm.prank(user);
        vault.deposit{value: depositAmount}();

        // check the balance has increased after some time has passed
        vm.warp(time);

        // Get balance after time has passed
        uint256 balance = rebaseToken.balanceOf(user);

        // Add rewards to the vault
        vm.deal(owner, balance - depositAmount);
        vm.prank(owner);
        addRewardToVault(balance - depositAmount);

        // Redeem funds
        vm.prank(user);
        vault.redeem(balance);

        uint256 ethBalance = address(user).balance;

        assertEq(balance, ethBalance);
        assertGt(balance, depositAmount);

    }


    function testDeposit(uint256 amount) public {
        amount = bound(amount, 1e3, type(uint96).max);
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
    }


    function testTransfer(uint256 amount, uint256 amountToSend) public {
        amount = bound(amount, SEND_VALUE + SEND_VALUE, type(uint96).max);
        amountToSend = bound(amountToSend, SEND_VALUE, amount - SEND_VALUE);

        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        address user2 = makeAddr("user2");
        uint256 userBalance = rebaseToken.balanceOf(user);
        uint256 user2Balance = rebaseToken.balanceOf(user2);

        assertEq(userBalance, amount);
        assertEq(user2Balance, 0);

        vm.prank(owner);
        rebaseToken.setInterestRate(4e10);

        vm.prank(user);
        rebaseToken.transfer(user2, amountToSend);
        uint256 userBalanceAfterTransfer = rebaseToken.balanceOf(user);
        uint256 user2BalanceAfterTransfer = rebaseToken.balanceOf(user2);
        assertEq(userBalanceAfterTransfer, amount - amountToSend);
        assertEq(user2BalanceAfterTransfer, user2Balance + amountToSend);

// Update the timestamp to simulate the passage of time
        vm.warp(block.timestamp + 1 days);

        uint256 userBalanceAfterTimeWarp = rebaseToken.balanceOf(user);
        uint256 user2BalanceAfterTimeWarp = rebaseToken.balanceOf(user2);

        uint256 user2InterestRate = rebaseToken.getUserInterestRate(user2);
        assertEq(user2InterestRate, 5e10);

        uint256 userInterestRate = rebaseToken.getUserInterestRate(user);
        assertEq(userInterestRate, 5e10);

        assertGt(userBalanceAfterTimeWarp, userBalanceAfterTransfer);
        assertGt(user2BalanceAfterTimeWarp, user2BalanceAfterTransfer);
    }

function testCannotCallBurn() public {
    vm.startPrank(user);
    vm.expectRevert();
    rebaseToken.burn(user, SEND_VALUE);
    vm.stopPrank();

}



    function testCannotSetInterestRate(uint256 rate) public {
    // Update the interest rate
        vm.startPrank(user);
        vm.expectRevert();
        rebaseToken.setInterestRate(rate);
        vm.stopPrank();
    }

    function testCannotCallMintAndBurn() public {
        vm.startPrank(user);
        uint256 interestRate= rebaseToken.getInterestRate();
        vm.expectRevert();
        rebaseToken.mint(user, SEND_VALUE, interestRate);
        vm.stopPrank();
    }

    function testCannotWithdrawMoreThanBalance() public {
        vm.startPrank(user);
        vm.deal(user, SEND_VALUE);
        
        vault.deposit{value: SEND_VALUE}();
        vm.expectRevert();
        vault.redeem(SEND_VALUE + 1);
        vm.stopPrank();
    }


    function testGetPrincipleAmount(uint256 amount) public {
        amount = bound(amount, SEND_VALUE, type(uint96).max);
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
        uint256 principleAmount = rebaseToken.principleBalanceOf(user);
        assertEq(principleAmount, amount);

        vm.warp(block.timestamp + 1 hours);
        uint256 principleAmountAfterWarp = rebaseToken.principleBalanceOf(user);
        assertEq(principleAmountAfterWarp, amount);
    }


function testInterestRateCanOnlyDecrease(uint256 newInterestRate) public {
    uint256 initialInterestRate = rebaseToken.getInterestRate();
newInterestRate= bound(newInterestRate, initialInterestRate, type(uint96).max);
    vm.prank(owner);
    vm.expectPartialRevert(
        bytes4(RebaseToken.RebaseToken__InvalidInterestRate.selector)
    );
    rebaseToken.setInterestRate(newInterestRate);
    assertEq(rebaseToken.getInterestRate(), initialInterestRate);

}

function testRedeemAfterTimeHasPassed(uint256 amountDeposited, uint256 time) public {
    time = bound(time, 1000, type(uint96).max); // this is a crazy number of years - 2^96 seconds is a lot
        amountDeposited = bound(amountDeposited, SEND_VALUE, type(uint96).max); // this is an Ether value of max 2^78 which is crazy

        // Deposit funds
        vm.deal(user, amountDeposited);
        vm.prank(user);
        vault.deposit{value: amountDeposited}();

        // check the balance has increased after some time has passed
      vm.warp(block.timestamp + time);

        // Get balance after time has passed
        uint256 balance = rebaseToken.balanceOf(user);

        // Add rewards to the vault
        vm.deal(owner, balance - amountDeposited);
        vm.prank(owner);
      addRewardToVault(balance - amountDeposited);
        (bool success, ) = payable(address(vault)).call{value: balance - amountDeposited}("");


        // Redeem funds
        vm.prank(user);
        vault.redeem(balance);

        uint256 ethBalance = address(user).balance;

        assertEq(balance, ethBalance);
        assertGt(balance, amountDeposited);
}

// These Tests are passed correctly
    function testGetRebaseTokenAddress() public view {
        assertEq(vault.getRebaseTokenAddress(), address(rebaseToken));
    }

    function testRevertNotElligibleToMint() public {
        vm.startPrank(user);
vm.expectRevert();
        rebaseToken.mint(user, SEND_VALUE, SEND_VALUE);
        vm.stopPrank();
    }


    function testSetInterestRate(uint256 newInterestRate) public {
        newInterestRate = bound(
            newInterestRate,
            0,
            rebaseToken.getInterestRate() - 1
        );

        vm.startPrank(owner);
        rebaseToken.setInterestRate(newInterestRate);
        uint256 interestRate = rebaseToken.getInterestRate();
        assertEq(interestRate, newInterestRate);
        vm.stopPrank();

        vm.startPrank(user);
        vm.deal(user, SEND_VALUE);
        vault.deposit{value: SEND_VALUE}();
        uint256 userInterestRate = rebaseToken.getUserInterestRate(user);
        vm.stopPrank();
        assertEq(userInterestRate, newInterestRate);
    }

    function testMaxUintTransfer() public{
        vm.startPrank(user);
        vm.deal(user, SEND_VALUE);

        vault.deposit{value: SEND_VALUE}();

       rebaseToken.transfer(
  owner , type(uint256).max);

       vm.stopPrank();
    }


    function testMaxUintTransferFrom () public{
   // Step 1: User deposits and gets tokens
    vm.startPrank(user);
    vm.deal(user, SEND_VALUE);
    vault.deposit{value: SEND_VALUE}();

    uint256 balance = rebaseToken.balanceOf(user);
    console.log("Balance: ", balance);
    assertEq(balance, SEND_VALUE);

    // Step 2: User approves owner to spend their tokens
    rebaseToken.approve(owner, balance);
    vm.stopPrank(); // End user's prank

    // Step 3: Owner calls transferFrom to move tokens
    vm.startPrank(owner);
    rebaseToken.transferFrom(user, owner, type(uint256).max);
    vm.stopPrank();

    // Optional: Verify the transfer worked
    assertEq(rebaseToken.balanceOf(owner), balance);
    assertEq(rebaseToken.balanceOf(user), 0);
    }



    function testInterestCanOnlyDecrease(uint256 newInterestRate) public {
        uint256 initialInterestRate = rebaseToken.getInterestRate();

        newInterestRate = bound(
           newInterestRate,
            initialInterestRate,
            type(uint96).max
        );
        vm.prank(owner);
        vm.expectPartialRevert(
            bytes4(RebaseToken.RebaseToken__InvalidInterestRate.selector)
        );
        rebaseToken.setInterestRate(newInterestRate);
        assertEq(rebaseToken.getInterestRate(), initialInterestRate);
    }
}
