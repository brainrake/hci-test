# Bashoswap

This is only the DEX part of Bashoswap.
Currently it doesn't restrict trading to a stablecoin because the Bashoswap
stablecoin hasn't been developed.

# General design

Uniswap v2's design is the base. i.e. we have liquidity pools,
product of liquidity pool must never decrease through a trade,
adding to the pool gives you the geometric mean of what you added
as liquidity pool tokens, when you withdraw you get back a portion
of the funds corresponding to your geometric mean / the geometric mean
of the whole pool.

## Throughput solution

We have global mutable state in the form of liquidity pools. We need to ensure that users can
operate on this shared mutable state in a timely manner.

Considering the properties of Cardano, small transactions are more likely to go through due
to the FIFO nature. Because of this, we want the transactions of the protocol to be as small
as possible.

We employ "sharding" to reduce the contention of the protocol.
Once a liquidity pool is used often enough, it will be split up.
If a liquidity pool isn't used often enough, it's a candidate for
merging with a liquidity pool with the same pair of tokens.

End-users who want to interact with the protocol will generally create one transaction
*per* liquidity pool, in such a fashion that only one of them can be accepted (by
making them all consume a shared UTXO).

Due to the limited size of liquidity pools, larger trades will have to be split
into multiple trades.

### Transaction chaining

It is likely possible to chain transactions such that transaction A with output Ao
and transaction B with input Ao can be put into the same block.

If it is not possible, it is likely simple to implement such a change in Cardano
and have it be accepted via a CIP.

Through this mechanism, users can cooperate off-chain to reduce contention,
such that a user can consume a liquidity pool output by the trade of another
user *in the same block*.

#### Security

FIXME: We need to figure out a way to make honest users
more successful than dishonest users. Intuitively there should be a way.

### Liquidity pool tokens

There is the question of how to handle liquidity pool tokens.
When a pool splits, then we need to split up the liquidity pool tokens
between the two new pools. Adding funds to one of the pools
must also not mean you can withdraw from the other.

To achieve this, when splitting, the token name changes.
We however create a new UTXO per new pool that contains
the corresponding (i.e. half) amount of the old LP tokens but with the
new name.
We can withdraw from this UTXO if we burn the corresponding amount
of the old LP tokens.

When we merge, we do the same thing but in reverse.
The UTXO now supports burning either of two LP token types.

# Formal specification

This will be done in MLabs's internal specification language which is to be open sourced.
This will concretely define the exact semantics of the protocol.
