# Workflow: Competitor keyword gap

## When to use

User wants the list of keywords competitors rank for that we don't. Two
sub-modes:

- **Gap from a list**: user provides 2–5 competitor domains.
- **Discover-then-gap**: user only knows their own domain (or a category
  description). Find competitors first, then gap.

## Prerequisites

- `references/concepts/dataforseo-endpoints.md`
- `references/concepts/keyword-metrics.md`
- `references/concepts/intent-taxonomy.md`

## Steps

### Step 1: Sanity-check the user's domain

`dataforseo_labs_google_domain_rank_overview_live` for the user's domain.

If the domain is brand-new and returns no organic data, switch to:
`dataforseo_labs_google_keywords_for_site_live` — DataForSEO infers what
the site *should* rank for from its content. This is the right
substitute.

Record the user's domain rank bucket (DR<30 / 30–60 / >60). KD calls
later will be interpreted against this bucket.

### Step 2: Discover competitors (only if user didn't list any)

`dataforseo_labs_google_competitors_domain_live` for the user's domain
(or for a strong seed keyword's #1 ranking domain if the user's site is
too new).

Filter the response: keep domains with `intersections >= 50` and
`avg_position <= 30`. Show the top 10 to the user, ask which 3–5 are
real competitors (drop aggregators and unrelated big-brand domains).

### Step 3: Pull each competitor's ranked keywords

For each chosen competitor:
`dataforseo_labs_google_ranked_keywords_live`

Parameters:
- `target`: competitor domain
- `location_code`, `language_code`: from ICP
- `limit`: 1000
- `filters`: `[["keyword_data.keyword_info.search_volume", ">", 50],
              ["ranked_serp_element.serp_item.rank_group", "<=", 20]]`

Cache each response.

### Step 4: Compute the gap

For each competitor, call:
`dataforseo_labs_google_domain_intersection_live`

Parameters:
- `target1`: user's domain
- `target2`: competitor domain
- `intersections`: `false` (we want the *non-overlap* — keywords where
  target2 ranks and target1 does NOT)

Filter results to:
- `target2` rank <= 20 (competitor in top 20)
- `target1` rank is null OR > 50 (we're not ranking)
- volume > 50

Repeat per competitor. Union the results. Dedupe.

### Step 5: Score for ICP relevance

Apply ICP filters (do this even if it costs you keywords — irrelevant
keywords pollute the plan):

- Drop keywords whose head terms don't match the ICP category.
- Drop keywords for anti-persona segments named in the ICP.
- Drop pure brand terms of the competitor (those are not real gaps —
  they're brand defense plays the user can't win).

### Step 6: Hydrate the gap list

`dataforseo_labs_google_bulk_keyword_difficulty_live` for the surviving
gap keywords (KD wasn't included in domain_intersection's payload in
useful form).

If volume / CPC are missing on any keyword, re-pull with
`keywords_data_google_ads_search_volume_live`.

### Step 7: Intent tag the head of the gap list

Run `serp_google_organic_live_advanced` for the top 20 gap keywords by
volume. Tag intent. Modifier-based intent for the rest.

### Step 8: Cluster + prioritize

Same as `icp-driven.md` steps 7–8. Add an extra column to each cluster
table: `Competitor ranking` (which of the user's competitors ranks where
for this term).

### Step 9: Anti-patterns checklist

Read `references/anti-patterns.md`. Verify. Deliver.

## Output Format

Same shape as `SKILL.md` → "Output Shape", with one addition: the cluster
tables include a `Competitor ranking` column showing which competitor
ranks for the term and at what position. The "Top opportunities" table
includes the same column so the operator sees who they're chasing.
