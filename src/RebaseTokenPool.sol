// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRebaseToken} from "../src/intefaces/IRebaseToken.sol";
import {TokenPool, Pool} from "../lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenPoolFactory/TokenPoolFactory.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

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

        address receiver = abi.decode(lockOrBurnIn.receiver, (address));

        uint256 userInterestRate = IRebaseToken(address(i_token))
            .getUserInterestRate(receiver);

        IRebaseToken(address(i_token)).burn(address(this), lockOrBurnIn.amount);

        lockOrBurnOut = Pool.LockOrBurnOutV1({
            amount: lockOrBurnIn.amount,
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector)
        });
    }

    function releaseOrMint(
        Pool.ReleaseOrMintInV1 calldata releaseOrMintIn
    ) external returns (Pool.ReleaseOrMintOutV1 memory) {}
}
