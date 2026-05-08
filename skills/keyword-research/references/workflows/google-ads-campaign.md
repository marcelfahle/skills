# Workflow: Google Ads campaign skeleton

## When to use

User is building or refining a paid search campaign (Sprint Zero AdWords
campaign is the canonical example). Translates a keyword plan into a
real campaign skeleton with ad groups, match types, negatives, and CPC
ceilings.

## Prerequisites

Run `icp-driven.md` (or `seed-expansion.md`) first. This workflow assumes
you already have a clustered, intent-tagged keyword plan. If you don't,
do that first.

Then read:
- `references/concepts/keyword-metrics.md` — match-type table at the
  bottom is the source of truth.
- `references/concepts/intent-taxonomy.md` — intent → bid table.

## Steps

### Step 1: Filter for paid-search candidates

From the keyword plan, keep only:

- **transactional** intent (always)
- **commercial** intent (always)
- **navigational — own brand** (always; cheap defensive)
- **navigational — competitor brand** (only if user explicitly opts in;
  flag the risk of QS penalty + ToS issues with personal-name brands)
- **local** intent (only if the user has a local-targeting goal)

Drop everything else. Add the dropped informational/local-mismatch terms
to the negatives list.

### Step 2: Map clusters → ad groups

One ad group per cluster. The ad group inherits the cluster's intent
tag. Name pattern:

```
<Campaign> | <Intent>: <Cluster head term>
```

Example: `Sprint Zero | Transactional: agile estimation tool`.

Every ad group needs:

- 5–15 keywords (Google's recommended SKAG-ish density; tighter is
  better for QS).
- ≥ 3 ad copy variants matching the cluster's intent (this skill does
  not write ad copy — flag it as a downstream task).
- A landing page that matches the cluster's intent. If the user
  doesn't have one, flag it as a blocker.

### Step 3: Assign match types

Use the table from `keyword-metrics.md`:

| Cluster intent | Match types to use | Why |
|---|---|---|
| Transactional, head terms | `[exact]` | Tight control, high CPC |
| Transactional, mid-tail | `[exact]` + `"phrase"` | Coverage |
| Commercial | `"phrase"` | Catch comparison variants |
| Brand (own) | `[exact]` | Defensive, cheap |
| Brand (competitor) | `[exact]` | Tight; never broad |
| Discovery only | broad | Only with strong negatives |

Default to **never use broad** unless the user explicitly asks. If they
do, add a paragraph in the deliverable noting the negatives strategy
required.

### Step 4: Set CPC ceilings

For each keyword:

- **Floor**: `low_top_of_page_bid` from DataForSEO.
- **Target**: midpoint of low and high top-of-page bids.
- **Ceiling**: `high_top_of_page_bid * 1.2`.

Output a single suggested CPC per keyword (the target). Note the
ceiling in the brief so the operator can set max bids in Google Ads.

If the user has a budget number, compute estimated daily clicks:
`budget_daily / weighted_avg_cpc * 0.7` (the 0.7 is a realistic
serve-rate haircut). Show the math in the brief.

### Step 5: Build the negatives list

Three sources, in order:

1. **Universal negatives** (always include unless explicitly relevant):
   `free`, `download`, `crack`, `torrent`, `pdf`, `meaning`,
   `definition`, `wiki`, `reddit`, `youtube`, `tutorial`, `course`,
   `jobs`, `salary`, `intern`, `template free`.
2. **Anti-persona negatives** from the ICP (e.g., if the ICP excludes
   students: `student`, `homework`, `assignment`).
3. **Dropped-seed negatives**: any seed from earlier steps that had
   wrong intent, plus the modifier that made it wrong (e.g., if "agile
   coach jobs" leaked into a "agile coach" expansion, add `jobs`).

Save as a comma-separated list at the bottom of the brief. Tag each
negative as `account-level` or `campaign-level`.

### Step 6: Pick the campaign type + structure

Default: **Search campaign**, single campaign per *intent bucket*.

```
Campaign 1: <Project> — Transactional
  ↳ Ad group per transactional cluster
Campaign 2: <Project> — Commercial
  ↳ Ad group per commercial cluster
Campaign 3: <Project> — Brand (own)
  ↳ One ad group
[Campaign 4: <Project> — Brand (competitor)] — only if requested
```

Why split by intent: lets the operator set different bid strategies and
budgets per intent. Transactional gets aggressive bid; commercial gets
target ROAS or manual; brand gets minimum bid.

### Step 7: Bid strategy recommendation

- **New account / no conversion data yet**: Manual CPC for first 2–4
  weeks, then switch to Maximize Conversions once 30+ conversions are in.
- **Has conversion data**: Maximize Conversions or Target CPA per ad
  group's historical CPA × 1.1.

State this once in the brief as a header note; do not repeat per group.

### Step 8: Anti-patterns checklist

Read `references/anti-patterns.md`. In addition to the standard items,
verify campaign-specific ones:

- [ ] Every keyword has a match type (none left as raw broad).
- [ ] Every ad group has a landing page mapped (or is flagged as
      missing).
- [ ] Negatives list is non-empty.
- [ ] Bid strategy is stated once, at the top.
- [ ] Brand and generic terms are in different campaigns.

## Output Format

Same `SKILL.md` → "Output Shape" plus a paid-search appendix:

```
## Campaign skeleton

### Campaign: <Project> — Transactional
- Bid strategy: <…>
- Daily budget suggestion: $<…>
- Estimated daily clicks: <…>

#### Ad group: <name>
- Landing page: <url or BLOCKER>
- Keywords:
  | Keyword | Match | Vol | CPC target | CPC ceiling |
- Ad copy: TODO (out of scope for this workflow)

(repeat per ad group, per campaign)

## Negatives
- Account-level: term, term, …
- Campaign-level — Transactional: term, term, …
- Campaign-level — Commercial: term, term, …
```

CSV companion has the same columns flattened, plus a `Campaign`,
`Ad group`, and `Match type` column. This is the file the operator
uploads to Google Ads Editor.
