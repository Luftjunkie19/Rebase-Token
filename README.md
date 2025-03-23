# Cross-Chain Rebase Token

1. A protocol that allows user to deposit to into a vault and in return, receiver rebase tokens that represent their underlying balance.

2. Rebase Token --> balanceOf function is dynamic to show the increasing balance with time.
- Balance increases linearly with time.
- Mint tokens to our users every time they perform an action (minting, burning, transferring, or.....bridging)

3. Interest Rate
- Individually set an interest rate or each user based on some global interest rate of the protocol at the time the user deposits into the vault.
- The global interest rate can only decrease to incentivize/reward early adopters.