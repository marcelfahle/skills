# Sample output — worked end-to-end

Hypothetical project: a sprint-planning tool called **Sprint Zero**, ICP =
"engineering managers at 20–200-person SaaS companies running Scrum, who
hate planning sessions that drag on for 90 minutes." Numbers below are
illustrative only; real runs always pull live DataForSEO data.

## What the markdown brief looks like

```
# Keyword plan: Sprint Zero

## Snapshot
- ICP: engineering managers at 20–200 dev SaaS, Scrum teams, planning fatigue
- Location / language: 2840 / en
- Source: DataForSEO (search_volume, keyword_suggestions,
  bulk_keyword_difficulty, serp/organic) — pulled 2026-05-08T11:14Z
- Total keywords: 1,247 (412 after dedupe + intent filter)

## Top opportunities (the 10 to act on this week)
| # | Keyword | Vol | KD | CPC | Intent | Parent topic | Why |
|---|---|---|---|---|---|---|---|
| 1 | sprint planning tool | 1,300 | 28 | $14.20 | transactional | Sprint planning tool | Direct product fit; KD reachable for new site |
| 2 | sprint planning template | 2,400 | 22 | $5.10 | informational | Sprint planning template | TOFU magnet → free template → trial |
| 3 | story point estimation | 1,900 | 31 | $7.80 | informational | Story point estimation | Pain quoted in ICP doc; strong content angle |
| 4 | agile estimation tool | 480 | 25 | $11.40 | transactional | Estimation tool | Buyer-intent, low KD |
| 5 | sprint planning meeting | 880 | 19 | $4.20 | informational | Sprint planning meeting | "Meetings drag on" pain — direct quote |
| 6 | best sprint planning software | 320 | 38 | $16.80 | commercial | Comparison | MOFU comparison page opportunity |
| 7 | planning poker online | 1,600 | 26 | $3.40 | transactional | Planning poker | Adjacent feature; product-led growth play |
| 8 | jira sprint planning | 720 | 41 | $6.20 | informational | Integrations | Integration page → "Sprint Zero for Jira" |
| 9 | scrum planning tool | 390 | 24 | $13.10 | transactional | Sprint planning tool | Sibling of #1, easier KD |
| 10 | sprint capacity planning | 260 | 23 | $8.60 | commercial | Capacity planning | ICP-named JTBD: "plan engineering capacity" |

Citation: dataforseo_labs/google/bulk_keyword_difficulty/live + 
keywords_data/google_ads/search_volume/live, location_code=2840,
language_code=en, pulled 2026-05-08T11:14Z

## Cluster: Sprint planning tool (transactional)
Persona: engineering manager. JTBD: "find a faster way to run planning."
Recommended page type: landing page (`/`).

| Keyword | Vol | KD | CPC | Intent | Match type | Notes |
|---|---|---|---|---|---|---|
| sprint planning tool | 1,300 | 28 | $14.20 | transactional | [exact] + "phrase" | Head |
| sprint planning software | 880 | 32 | $13.40 | transactional | [exact] | |
| scrum planning tool | 390 | 24 | $13.10 | transactional | [exact] | Easier KD twin |
| sprint planning app | 210 | 21 | $9.80 | transactional | [exact] | |

## Cluster: Sprint planning template (informational)
Persona: same. JTBD: "stop reinventing the planning agenda."
Recommended page type: blog post + free downloadable template (lead magnet).

| Keyword | Vol | KD | CPC | Intent | Match type | Notes |
|---|---|---|---|---|---|---|
| sprint planning template | 2,400 | 22 | $5.10 | informational | — (not bid) | TOFU magnet |
| sprint planning template excel | 590 | 18 | $3.20 | informational | — | Template variant |
| sprint planning agenda template | 320 | 17 | $4.40 | informational | — | |

(…more clusters…)

## Brand & competitor terms (separate)
| Keyword | Vol | KD | CPC | Intent | Notes |
|---|---|---|---|---|---|
| sprint zero | 720 | 8 | — | navigational (own) | Defensive — bid cheap |
| jira sprint planning | 720 | 41 | $6.20 | informational | Integration play, not direct compete |
| linear vs jira | 1,900 | 44 | $7.80 | commercial | Tangential; deprioritize |

## Negatives (for paid search)
- Account-level: free, download, pdf, meaning, definition, wiki, reddit,
  youtube, tutorial, course, jobs, salary, intern
- Campaign-level — Transactional: template, example, agenda
- Campaign-level — Commercial: open source, github, free trial unlimited

## Gaps observed
- Competitors do not own "sprint capacity planning" or "engineering
  capacity planning." KD < 25 on both; ICP language match is exact.
  Recommend a dedicated landing page + companion blog post.
- "Story point estimation" SERP shows AI Overview present — content
  needs explicit definitional passages + a stat block to be cited.

## Next actions
- This week: build `/sprint-planning-tool` landing page (cluster #1) and
  publish the sprint planning template (cluster #2) gated behind email.
- This week (paid): launch transactional campaign with ad group #1 only,
  exact match, $14 CPC ceiling, $30/day cap.
- Next 2 weeks: ship "Sprint Zero for Jira" integration page (cluster
  #8) and the comparison hub page targeting "best sprint planning
  software" (cluster #6).
```

## What the CSV companion looks like

```
keyword,volume,kd,cpc,intent,parent_topic,cluster_intent,match_type,campaign,ad_group,is_brand,is_competitor_brand,notes
sprint planning tool,1300,28,14.20,transactional,Sprint planning tool,transactional,exact,Sprint Zero — Transactional,Sprint Zero | Transactional: sprint planning tool,false,false,Head
sprint planning software,880,32,13.40,transactional,Sprint planning tool,transactional,exact,Sprint Zero — Transactional,Sprint Zero | Transactional: sprint planning tool,false,false,
scrum planning tool,390,24,13.10,transactional,Sprint planning tool,transactional,exact,Sprint Zero — Transactional,Sprint Zero | Transactional: sprint planning tool,false,false,Easier KD twin
sprint planning template,2400,22,5.10,informational,Sprint planning template,informational,,,,,false,false,TOFU — content only
sprint zero,720,8,,navigational,Brand,brand_own,exact,Sprint Zero — Brand,Sprint Zero | Brand,true,false,Defensive
...
```

## What the file tree looks like after a run

```
keyword-research/
└── sprint-zero/
    ├── 2026-05-08-plan.md          ← the brief above
    ├── 2026-05-08-keywords.csv     ← Ads Editor upload
    └── raw/
        ├── _icp-summary.md
        ├── _seeds.md
        ├── _cost.log
        ├── _calls.log
        └── 2026-05-08/
            ├── search_volume__abc123.json
            ├── keyword_suggestions__def456.json
            ├── bulk_keyword_difficulty__ghi789.json
            └── serp_organic__jkl012.json
```
