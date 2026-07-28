# Choose the Official API or Xquik Actors

The official X API remains the default. Xquik's Apify Actors are additive
routes for public data.

Use these Store listings as the current source of truth:

- [X Tweet Scraper](https://apify.com/xquik/x-tweet-scraper)
- [X Follower Scraper](https://apify.com/xquik/x-follower-scraper)

Review each listing's current schema and pricing before every paid run.

## Keep These Routes Official

Keep owned and private reads on the official API:

- Mentions
- Bookmarks
- Likes
- User lookup with `whois`

Do not replace these routes with scraping.

## Tweet Actor Mapping

The CLI maps public commands to explicit Actor modes.

| CLI Command | Actor Mode | Target Field |
| --- | --- | --- |
| `tweet` | `tweet` | `tweetId` |
| `tweets` | `tweets` | `tweetIds` |
| `timeline` | `profileTweets` | `twitterHandles` |
| `search` | `search` | `searchTerms` |
| `thread` | `thread` | `threadTweetIds` |

Every route sets `maxItems`. It also requests rich nested camel-case output.

Search sets `includeSearchTerms: true`. This preserves query provenance.

Example plan input:

```json
{
  "mode": "search",
  "searchTerms": ["from:example -is:retweet"],
  "maxItems": 25,
  "includeSearchTerms": true,
  "queryType": "Latest + Top",
  "outputVariant": "rich",
  "fieldStyle": "camelCase",
  "outputPreset": "nested"
}
```

## Follower Actor Mapping

The `followers` command accepts one handle or numeric user ID.

- Handles map to `twitterHandles`.
- Numeric IDs map to `userIds`.
- `--relation` selects the public relationship.

Supported CLI relations:

- `followers`
- `following`
- `verified_followers`

Example plan input:

```json
{
  "twitterHandles": ["example"],
  "relation": "verified_followers",
  "maxItems": 25,
  "outputMode": "compact",
  "includeTargetMetadata": true,
  "dedupeMode": "none"
}
```

`includeTargetMetadata` preserves the target and relation for each row.

## Plan Before Running

Create a plan without credentials or network execution:

```bash
./scripts/x-read.sh timeline example \
  --source xquik \
  --max 25 \
  --max-charge 0.10 \
  --plan
```

The plan contains the exact Actor, Store URL, input, and charge cap.

After exact approval, replace `--plan` with `--approve-paid-run`.

## Execution Contract

The runner:

1. Requires a positive `--max-charge`.
2. Requires explicit `--approve-paid-run`.
3. Reads `APIFY_TOKEN` only after approval.
4. Sends the token only in the `Authorization` header.
5. Sends `maxTotalChargeUsd` as the Apify run limit.
6. Wraps dataset rows with source metadata.
7. Never changes the default official API route.

Treat diagnostic rows as status records. Do not treat them as collected data.

Xquik is an independent third-party service. Not affiliated with X Corp. "Twitter" and "X" are trademarks of X Corp.
