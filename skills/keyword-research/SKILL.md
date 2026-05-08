---
name: keyword-research
description: Run real keyword research with DataForSEO. Volumes, CPC, keyword
  difficulty, SERP intent, competitor gaps, and clustered topical maps grounded
  in the user's ICP — not vibes. Use when the user wants to "do keyword
  research," "find keywords for," "build a keyword list," "what should I rank
  for," "check search volume," "find keyword gaps vs competitors," "build a
  topical map," "plan a content cluster," "set up Google Ads keywords," "build
  an AdWords campaign," or "find long-tail keywords." Pulls the ICP from the
  user's Obsidian vault when present, talks to DataForSEO directly (REST or
  MCP), and produces a prioritized, intent-tagged keyword plan ready to feed
  into Ads, content, or SEO. Does NOT invent volumes or CPCs — every number is
  cited to a DataForSEO endpoint and timestamp.
---

# Keyword Research

Real keyword research means real data. Every keyword in the final output has a
DataForSEO-sourced search volume, CPC, and difficulty — or it does not appear.
No guesses. No "estimated." If the API returns nothing, the keyword is dropped
or flagged, never faked.

The job: take a fuzzy intent ("find keywords for Sprint Zero", "build the ad
campaign for X") plus the user's ICP, and return a prioritized, intent-clustered
keyword plan that an operator can paste into Google Ads, a content brief, or a
programmatic SEO template.

## Mode Selection

Pick the mode from the user's request. Each mode → Read the matching workflow
file before doing anything else.

- **ICP-driven research** (default for new projects, ad campaigns, new pages):
  user gives a product / project name and (optionally) the ICP doc. Read
  `references/workflows/icp-driven.md`.
- **Seed expansion**: user already has 1–10 seed keywords and wants the full
  cluster. Read `references/workflows/seed-expansion.md`.
- **Competitor gap analysis**: user gives 1–N competitor domains and wants the
  keywords they rank for that we don't. Read
  `references/workflows/competitor-gap.md`.
- **Google Ads campaign**: user is building or refining a paid search campaign
  (exact/phrase/broad match groups, negative lists, CPC ceilings). Read
  `references/workflows/google-ads-campaign.md`.

If the user's request straddles modes (common: "build the AdWords campaign for
Sprint Zero, ICP is in Obsidian") run them in order: ICP-driven → seed
expansion → competitor gap → Google Ads.

## Prerequisites (run once, fail loud)

Before any keyword work, verify DataForSEO access. Read
`references/concepts/dataforseo-endpoints.md` for the full setup.

1. Confirm the `dataforseo` MCP is registered:
   ```bash
   openclaw mcp list | grep -i dataforseo || \
     echo "→ Register it: see references/concepts/dataforseo-endpoints.md"
   ```
2. Smoke-test the connection by calling the cheapest tool (e.g.
   `dataforseo.appendix_user_data` or the REST equivalent) and reading
   `money` from the response. If money is 0 or auth fails, stop and ask the
   user to top up / fix credentials. Never proceed and silently degrade to
   guessed numbers.

## Hard Constraints

1. **Every keyword in the output has a real DataForSEO number.** No hallucinated
   volumes. No "approximately 1K." If the API returns null, drop it or mark
   `volume=NULL (no_data)`.
2. **Cite the source on every batch.** Each table footer states the endpoint,
   location code, language code, and ISO timestamp of the call.
3. **Always pull the ICP first** when one exists. Search the Obsidian vault
   before asking the user to paste anything. Use the `obsidian` skill's
   `obsidian-cli search-content "ICP"` and friends.
4. **Tag every keyword with intent** (informational / commercial /
   transactional / navigational / local). Intent comes from the SERP, not from
   the keyword string. When uncertain, run a SERP check.
5. **Cluster before delivering.** Raw keyword dumps are not an output. Group by
   parent topic + intent + funnel stage.
6. **Brand vs generic split is mandatory.** Brand terms (the user's name,
   competitors' names) are reported separately and never mixed into the generic
   commercial cluster.
7. **Keyword Difficulty (KD) is reported with the threshold context.** "KD 35"
   alone is meaningless; pair it with the user's domain rating bucket (new
   site / DR<30 / DR 30–60 / DR>60) and a go/no-go.
8. **Cache raw API responses.** Save every DataForSEO response to
   `keyword-research/raw/<project>/<YYYY-MM-DD>/<endpoint>.json`. Re-runs read
   the cache before re-billing the API.
9. **Respect the user's locale.** Default to the location and language declared
   in the ICP. If absent, ask once, then proceed.
10. **No final delivery without the anti-patterns checklist.** Read
    `references/anti-patterns.md` and verify every item before handing back the
    plan.

## Soft Constraints

1. Prefer batches of 100–700 keywords per call (DataForSEO sweet spot).
2. Default location: `2840` (United States), language `en` — override per ICP.
3. Default to **monthly volume**, **competition**, **CPC**, and (when
   available) **KD** as the four core columns. Add **search intent** and
   **parent topic** as derived columns.
4. When the user has Ahrefs / Semrush data, cross-reference but trust
   DataForSEO's volume as canonical (it's their pipeline).
