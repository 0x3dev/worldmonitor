#!/bin/sh
# Railway seeder service entrypoint — curated seeder list for this deployment.
# Tracked in-repo so the list is reviewable; Dockerfile.seeder runs this as CMD
# (clear any custom start command on the Railway service so the CMD applies).
#
# Order matters for first-run correctness:
#   - seed-commodity-quotes / seed-market-quotes / seed-economy write the
#     market + FRED input caches that seed-forecasts reads.
#   - seed-cot writes the COT cache that gold intelligence joins against.
#   - seed-forecasts runs LAST (LLM market implications over the world state
#     the earlier seeders just wrote; needs GROQ_API_KEY).
#
# Keys consumed here: FRED_API_KEY, EIA_API_KEY, FINNHUB_API_KEY (earnings),
# GROQ_API_KEY (forecasts), ALPHA_VANTAGE_API_KEY (optional, commodities/ETF
# flows primary), COINGECKO_API_KEY (optional, stablecoins pro tier).

SEEDERS="
seed-prediction-markets
seed-ucdp-events
seed-conflict-intel
seed-fao-food-price-index
seed-energy-disruptions
seed-fuel-shortages
seed-commodity-quotes
seed-market-quotes
seed-market-breadth
seed-aaii-sentiment
seed-economy
seed-fear-greed
seed-economic-calendar
seed-chokepoint-baselines
seed-chokepoint-flows
seed-cot
seed-gold-etf-flows
seed-gold-cb-reserves
seed-earnings-calendar
seed-etf-flows
seed-hyperliquid-flow
seed-stablecoin-markets
seed-forecasts
"

ok=0
fail=0
failed_names=""

for s in $SEEDERS; do
  echo "→ $s"
  if node "scripts/$s.mjs"; then
    ok=$((ok + 1))
  else
    echo "FAILED: $s"
    fail=$((fail + 1))
    failed_names="$failed_names $s"
  fi
done

echo "── seeders done: $ok ok, $fail failed${failed_names:+ (${failed_names# })}"
# Always exit 0: partial upstream flakiness is routine and each seeder
# preserves its last-good cache; a nonzero exit would mark the whole
# Railway cron run failed and obscure which seeder actually broke.
exit 0
