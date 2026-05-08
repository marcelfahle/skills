# Keyword metrics glossary

Use these definitions consistently in every output. Operators read fast and
expect column meanings to be stable.

## Volume

**Monthly search volume**, averaged over the last 12 months by Google Ads
Keyword Planner (the source DataForSEO mirrors). Reported as a single integer
per keyword for the requested location + language.

- Volumes < 10 round to 0 in Google's data — DataForSEO returns the raw
  value. Keep `0` distinct from `null`.
- Seasonal terms: pull the `monthly_searches` array and flag if the peak
  month is >3× the trough.

## CPC

**Cost-per-click** in USD as the average top-of-page bid Google reports.
Useful for two things:

1. As an **intent signal** — high CPC ($10+) almost always means a paying
   buyer is at the end of the funnel.
2. As a **paid-search budget input** — multiply by expected click volume to
   size a campaign.

DataForSEO also returns `low_top_of_page_bid` and `high_top_of_page_bid`.
Show the high bid in the campaign workflow, the average CPC in the content
workflow.

## Competition / competition_index

Google's **paid-competition** signal (0–1 in `competition`, 0–100 in
`competition_index`). It is *not* SEO competition. Don't confuse it with KD.

Use it only when planning paid search. Ignore it for SEO.

## KD (Keyword Difficulty)

DataForSEO's 0–100 SEO difficulty score. Measures how strong the top-10
backlink + authority profile is, not how good the content is.

| KD | What it means | Who can win |
|----|---------------|-------------|
| 0–10 | Trivial | Anyone, including new sites |
| 11–30 | Easy | DR<30 with focused content |
| 31–50 | Moderate | DR 30–60 sites, or DR<30 with strong topical authority |
| 51–70 | Hard | DR 60+ or pSEO play |
| 71–100 | Brutal | Established brands; do not target as a new site |

Always pair KD with the user's domain rating bucket. A "KD 35" call without
that context is wrong.

## Search intent

Five buckets. Derived from the SERP, not the keyword string.

- **informational** — SERP shows blog posts, guides, Wikipedia, PAA boxes.
- **commercial** — SERP shows listicles ("best X"), comparison pages,
  reviews. The user is researching to buy.
- **transactional** — SERP shows product pages, pricing pages, shopping
  results, "buy" / "free trial" CTAs.
- **navigational** — SERP is dominated by one brand's own pages. The user
  knows what they want.
- **local** — SERP shows a local pack / map.

Mixed-intent SERPs exist. Tag with the dominant intent and add a note.

## SERP features

Surface in the output when present:

- AI Overview (Google's generative answer) — flag because zero-click risk
  rises sharply.
- Featured snippet — flag as an opportunity.
- People Also Ask — mine for adjacent keywords.
- Shopping pack — transactional signal.
- Local pack — local intent.
- Video carousel — YouTube opportunity.
- Sitelinks on every result — navigational, hard to break in.

## Click potential

Volume is not clicks. SERPs with AI Overview + 4 ads + featured snippet leak
70%+ of clicks before position 1. When prioritizing, downgrade keywords with:

- AI Overview present
- 4 paid ads on top
- Featured snippet held by a DR>80 site

## Match types (Google Ads)

| Type | Syntax | When to use |
|------|--------|-------------|
| Exact | `[keyword]` | High-CPC bottom-of-funnel terms; tight control |
| Phrase | `"keyword"` | Mid-funnel commercial; some variation OK |
| Broad | `keyword` | Discovery only; pair with a strong negatives list |

Default to phrase + exact. Broad without negatives burns money.
