// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "../lib/forge-std/src/Script.sol";
import {IRouterClient} from "../lib/ccip/contracts/src/v0.8/ccip/IRouterClient.sol";
import {Client} from "../lib/ccip/contracts/src/v0.8/ccip/Client.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract BridgeTokens is Script {
    function run(
        address receiverAddress,
        uint64 destinationChainSelector,
        address tokenToSendAddress,
        uint256 amountToSend,
        address linkTokenAddress,
        address routerAddress
    ) public {
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);

        tokenAmounts[0] = Client.EVMTokenAmount({
            token: tokenToSendAddress,
            amount: amountToSend
        });

        vm.startBroadcast();
        Client.EVM2AnyMessage message = Client.EVM2AnyMessage({
            sender: address(this),
            data: "",
            tokenAmounts: tokenAmounts,
            feeToken: linkTokenAddress,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 0}))
        });
        uint256 ccipFee = IRouterClient(routerAddress).getFee(
            destinationChainSelector,
            message
        );
        IERC20(linkTokenAddress).approve(routerAddress, ccipFee);
        IRouterClient(routerAddress).ccipSend(
            destinationChainSelector,
            message
        );
        vm.stopBroadcast();
    }
}
