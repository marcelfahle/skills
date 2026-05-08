# Workflow: ICP-driven keyword research

## When to use

Default workflow. Use when starting a new project, building a campaign, or
planning content for a product where the user has (or will have) an ICP /
positioning doc. This is the path that turns "do keyword research for Sprint
Zero" into a usable plan.

## Prerequisites

Read these first, in order:

1. `references/concepts/dataforseo-endpoints.md` — confirm MCP is registered
   and the connection works. Smoke-test before any other call.
2. `references/concepts/intent-taxonomy.md` — you will tag every keyword.
3. `references/concepts/keyword-metrics.md` — column definitions.

## Steps

### Step 1: Locate the ICP

Search the user's Obsidian vault before asking for anything. Use the
`obsidian` skill.

```bash
# What vault is active?
obsidian-cli print-default --path-only

# Find ICP docs by name
obsidian-cli search "ICP"
obsidian-cli search "ideal customer"
obsidian-cli search "positioning"
obsidian-cli search "<project name>"

# Find ICP material by content
obsidian-cli search-content "ideal customer profile"
obsidian-cli search-content "<project name>"
```

If nothing matches, ask the user: "Where is the ICP for `<project>`? Path,
note title, or paste it here." Do not invent an ICP.

Read the doc(s). Extract:

- Product one-liner + category
- Primary persona(s) — title, company size, industry
- Top 3 pains / JTBD
- Geography + language (location_code, language_code)
- Direct competitors (URLs)
- Anti-personas / explicitly-excluded segments
- Brand vocabulary the user wants to use / avoid

Save this distilled context to
`keyword-research/raw/<project>/_icp-summary.md` as a one-page reference for
later steps.

### Step 2: Generate seeds (you, not the API)

From the ICP, write 5–15 seed keywords across three buckets. These are
hypotheses you will validate against the API in step 3.

- **Category seeds**: how the user describes the *product category*
  ("sprint planning tool", "agile estimation").
- **Pain seeds**: how the *persona* describes the problem ("how to plan a
  sprint", "estimate story points").
- **JTBD seeds**: the job they're trying to do ("plan engineering
  capacity", "kick off a project").

Save seeds to `keyword-research/raw/<project>/_seeds.md`. One line per seed,
with bucket tag + the ICP quote that justifies it.

### Step 3: Pull volume + CPC for the seeds

Validate the seeds with one cheap call. This filters out keywords no one
actually searches.

Tool: `keywords_data_google_ads_search_volume_live` (MCP) or
`POST /v3/keywords_data/google_ads/search_volume/live` (REST).

```
location_code: <from ICP>
language_code: <from ICP>
keywords: <all seeds, deduped, lowercased>
```

Cache the response. Drop seeds with `search_volume = 0` *unless* the seed is
clearly transactional (a brand or product term). Note dropped seeds in the
log — they're useful negatives later.

### Step 4: Expand each surviving seed

For every surviving seed, run TWO expansion calls in parallel and union the
results:

1. `dataforseo_labs_google_keyword_suggestions_live` — long-tail and
   question-form (best for content + transactional intent).
2. `keywords_data_google_ads_keywords_for_keywords_live` — Google Ads' own
   expansion (best for paid search variants).

Cap each call at 700 results. Dedupe across calls. Drop pure brand-typo
variants (e.g. "jira jora", "jira jria").

Now you have the raw corpus. Typical size: 500–3000 keywords.

### Step 5: Hydrate metrics

Two batched calls, both cheap.

1. `keywords_data_google_ads_search_volume_live` for the full corpus (1000
   per task, multiple tasks per HTTP call). Get `search_volume`, `cpc`,
   `competition_index`, `monthly_searches`.
2. `dataforseo_labs_google_bulk_keyword_difficulty_live` for the same
   corpus (1000 per call). Get `keyword_difficulty`.

Merge into one table. Drop rows where both volume and CPC are null/zero
unless they're a brand term.

### Step 6: Tag intent

For the **top 30 head terms by volume**, call
`serp_google_organic_live_advanced` (one per keyword — this is the
expensive bucket; do not run it on the whole corpus).

Apply the matrix in `references/concepts/intent-taxonomy.md` to each SERP.
Tag the head term with the dominant intent + any SERP features (AI
Overview, featured snippet, shopping pack).

For the rest of the corpus, infer intent from the modifier table in
`intent-taxonomy.md`. When uncertain, tag `commercial` and flag for review.

### Step 7: Cluster

Group by parent topic. Two cheap heuristics work well:

1. **Token overlap**: any two keywords sharing 2+ non-stopword tokens go in
   the same cluster (e.g. "sprint planning template" + "sprint planning
   software").
2. **Intent boundary**: never merge keywords across intent buckets even if
   tokens overlap. "best sprint planning tool" (commercial) and "sprint
   planning template" (informational) are separate clusters.

Name each cluster with the highest-volume keyword + intent in parentheses,
e.g. `Sprint planning template (informational)`.

Pull brand terms (user's brand, competitors' brand names from the ICP
competitor list) into a dedicated `Brand & competitor terms` cluster. Do
not mix.

### Step 8: Prioritize the top 10

Score every cluster's *best* keyword on:

- Volume (higher = better, log-scale)
- KD vs user's domain bucket (penalize if out of reach)
- CPC (proxy for buyer intent — higher = better for transactional)
- Intent match to the campaign goal (transactional > commercial >
  informational for ads; reverse for content TOFU)
- Competition gap (if competitors rank for it and we don't, +)
- ICP fit (does the keyword serve the persona's JTBD?)

Pick 10. Each gets a one-line "Why" in the deliverable.

### Step 9: Tie back to ICP + recommend page type

For each cluster, write one line in the deliverable:

- Persona served
- Pain / JTBD it addresses (quoted from the ICP doc)
- Recommended page type (from `intent-taxonomy.md` mapping)

### Step 10: Generate negatives (only if paid search is in scope)

From the dropped seeds + adjacent terms with mismatched intent, build the
negatives list. Add the obvious universals: `free`, `download`, `crack`,
`torrent`, `pdf`, `meaning`, `definition`, `wiki`, `reddit`, `youtube`
(unless any of these are intentional targets).

### Step 11: Apply the anti-patterns checklist

Read `references/anti-patterns.md`. Verify every box. Fix anything that
fails. Then deliver.

## Output Format

Output exactly the shape in `SKILL.md` → "Output Shape." No preamble,
no chat-log meta. Two files:

- `keyword-research/<project>/<YYYY-MM-DD>-plan.md`
- `keyword-research/<project>/<YYYY-MM-DD>-keywords.csv`

The markdown is the brief. The CSV is what gets pasted into Ads / Sheets.
