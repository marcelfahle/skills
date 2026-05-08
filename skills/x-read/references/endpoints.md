# X API v2 endpoint catalog (read-only)

All paths are relative to `https://api.x.com/2`. Every endpoint accepts the standard
`tweet.fields`, `user.fields`, `media.fields`, `expansions`, and pagination
(`max_results`, `pagination_token`) params unless noted.

Costs are pay-per-use as of 2026-04-20. "Owned read" = the resource belongs to the
authenticated user (own posts, own mentions, own bookmarks, etc.).

## Single tweet

`GET /tweets/{id}` — $0.005/read.

Useful expansions:
- `referenced_tweets.id` → full text of the parent in `includes.tweets`.
- `referenced_tweets.id.author_id` → author of the parent.
- `attachments.media_keys` → media in `includes.media`.

## Batch tweets

`GET /tweets?ids=1,2,3,...` — up to 100 ids, billed at $0.005 each. Always cheaper
than N single calls because of HTTP overhead and shared `includes`.

## User timeline

`GET /users/{id}/tweets` — $0.001 if `{id}` is the authenticated user, $0.005 otherwise.
`max_results` 5–100. Returns most-recent-first. Replies and retweets are included
unless excluded via `exclude=retweets,replies`.

## Mentions

`GET /users/{id}/mentions` — $0.001 owned, otherwise $0.005. Same pagination shape.

## Bookmarks

`GET /users/{id}/bookmarks` — $0.001 owned. **Requires user-context OAuth 2.0
token** with scope `bookmark.read` (the app bearer is rejected with 403).

## Liked tweets

`GET /users/{id}/liked_tweets` — $0.001 owned. Requires `like.read` scope when
the account is private; public likes work with the app bearer.

## Recent search

`GET /tweets/search/recent?query=...` — $0.005/read. 7-day window only. Query
syntax: https://developer.x.com/en/docs/x-api/tweets/search/integrate/build-a-query

Quick filter cheatsheet:
- `from:USER` — posts by a user
- `to:USER` — replies to a user
- `-is:retweet` — exclude retweets
- `-is:reply` — top-level posts only
- `lang:en` — language
- `has:links` / `has:media` / `has:images`
- `"exact phrase"` — quoted match

## User lookup

`GET /users/by/username/{username}` — $0.001/read. Returns `data.id` (numeric) and
`data.public_metrics`.

## What we deliberately don't expose

These endpoints exist on v2 but are not in the script — either too expensive,
removed from self-serve, or out-of-scope for read-only:

- `POST /tweets` — $0.20/post, removed from cheap tier.
- `POST /users/{id}/likes`, `POST /users/{id}/following`, `POST /users/{id}/retweets/...`
  — removed from self-serve API entirely (Apr 2026).
- `GET /tweets/search/all` — full-archive, Enterprise tier only.
- `GET /tweets/counts/recent` — possible to add, low value for reading content.
- Streaming / filtered-stream — different consumer pattern, not a fit for an
  agent-tool script.

If the user wants posting back, the right move is the browser tool with a
manually logged-in host browser session, not the API.
