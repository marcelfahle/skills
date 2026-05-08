---
name: x-read
description: Read tweets, threads, user timelines, mentions, bookmarks, likes, and search results from X (Twitter) via the official X API v2. Use when the user asks "what's in this tweet", "summarize this thread", "show my mentions / bookmarks", "what did <user> tweet about", "what's trending on X about <topic>", or pastes an x.com / twitter.com URL and wants the contents. Owned reads (the user's own posts, mentions, bookmarks, likes, followers, lists) cost $0.001 per resource since 2026-04-20; arbitrary tweet reads are $0.005. The skill never invents tweet text — every output is the literal API response or `null` when the API has no data. Does NOT post, like, follow, or mutate state — read-only.
---

# x-read — Read tweets via X API v2

Read-only client for the X (Twitter) v2 API. V1 wraps the eight most useful read endpoints behind a single bash script so any agent can paste a URL and get the tweet, fetch a user's timeline, check mentions, dump bookmarks, or run a recent-search.

Posting, liking, following, and quote-posting are intentionally out of scope — those endpoints were removed from self-serve in April 2026 and require enterprise tier. Posting via API is also $0.20/post which is not worth it.

## When to invoke

Trigger this skill when the user:

- Pastes an `x.com/<user>/status/<id>` or `twitter.com/...` URL and wants the contents.
- Asks "what's in this tweet", "summarize this thread", "what did X say".
- Asks for their own mentions, bookmarks, liked tweets, or recent posts.
- Asks "what's a user tweeting about lately" or "show me <user>'s timeline".
- Asks for a recent-search ("tweets about <topic> from this week").

Skip and use the browser/headless path only if the user explicitly wants screenshots, the tweet is age-gated, or the API returns 403 (protected account).

## Prerequisites — secrets the operator must set

Set in the gateway environment (per OpenClaw env conventions):

| Variable | Required for | How to get it |
| --- | --- | --- |
| `X_BEARER_TOKEN` | All public reads (tweet by id, timelines, mentions, search) | https://developer.x.com — Project → App → "Bearer Token". Pay-per-use plan, no flat tier. |
| `X_USER_OAUTH_TOKEN` | Owned reads that need user context (bookmarks, liked_tweets when private) | OAuth 2.0 PKCE user token with `bookmark.read tweet.read users.read like.read` scopes. |
| `X_USER_ID` | Convenience — let the user say "my mentions" without re-typing the numeric id | `curl -H "Authorization: Bearer $X_USER_OAUTH_TOKEN" https://api.x.com/2/users/me \| jq -r .data.id` |

If any required token is missing, the script exits with code `2` and a clear `missing X_BEARER_TOKEN` message. Do NOT fall back to scraping or guessing — surface the missing-secret error to the user verbatim and stop.

## Cost model (as of 2026-04-20)

| Endpoint | Per call | Notes |
| --- | --- | --- |
| `GET /2/tweets/{id}` (someone else's) | $0.005 | "Read" billing tier |
| `GET /2/users/{me}/tweets` (own timeline) | $0.001 | "Owned read" tier — 5× cheaper |
| `GET /2/users/{me}/mentions` | $0.001 | Owned read |
| `GET /2/users/{me}/bookmarks` | $0.001 | Owned read; needs OAuth user token |
| `GET /2/users/{me}/liked_tweets` | $0.001 | Owned read |
| `GET /2/tweets/search/recent` | $0.005 | 7-day window only; use Apify for historical |

Hard cap: 2,000,000 post-reads/month before Enterprise tier. The script does NOT auto-batch or auto-paginate beyond `max_results` (default 10) — the agent must explicitly request more.

## Usage

The skill ships a single bash entrypoint: `scripts/x-read.sh`. All commands print JSON (`--pretty` for indented). Pipe through `jq` for shaping.

```bash
# Single tweet (URL or id)
./scripts/x-read.sh tweet https://x.com/elonmusk/status/1234567890
./scripts/x-read.sh tweet 1234567890

# Multiple tweets in one call (cheaper)
./scripts/x-read.sh tweets 1234567890,1234567891,1234567892

# A user's recent posts
./scripts/x-read.sh timeline elonmusk          # by username
./scripts/x-read.sh timeline 44196397 --max 25 # by numeric id

# My mentions / bookmarks / likes (uses X_USER_ID)
./scripts/x-read.sh mentions
./scripts/x-read.sh bookmarks
./scripts/x-read.sh likes

# Recent search (last 7 days)
./scripts/x-read.sh search '"openclaw" -is:retweet lang:en' --max 50

# Resolve a username -> numeric id (handy + cheap)
./scripts/x-read.sh whois marcelfahle
```

Output is the raw `data`/`includes` envelope from the X API. Agents should parse `.data[].text`, `.includes.users[]`, `.includes.tweets[]` (for thread context) directly.

## Reading a thread

X v2 doesn't have a "give me this thread" endpoint. The script's `thread <id>` subcommand:

1. Fetches the leaf tweet with `expansions=referenced_tweets.id,author_id`.
2. Walks `referenced_tweets[type=replied_to]` upward until it hits a root.
3. Then fetches the author's recent posts and stitches forward replies that share `conversation_id`.

This costs ~3–6 reads for a typical thread. For deeper threads, prefer Apify (V2 plan).

## Anti-patterns (do NOT do)

1. **Never invent tweet text.** If the API returns 404 or `errors[]`, surface the error verbatim. No paraphrasing from training data.
2. **Never log the bearer token.** The script masks tokens in error output; agents must not echo `$X_BEARER_TOKEN` to the user or to logs.
3. **Don't auto-paginate past `max_results=100`.** That burns the monthly cap fast. Ask the user to confirm before fetching > 100 tweets.
4. **Don't use this for posting, liking, following, retweeting, or quote-posting.** Those endpoints aren't included on purpose.
5. **Don't fall back to scraping x.com via the browser tool when an API call fails with rate-limit (429).** Honor the rate limit and tell the user.

## Reference index

- `references/endpoints.md` — Full endpoint catalog (URL, params, fields, costs).
- `references/auth-setup.md` — Step-by-step OAuth 2.0 PKCE flow to mint the user token for bookmarks.
- `references/migration-to-apify.md` — When and how to switch this skill to the Apify "Cheap & Simple X" actor for bulk/historical (~$0.00046/tweet).

## Roadmap

- **V1 (this):** read-only, X API v2 official, bearer + optional user OAuth token.
- **V2:** Apify backend behind the same CLI surface for bulk/historical reads at ~20× cheaper per tweet.
- **V3:** thread reconstruction via Grok's free conversation expansion (when/if available on the public API).
