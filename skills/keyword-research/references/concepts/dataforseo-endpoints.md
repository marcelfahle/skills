# DataForSEO access (MCP — preferred, REST — fallback)

DataForSEO is the canonical source for volume / CPC / KD / SERP / backlinks.
Two ways to call it. **Default to the official MCP server.** Drop to REST only
when the MCP is unavailable or when scripting from a non-MCP context (cron,
CI, raw shell).

## Path A: Official DataForSEO MCP (preferred)

Package: [`dataforseo-mcp-server`](https://github.com/dataforseo/mcp-server-typescript) (npm, official, maintained by DataForSEO).

### Register with OpenClaw (one-time)

```bash
openclaw mcp set dataforseo '{
  "command": "npx",
  "args": ["-y", "dataforseo-mcp-server"],
  "env": {
    "DATAFORSEO_USERNAME": "REPLACE_WITH_API_LOGIN",
    "DATAFORSEO_PASSWORD": "REPLACE_WITH_API_PASSWORD",
    "ENABLED_MODULES": "SERP,KEYWORDS_DATA,DATAFORSEO_LABS,BACKLINKS,DOMAIN_ANALYTICS"
  }
}'

openclaw mcp list                      # confirm it's registered
openclaw mcp show dataforseo --json    # confirm shape
```

Notes:
- `DATAFORSEO_USERNAME` / `DATAFORSEO_PASSWORD` are the **API** credentials
  from <https://app.dataforseo.com/api-access>, NOT the dashboard login.
- `ENABLED_MODULES` keeps the tool surface focused on what this skill needs.
  Drop `BACKLINKS` or `DOMAIN_ANALYTICS` if you want a smaller surface.
- Restart the agent / re-open the session after `mcp set` so the tool list
  refreshes.

### Rotating the password (in-place, no re-typing the JSON)

The OpenClaw config schema stores MCP servers under `mcp.servers.<name>`.
To rotate just the password without disturbing the rest of the config:

```bash
jq '.mcp.servers.dataforseo.env.DATAFORSEO_PASSWORD = "NEW_PASSWORD_HERE"' \
  ~/.openclaw/openclaw.json > /tmp/oc.json && mv /tmp/oc.json ~/.openclaw/openclaw.json

openclaw mcp show dataforseo --json   # verify
```

Common footgun: do NOT use `.mcp.dataforseo...` (the schema rejects it
with `Unrecognized key "dataforseo"` on next load). The correct path is
`.mcp.servers.dataforseo.env.DATAFORSEO_PASSWORD`.

### Common MCP tool calls

Tool names follow the DataForSEO endpoint structure. Inspect the live schema
once the server is registered (preferred over copy-paste from docs):

```
# inside the agent
list_tools dataforseo                  # see what's exposed
```

Typical tools you'll use (names may vary by server build — verify with
`list_tools`):

- `keywords_data_google_ads_search_volume_live` — volume + CPC for given
  keywords (THE core call).
- `keywords_data_google_ads_keywords_for_keywords_live` — Google Ads' own
  expansion for paid search.
- `dataforseo_labs_google_keyword_suggestions_live` — long-tail expansion.
- `dataforseo_labs_google_keyword_ideas_live` — broader semantic ideas.
- `dataforseo_labs_google_bulk_keyword_difficulty_live` — KD up to 1000 at
  a time.
- `dataforseo_labs_google_ranked_keywords_live` — what a domain ranks for.
- `dataforseo_labs_google_domain_intersection_live` — true keyword-gap call.
- `dataforseo_labs_google_competitors_domain_live` — discover competitors.
- `dataforseo_labs_google_keywords_for_site_live` — keywords a site should
  rank for; use when the user's domain is too new for `ranked_keywords`.
- `dataforseo_labs_google_domain_rank_overview_live` — competitor sizing.
- `serp_google_organic_live_advanced` — SERP for intent validation.

### Cache MCP responses

The MCP returns JSON. Pipe it to disk on every call:

```
keyword-research/raw/<project>/<YYYY-MM-DD>/<tool-name>__<short-hash>.json
keyword-research/raw/<project>/_calls.log
keyword-research/raw/<project>/_cost.log
```

`_calls.log` line format:
`<ISO ts> <tool> n=<keyword_count> cost=$<n.nnnn> sha=<args-hash>`

Before any new call, grep the cache for the same `(tool, args-hash)`. Reuse
hits unless older than 30 days or the user asks for a refresh.

## Path B: Direct REST (fallback / scripting)

Auth: HTTP Basic with the same API login + password.

```bash
export DATAFORSEO_LOGIN="…"
export DATAFORSEO_PASSWORD="…"

# Smoke test + remaining money
curl -s -u "$DATAFORSEO_LOGIN:$DATAFORSEO_PASSWORD" \
  https://api.dataforseo.com/v3/appendix/user_data \
  | jq '.tasks[0].result[0] | {money: .money, rates: .rates}'
```

Standard call shape — POST a JSON array of tasks (you can batch multiple
tasks per HTTP call):

```bash
curl -s -u "$DATAFORSEO_LOGIN:$DATAFORSEO_PASSWORD" \
  -H "Content-Type: application/json" \
  -d '[{
        "location_code": 2840,
        "language_code": "en",
        "keywords": ["sprint zero", "sprint planning template"]
      }]' \
  https://api.dataforseo.com/v3/keywords_data/google_ads/search_volume/live \
  | tee keyword-research/raw/<project>/$(date -I)/google_ads_search_volume.json \
  | jq '.tasks[].result[] | {keyword, search_volume, cpc, competition_index}'
```

REST endpoint catalog — same data, different transport:

| Purpose | REST path |
|---|---|
| Volume + CPC | `/v3/keywords_data/google_ads/search_volume/live` |
| Google Ads expansion | `/v3/keywords_data/google_ads/keywords_for_keywords/live` |
| Long-tail suggestions | `/v3/dataforseo_labs/google/keyword_suggestions/live` |
| Broad semantic ideas | `/v3/dataforseo_labs/google/keyword_ideas/live` |
| Related keywords | `/v3/dataforseo_labs/google/related_keywords/live` |
| Bulk keyword difficulty | `/v3/dataforseo_labs/google/bulk_keyword_difficulty/live` |
| Domain ranked keywords | `/v3/dataforseo_labs/google/ranked_keywords/live` |
| Domain intersection (gap) | `/v3/dataforseo_labs/google/domain_intersection/live` |
| Competitors discovery | `/v3/dataforseo_labs/google/competitors_domain/live` |
| Keywords for a site | `/v3/dataforseo_labs/google/keywords_for_site/live` |
| Domain overview | `/v3/dataforseo_labs/google/domain_rank_overview/live` |
| SERP (intent + features) | `/v3/serp/google/organic/live/advanced` |

## Location + language codes

- US English: `location_code: 2840, language_code: "en"`
- UK English: `2826 / "en"`
- Germany German: `2276 / "de"`
- Full list: `GET /v3/serp/google/locations` (cache locally; it's stable).

## Cost discipline

- `search_volume/live` ≈ $0.0005 / keyword. 1000 keywords = $0.50. Batch.
- `bulk_keyword_difficulty/live` is the cheapest KD source. Never call the
  per-keyword endpoint.
- SERP calls are the most expensive (~$0.002 each). Run only for head terms
  (top 20–50 per project), not the whole list.
- Always log `.cost` from each response to `_cost.log`.
