module Waves::LPToken {
    use sui::object::{Self, UID};
    use sui::balance::{Self};
    use sui::tx_context::TxContext;

    struct LPToken has key {
        id: UID,
        owner: address,
        bin_price_tick: u64,
        liquidity: u64,
    }

    public fun mint(
        ctx: &mut TxContext,
        owner: address,
        bin_price_tick: u64,
        liquidity: u64
    ): LPToken {
        LPToken {
            id: object::new(ctx),
            owner,
            bin_price_tick,
            liquidity,
        }
    }
}