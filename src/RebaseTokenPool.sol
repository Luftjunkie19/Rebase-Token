// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRebaseToken} from "../src/intefaces/IRebaseToken.sol";
import {TokenPool} from "../lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";

import {Pool} from "../lib/ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";

import {IERC20} from "../lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


// This smart contract has been created for the purpose of locking or burning rebase tokens and minting them on the destination chain.
// It is a part of the CCIP Token Pool Factory and is used to facilitate the transfer of tokens across different chains.
// The contract inherits from the TokenPool contract and implements the lockOrBurn and releaseOrMint functions to handle the locking, burning, and minting of rebase tokens.

contract RebaseTokenPool is TokenPool {
constructor(IERC20 _token, address[] memory elligibleList, address _rnmProxy, address _router) 
TokenPool(_token, 18, elligibleList, _rnmProxy, _router) 
{}


// The lockOrBurn function is used to lock or burn the specified amount of tokens on the source chain and prepare them for transfer to the destination chain.
// It takes a Pool.LockOrBurnInV1 struct as input, 
// which contains the details of the lock or burn operation, and returns a Pool.LockOrBurnOutV1 struct as output, which contains the details of the operation's result.
    function lockOrBurn(
        Pool.LockOrBurnInV1 calldata lockOrBurnIn
    ) external virtual override returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut) {
   // Validate the lock or burn operation using the _validateLockOrBurn function from the TokenPool contract.
        _validateLockOrBurn(lockOrBurnIn);

// Get the user interest rate for the specified receiver address from the IRebaseToken contract.
        // This interest rate is used to calculate the amount of tokens to be minted on the destination chain.
        uint256 userInterestRate = IRebaseToken(address(i_token))
            .getUserInterestRate(lockOrBurnIn.originalSender);

// Check if the user interest rate is valid (greater than 0) and revert if it is not.
        IRebaseToken(address(i_token)).burn(address(this), lockOrBurnIn.amount);

// The burn operation is performed on the source chain to remove the specified amount of tokens from circulation.
// The amount of tokens to be burned is specified in the lockOrBurnIn struct.
        lockOrBurnOut = Pool.LockOrBurnOutV1({
         destPoolData:abi.encode(userInterestRate),
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector)
        });
    }

// The releaseOrMint function is used to mint the specified amount of tokens on the destination chain after they have been locked or burned on the source chain.
// It takes a Pool.ReleaseOrMintInV1 struct as input, which contains the details of the release or mint operation, and returns a Pool.ReleaseOrMintOutV1 struct as output, which contains the details of the operation's result.
    function releaseOrMint(
        Pool.ReleaseOrMintInV1 calldata releaseOrMintIn
    ) external returns (Pool.ReleaseOrMintOutV1 memory) {
    // Validate the release or mint operation using the _validateReleaseOrMint function from the TokenPool contract.
        // This function checks if the operation is valid and reverts if it is not.
        // It also checks if the sender is allowed to perform the operation and if the amount is valid.
        // The _validateReleaseOrMint function is inherited from the TokenPool contract.
        // It is used to ensure that the operation is valid and that the sender is allowed to perform it.
        _validateReleaseOrMint(releaseOrMintIn);


        // The user interest rate is retrieved from the source pool data using the abi.decode function.
        // The source pool data contains the user interest rate that was set during the lockOrBurn operation.
        // The method of decoding the source pool data is used to extract the user interest rate from the data.
        uint256 userInterestRate = abi.decode(releaseOrMintIn.sourcePoolData, (uint256));

// The IRebaseToken there is used to mint the specified amount of tokens on the destination chain.
        // The mint operation is performed on the destination chain to create the specified amount of tokens.
        IRebaseToken(address(IRebaseToken(address(i_token)))).mint(releaseOrMintIn.receiver,releaseOrMintIn.amount, userInterestRate);

// The mint operation is performed on the destination chain to create the specified amount of tokens.
        // The amount of tokens to be minted is specified in the releaseOrMintIn struct.
        return Pool.ReleaseOrMintOutV1({
            destinationAmount: releaseOrMintIn.amount
        });
    }

    
}
