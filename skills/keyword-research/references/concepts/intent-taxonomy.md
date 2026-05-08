# Intent taxonomy (derive from SERPs, not strings)

The keyword string lies. "best CRM" looks commercial but its SERP often shows
half informational guides. Always validate intent from the SERP for head
terms before clustering.

## How to derive intent

1. For each head term (top 20–50 keywords by volume), call
   `serp/google/organic/live/advanced`.
2. Look at the **top 10 organic results** + the SERP features.
3. Apply the matrix below. Pick the dominant pattern. If it's a 60/40 split,
   tag the dominant intent and note the secondary in the cluster description.

## Intent matrix

| SERP signal | Intent |
|-------------|--------|
| Wikipedia, .edu, blog posts, "what is" titles, PAA box | informational |
| Listicles ("best", "top 10"), comparison pages, review sites (G2, Capterra) | commercial |
| Product pages, pricing pages, "free trial" / "buy now" CTAs, shopping pack | transactional |
| One brand's own subdomain pages dominate top 5 | navigational |
| Local pack, map, "near me" results | local |

Mixed signals → dominant intent + note. E.g., "email deliverability services"
SERP shows agencies (transactional) but also a Mailchimp guide (informational)
in #4 → tag `transactional` with note `mixed: informational #4`.

## Intent → funnel stage → page type

| Intent | Funnel stage | Page type |
|--------|--------------|-----------|
| informational | TOFU (awareness) | Blog post, guide, glossary entry |
| commercial | MOFU (consideration) | Listicle, comparison, alternatives, vs page |
| transactional | BOFU (decision) | Landing page, pricing page, demo request, product page |
| navigational | BOFU + retention | Brand page, login, docs, support |
| local | BOFU | Location page, "service in [city]" pSEO template |

Use this mapping to recommend the page type in each cluster's table notes.

## Intent for paid search

Paid search inverts the bias: transactional + commercial only, with rare
exceptions.

| Intent | Bid? |
|--------|------|
| transactional | Yes — exact + phrase, top-of-page bid |
| commercial | Yes — phrase, with negatives for "free" / "open source" / "diy" |
| informational | Only if you have a true lead magnet matching the query |
| navigational (own brand) | Yes — defensive, cheap |
| navigational (competitor brand) | Carefully — check ToS + brand-name policies; expect QS penalty |
| local | Yes for local services; pair with location targeting |

## Modifiers that nudge intent

These tokens, when present, shift intent reliably enough to skip the SERP
check for tail terms:

| Modifier | Likely intent |
|----------|---------------|
| "what is", "how to", "guide", "tutorial", "examples" | informational |
| "best", "top", "vs", "alternatives", "review" | commercial |
| "buy", "pricing", "cost", "free trial", "demo", "for sale", "discount" | transactional |
| "[brand name]", "[brand] login", "[brand] docs" | navigational |
| "near me", "[city]", "in [city]" | local |
