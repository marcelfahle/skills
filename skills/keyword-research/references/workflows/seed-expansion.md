# Workflow: Seed expansion

## When to use

User already has 1–10 seed keywords and just wants the full cluster with
real metrics. No ICP needed (but still useful if available).

## Prerequisites

- `references/concepts/dataforseo-endpoints.md`
- `references/concepts/keyword-metrics.md`
- `references/concepts/intent-taxonomy.md`

## Steps

### Step 1: Confirm seeds + locale

Restate the seeds back to the user in one line. Confirm `location_code`
and `language_code`. Default to `2840` / `en` only if the user's request
makes US English unambiguous.

### Step 2: Validate seeds

Single call:
`keywords_data_google_ads_search_volume_live` for the seed list.

Drop seeds with volume 0 unless explicitly brand/product. Flag the drops
in the deliverable.

### Step 3: Expand

For each surviving seed, in parallel:

1. `dataforseo_labs_google_keyword_suggestions_live` (limit 700)
2. `keywords_data_google_ads_keywords_for_keywords_live` (limit 700)

Union, dedupe.

### Step 4: Hydrate

1. `keywords_data_google_ads_search_volume_live` for the union.
2. `dataforseo_labs_google_bulk_keyword_difficulty_live` for the union.

### Step 5: Intent tag

Run `serp_google_organic_live_advanced` for the top 20 head terms by
volume. Modifier-based intent for the long tail. See
`references/concepts/intent-taxonomy.md`.

### Step 6: Cluster

Token overlap + intent boundary, as in `icp-driven.md` step 7. Name each
cluster with the head term + intent.

### Step 7: Prioritize top 10

Volume × intent × KD-vs-DR. One-line "Why" per pick.

### Step 8: Anti-patterns checklist

Read `references/anti-patterns.md`. Verify. Deliver.

## Output Format

Same shape as `SKILL.md` → "Output Shape." Markdown brief + CSV companion.
Skip the "ICP fit" notes if no ICP was provided; everything else is
identical.
