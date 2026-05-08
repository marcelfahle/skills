# When to migrate this skill from X API → Apify

Right now (V1) this skill talks to the official X API v2. The ceiling is:

- $0.005 per arbitrary tweet read,
- 2,000,000 monthly post-reads cap before Enterprise,
- 7-day search window only.

The "Cheap & Simple X" Apify actor (and the broader Apify scraper ecosystem)
prices arbitrary tweet reads at roughly **$0.00046 per tweet** — about 11×
cheaper than the API's $0.005 — and supports historical search (no 7-day
window) plus full thread expansion.

## Migrate when any of these is true

1. Marcel's monthly arbitrary-read volume crosses ~10,000 tweets — at that point
   API spend is $50+/month and Apify would be $5.
2. He needs historical search (older than 7 days). API recent-search literally
   cannot do this on the cheap tier.
3. He wants thread reconstruction without the 3–6-call walk this skill does
   today. Apify actors return whole threads in one shot.
4. The 2M/month cap starts to matter (it won't for personal use, but it might
   if a public-facing bot ends up calling this).

## What stays the same

The skill's CLI surface (`x-read.sh tweet|tweets|timeline|...`) does not change.
V2 swaps the implementation behind those subcommands; agents that call the
skill don't need to know.

## What stays on the official API even after migrating

- Owned reads ($0.001/resource — already cheaper than Apify): **bookmarks,
  mentions, own timeline, own likes**. Keep these on the X API; Apify can't
  authenticate as Marcel for owned-private resources.
- `whois` / username → id lookup. Cheap and authoritative on the API.

## Implementation sketch (V2)

1. Add `APIFY_TOKEN` to gateway env.
2. Pick the actor — likely `apidojo/twitter-scraper-lite` or `quacker/twitter-scraper`
   based on price/freshness benchmarks at migration time.
3. Replace `cmd_tweet`, `cmd_tweets`, `cmd_timeline` (when not own), `cmd_search`,
   `cmd_thread` to POST to `https://api.apify.com/v2/acts/<actor>/run-sync-get-dataset-items`
   with the appropriate input shape, then map the actor's output back to the
   v2-compatible JSON envelope this skill already returns.
4. Keep `cmd_mentions`, `cmd_bookmarks`, `cmd_likes` (owned), and `cmd_whois`
   pointed at the X API.
5. Add a `--source api|apify` override flag in case one backend is down.

## Cost ceiling check

Before migrating, sanity-check the actual price by running a small benchmark:

```bash
# Pull 100 of @elonmusk's recent tweets through both backends, compare cost + freshness.
./scripts/bench-backends.sh elonmusk 100   # to be added in V2
```

If Apify's per-tweet cost has drifted above $0.001, the migration math falls
apart for owned reads — re-evaluate.
