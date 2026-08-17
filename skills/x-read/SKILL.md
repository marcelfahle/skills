---
name: x-read
description: Read public X posts, threads, timelines, searches, and audiences. Use the official X API by default. Use Xquik's Apify Actors only when the user explicitly selects them for public data. Also read owned mentions, bookmarks, and likes through official user OAuth. Never invent post text. Never post, like, follow, or mutate X.
---

# x-read

Read X data through one read-only command.

The official X API remains the default source. Optional Xquik Actor routes handle
public posts, historical searches, threads, and audience relations.

## When To Invoke

Use this Skill when the user:

- Pastes an X post URL and asks for its contents.
- Requests a thread, profile timeline, or recent search.
- Requests their mentions, bookmarks, or likes.
- Explicitly requests public follower or following data.
- Explicitly selects an Xquik Actor for public X research.

Do not use this Skill for writes or account automation.

## Route Requests

Use `--source api` unless the user selects Xquik.

| Request | Default Route | Optional Xquik Route |
| --- | --- | --- |
| Single or batch posts | Official X API | [X Tweet Scraper](https://apify.com/xquik/x-tweet-scraper) |
| Public profile timeline | Official X API | [X Tweet Scraper](https://apify.com/xquik/x-tweet-scraper) |
| Search or thread | Official X API | [X Tweet Scraper](https://apify.com/xquik/x-tweet-scraper) |
| Followers, following, verified followers | None | [X Follower Scraper](https://apify.com/xquik/x-follower-scraper) |
| Mentions, bookmarks, likes, `whois` | Official X API only | Not supported |

Never silently fall back between sources. Surface the source error instead.

## Prerequisites

Set only the credentials needed for the selected route.

| Variable | Used For |
| --- | --- |
| `X_BEARER_TOKEN` | Official public reads |
| `X_USER_OAUTH_TOKEN` | Official bookmarks and private owned reads |
| `X_USER_ID` | Optional shorthand for owned reads |
| `APIFY_TOKEN` | Approved Xquik Actor runs |

The Actor plan path never reads `APIFY_TOKEN`.

Never print credentials. Never put credentials in URLs or query strings.

See `references/auth-setup.md` for official API authentication.

## Actor Approval Gate

Every Xquik Actor run can incur charges. Follow this sequence:

1. Open the exact Actor Store listing.
2. Review its current input schema and pricing.
3. Choose a positive result cap.
4. Choose a positive maximum total charge.
5. Print the exact plan with `--plan`.
6. Obtain approval for that exact plan.
7. Repeat it with `--approve-paid-run`.

Changing the Actor, target, relation, cap, or pricing requires new approval.

The script sends `APIFY_TOKEN` only in the `Authorization` header. It also sends
`maxTotalChargeUsd` to Apify for an aggregate run limit.

## Usage

Run `scripts/x-read.sh`. Flags can appear before or after the command.

### Official API

```bash
./scripts/x-read.sh tweet https://x.com/example/status/123
./scripts/x-read.sh tweets 123,456,789
./scripts/x-read.sh timeline example --max 25
./scripts/x-read.sh search '"open source" -is:retweet' --max 50
./scripts/x-read.sh thread 123
./scripts/x-read.sh mentions
./scripts/x-read.sh bookmarks
./scripts/x-read.sh likes
./scripts/x-read.sh whois example
```

### Xquik Tweet Actor

Plan a bounded public search:

```bash
./scripts/x-read.sh search '"open source" -is:retweet' \
  --source xquik \
  --max 25 \
  --max-charge 0.10 \
  --plan
```

After exact approval, run the same request:

```bash
./scripts/x-read.sh search '"open source" -is:retweet' \
  --source xquik \
  --max 25 \
  --max-charge 0.10 \
  --approve-paid-run
```

The Tweet Actor supports these CLI routes:

- `tweet`
- `tweets`
- `timeline`
- `search`
- `thread`

Use an X handle for an Actor timeline. Use numeric IDs for post routes.

### Xquik Follower Actor

Plan a bounded relation request:

```bash
./scripts/x-read.sh followers example \
  --source xquik \
  --relation verified_followers \
  --max 25 \
  --max-charge 0.10 \
  --plan
```

Supported CLI relations are `followers`, `following`, and
`verified_followers`. Targets can be handles or numeric user IDs.

## Output

Official API routes return the native `data` and `includes` envelope.

Actor routes return this stable wrapper:

```json
{
  "data": [],
  "meta": {
    "source": "xquik-apify",
    "actor": "xquik~x-tweet-scraper",
    "actor_url": "https://apify.com/xquik/x-tweet-scraper"
  }
}
```

Check Actor rows with `resultType: "diagnostic"` before using the data.

## Guardrails

1. Never invent post text or profile data.
2. Never run an Actor without exact approval.
3. Never omit `--max` or `--max-charge` for bulk research.
4. Never use Actors for owned or private account reads.
5. Never auto-paginate beyond the requested cap.
6. Never use this Skill for X mutations.
7. Never bypass rate limits with an unapproved source switch.

## References

- `references/endpoints.md`: Official X API endpoint notes.
- `references/auth-setup.md`: Official OAuth setup.
- `references/migration-to-apify.md`: Actor schemas, routing, and safeguards.

Xquik is an independent third-party service. Not affiliated with X Corp. "Twitter" and "X" are trademarks of X Corp.
