module Waves::Router {
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::balance::{Balance};
    use Waves::LiquidityPool::{PriceBin, total_value_locked, swap_a_for_b};

    struct Router has key {
        id: UID,
        bins: vector<PriceBin>, // Registry of available bins
    }

    public fun init(ctx: &mut TxContext): Router {
        Router {
            id: object::new(ctx),
            bins: vector::empty(),
        }
    }

    public fun register_bin(router: &mut Router, bin: PriceBin) {
        vector::push_back(&mut router.bins, bin);
    }

    /// Core swap router: swaps CoinA for CoinB using best bins
    public fun route_swap_a_for_b(
        router: &mut Router,
        mut amount_in: Balance<coin::CoinA>,
        ctx: &mut TxContext
    ): Balance<coin::CoinB> {
        let mut result_b: Balance<coin::CoinB> = coin::zero();

        // Sort bins by best price_tick descending (i.e. highest output)
        // For simplicity: use naive selection without actual sorting here
        let len = vector::length(&router.bins);
        let mut i = 0;

        while (i < len && coin::value(&amount_in) > 0) {
            let bin = &mut vector::borrow_mut(&mut router.bins, i);

            let bin_b_liquidity = coin::value(&bin.token_b);
            let dynamic_fee = bin.base_fee_rate;

            let unit_price = bin.price_tick;
            let max_affordable_input = bin_b_liquidity / unit_price;

            let input_to_use = if (coin::value(&amount_in) <= max_affordable_input) {
                coin::split(&mut amount_in, coin::value(&amount_in))
            } else {
                coin::split(&mut amount_in, max_affordable_input)
            };

            let b_out = swap_a_for_b(bin, input_to_use, ctx);
            coin::merge(&mut result_b, b_out);
            i = i + 1;
        }

        // Remaining CoinA (if any) remains unspent
        result_b
    }
}