// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRebaseToken} from "../src/intefaces/IRebaseToken.sol";
import {TokenPool, Pool} from "../lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenPoolFactory/TokenPoolFactory.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


// This smart contract has been created for the purpose of locking or burning rebase tokens and minting them on the destination chain.
// It is a part of the CCIP Token Pool Factory and is used to facilitate the transfer of tokens across different chains.
// The contract inherits from the TokenPool contract and implements the lockOrBurn and releaseOrMint functions to handle the locking, burning, and minting of rebase tokens.

contract RebaseTokenPool is TokenPool {
    constructor(
        IERC20 _token,
        address[] memory elligibleList,
        address _rnmProxy,
        address _router
    ) TokenPool(_token, 18, elligibleList, _rnmProxy, _router) {}

    function lockOrBurn(
        Pool.LockOrBurnInV1 memory lockOrBurnIn
    ) external returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut) {
        _validateLockOrBurn(lockOrBurnIn);



        uint256 userInterestRate = IRebaseToken(address(i_token))
            .getUserInterestRate(lockOrBurnIn.receiver);

        IRebaseToken(address(i_token)).burn(address(this), lockOrBurnIn.amount);

        lockOrBurnOut = Pool.LockOrBurnOutV1({
         destPoolData:abi.encode(userInterestRate),
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector)
        });
    }

    function releaseOrMint(
        Pool.ReleaseOrMintInV1 calldata releaseOrMintIn
    ) external returns (Pool.ReleaseOrMintOutV1 memory) {
        _validateReleaseOrMint(releaseOrMintIn);
        uint256 userInterestRate = abi.decode(releaseOrMintIn.sourcePoolData, (uint256));
        IRebaseToken(address(i_rebaseToken)).mint(releaseOrMintIn.receiver,releaseOrMintIn.amount, userInterestRate);

        return Pool.ReleaseOrMintOutV1({
            destinationAmount: releaseOrMintIn.amount
        })
    }

    
}