5. Use `dataforseo_labs/google/bulk_keyword_difficulty/live` to get KD for up
   to 1000 keywords in one call instead of one-at-a-time.
6. For long-tail expansion, prefer
   `dataforseo_labs/google/keyword_suggestions/live` over `related_keywords` —
   it surfaces more transactional variants.
7. Save the final plan as a markdown file with a CSV companion. Operators
   paste the CSV into Ads / sheets, the markdown is the human-readable brief.

## Output Shape

Every final deliverable has this exact structure (operators rely on the
shape — do not freelance):

```
# Keyword plan: <project>

## Snapshot
- ICP: <one line>
- Location / language: <e.g., 2840 / en>
- Source: DataForSEO (<endpoints used>) — pulled <ISO timestamp>
- Total keywords: N (M after dedupe + intent filter)

## Top opportunities (the 10 to act on this week)
| # | Keyword | Vol | KD | CPC | Intent | Parent topic | Why |

## Cluster: <parent topic 1>
| Keyword | Vol | KD | CPC | Intent | Match type | Notes |

## Cluster: <parent topic 2>
...

## Brand & competitor terms (separate)
| Keyword | Vol | KD | CPC | Intent | Notes |

## Negatives (for paid search)
- term, term, term

## Gaps observed
- ...

## Next actions
- ...
```

## Reference File Index

- `references/anti-patterns.md` — **Load before every delivery.** Pre-flight
  checklist that catches hallucinated metrics, missing citations, missing
  intent tags, and unclustered dumps.
- `references/concepts/dataforseo-endpoints.md` — **Load before any API
  call.** Auth, endpoint catalog (REST + mcporter), cost notes, batch limits,
  location / language code reference.
- `references/concepts/keyword-metrics.md` — Glossary: volume, CPC, KD,
  competition index, SERP features, click potential.
- `references/concepts/intent-taxonomy.md` — How to derive intent from SERPs
  (not from the keyword string), and how to map intent to funnel stage and
  page type.
- `references/workflows/icp-driven.md` — Default workflow. ICP → seeds →
  expansion → SERP validation → cluster → prioritize.
- `references/workflows/seed-expansion.md` — Given seeds, produce the full
  semantic + transactional cluster.
- `references/workflows/competitor-gap.md` — Given competitor domains, find
  what they rank for that we don't, scored by relevance to our ICP.
- `references/workflows/google-ads-campaign.md` — Translate the keyword plan
  into an actual Google Ads campaign skeleton (ad groups, match types,
  negatives, CPC ceilings).
- `references/examples/sample-output.md` — One worked example end-to-end so
  the shape is unambiguous.
