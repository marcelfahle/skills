#!/usr/bin/env bash
# x-read — read-only client for X (Twitter) API v2.
# Usage: x-read.sh <subcommand> [args...]
# Requires: curl, jq. Env: X_BEARER_TOKEN (required for most), X_USER_OAUTH_TOKEN (bookmarks),
# X_USER_ID (optional convenience for "my" reads).

set -euo pipefail

API="https://api.x.com/2"
TWEET_FIELDS="id,text,author_id,created_at,conversation_id,referenced_tweets,public_metrics,lang,entities"
USER_FIELDS="id,name,username,verified,public_metrics"
EXPANSIONS="author_id,referenced_tweets.id,referenced_tweets.id.author_id,attachments.media_keys"
MEDIA_FIELDS="media_key,type,url,preview_image_url,alt_text"

PRETTY=0
MAX_RESULTS=""

die() { printf 'x-read: %s\n' "$1" >&2; exit "${2:-1}"; }

require_token() {
  local var=$1
  if [ -z "${!var:-}" ]; then
    die "missing $var — set it in the gateway environment (see SKILL.md → Prerequisites)" 2
  fi
}

require_bin() {
  command -v "$1" >/dev/null 2>&1 || die "$1 not found on PATH" 2
}

extract_id_from_url() {
  # Accept "https://x.com/u/status/123", "https://twitter.com/u/status/123?s=20", or a bare numeric id.
  local input=$1
  if [[ $input =~ ^[0-9]+$ ]]; then
    printf '%s' "$input"
  elif [[ $input =~ /status/([0-9]+) ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  else
    die "could not extract tweet id from: $input"
  fi
}

api_get() {
  # api_get <path> [query-params...]
  local path=$1; shift || true
  require_token X_BEARER_TOKEN
  local url="$API$path"
  local first=1
  for kv in "$@"; do
    [ -z "$kv" ] && continue
    if [ $first -eq 1 ]; then url+="?$kv"; first=0; else url+="&$kv"; fi
  done
  local body http_code
  body=$(curl -fsSL -w '\n%{http_code}' \
              -H "Authorization: Bearer $X_BEARER_TOKEN" \
              -H "Accept: application/json" \
              "$url" 2>&1) || {
    http_code=$(printf '%s' "$body" | tail -n1)
    die "GET $path failed (HTTP $http_code) — body: $(printf '%s' "$body" | head -n -1 | head -c 500)"
  }
  http_code=$(printf '%s' "$body" | tail -n1)
  body=$(printf '%s' "$body" | head -n -1)
  case "$http_code" in
    2*) ;;
    401) die "401 unauthorized — X_BEARER_TOKEN invalid or revoked" ;;
    403) die "403 forbidden — endpoint not enabled on this app's tier, or account is protected" ;;
    404) die "404 not found — tweet/user does not exist or is deleted" ;;
    429) die "429 rate-limited — back off, do not fall back to scraping (see SKILL.md anti-patterns)" ;;
    *)   die "unexpected HTTP $http_code: $(printf '%s' "$body" | head -c 500)" ;;
  esac
  if [ "$PRETTY" -eq 1 ]; then printf '%s' "$body" | jq .; else printf '%s' "$body"; fi
}

api_get_user_oauth() {
  local path=$1; shift || true
  require_token X_USER_OAUTH_TOKEN
  local url="$API$path"
  local first=1
  for kv in "$@"; do
    [ -z "$kv" ] && continue
    if [ $first -eq 1 ]; then url+="?$kv"; first=0; else url+="&$kv"; fi
  done
  local body http_code
  body=$(curl -fsSL -w '\n%{http_code}' \
              -H "Authorization: Bearer $X_USER_OAUTH_TOKEN" \
              -H "Accept: application/json" \
              "$url" 2>&1) || {
    http_code=$(printf '%s' "$body" | tail -n1)
    die "GET $path (user-oauth) failed (HTTP $http_code) — body: $(printf '%s' "$body" | head -n -1 | head -c 500)"
  }
  http_code=$(printf '%s' "$body" | tail -n1)
  body=$(printf '%s' "$body" | head -n -1)
  case "$http_code" in
    2*) ;;
    401) die "401 unauthorized — X_USER_OAUTH_TOKEN invalid or expired (see references/auth-setup.md)" ;;
    403) die "403 forbidden — token missing required scope (need bookmark.read / like.read / tweet.read)" ;;
    429) die "429 rate-limited" ;;
    *)   die "unexpected HTTP $http_code: $(printf '%s' "$body" | head -c 500)" ;;
  esac
  if [ "$PRETTY" -eq 1 ]; then printf '%s' "$body" | jq .; else printf '%s' "$body"; fi
}

resolve_user_id() {
  # Accept numeric id, @username, or username; return numeric id.
  local input=$1
  input=${input#@}
  if [[ $input =~ ^[0-9]+$ ]]; then printf '%s' "$input"; return; fi
  api_get "/users/by/username/$input" "user.fields=$USER_FIELDS" \
    | jq -r '.data.id // empty' \
    | { read -r id; [ -n "$id" ] || die "user not found: $input"; printf '%s' "$id"; }
}

require_my_id() {
  if [ -n "${X_USER_ID:-}" ]; then printf '%s' "$X_USER_ID"; return; fi
  if [ -n "${X_USER_OAUTH_TOKEN:-}" ]; then
    api_get_user_oauth "/users/me" | jq -r '.data.id'
    return
  fi
  die "X_USER_ID not set and no X_USER_OAUTH_TOKEN to look it up — set X_USER_ID in the gateway env" 2
}

# ---- Subcommands ----

cmd_tweet() {
  local input=${1:-}
  [ -n "$input" ] || die "usage: x-read.sh tweet <url-or-id>"
  local id; id=$(extract_id_from_url "$input")
  api_get "/tweets/$id" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS" \
    "media.fields=$MEDIA_FIELDS"
}

cmd_tweets() {
  local ids=${1:-}
  [ -n "$ids" ] || die "usage: x-read.sh tweets <id1,id2,...>  (max 100)"
  api_get "/tweets" \
    "ids=$ids" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS" \
    "media.fields=$MEDIA_FIELDS"
}

cmd_timeline() {
  local who=${1:-}
  [ -n "$who" ] || die "usage: x-read.sh timeline <username-or-id>"
  local id; id=$(resolve_user_id "$who")
  local max=${MAX_RESULTS:-10}
  api_get "/users/$id/tweets" \
    "max_results=$max" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS"
}

cmd_mentions() {
  local who=${1:-}
  local id
  if [ -n "$who" ]; then id=$(resolve_user_id "$who"); else id=$(require_my_id); fi
  local max=${MAX_RESULTS:-10}
  api_get "/users/$id/mentions" \
    "max_results=$max" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS"
}

cmd_bookmarks() {
  local id; id=$(require_my_id)
  local max=${MAX_RESULTS:-10}
  api_get_user_oauth "/users/$id/bookmarks" \
    "max_results=$max" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS"
}

cmd_likes() {
  local who=${1:-}
  local id
  if [ -n "$who" ]; then id=$(resolve_user_id "$who"); else id=$(require_my_id); fi
  local max=${MAX_RESULTS:-10}
  api_get_user_oauth "/users/$id/liked_tweets" \
    "max_results=$max" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS"
}

cmd_search() {
  local query=${1:-}
  [ -n "$query" ] || die "usage: x-read.sh search '<query>'  (e.g. '\"openclaw\" -is:retweet lang:en')"
  local max=${MAX_RESULTS:-10}
  local encoded; encoded=$(jq -rn --arg q "$query" '$q|@uri')
  api_get "/tweets/search/recent" \
    "query=$encoded" \
    "max_results=$max" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS"
}

cmd_whois() {
  local who=${1:-}
  [ -n "$who" ] || die "usage: x-read.sh whois <username>"
  who=${who#@}
  api_get "/users/by/username/$who" "user.fields=$USER_FIELDS"
}

cmd_thread() {
  local input=${1:-}
  [ -n "$input" ] || die "usage: x-read.sh thread <url-or-id>"
  local id; id=$(extract_id_from_url "$input")

  # 1. Fetch leaf tweet to learn conversation_id and author_id.
  local leaf conv_id author_id
  leaf=$(api_get "/tweets/$id" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS")
  conv_id=$(printf '%s' "$leaf" | jq -r '.data.conversation_id // empty')
  author_id=$(printf '%s' "$leaf" | jq -r '.data.author_id // empty')
  [ -n "$conv_id" ] || die "could not resolve conversation_id for $id"

  # 2. Fetch the conversation root if different from leaf.
  local root="$leaf"
  if [ "$conv_id" != "$id" ]; then
    root=$(api_get "/tweets/$conv_id" \
      "tweet.fields=$TWEET_FIELDS" \
      "expansions=$EXPANSIONS" \
      "user.fields=$USER_FIELDS")
  fi

  # 3. Pull the author's recent posts (cheap on owned reads, 5x cheaper if it's the user themself).
  #    Filter client-side by conversation_id to assemble the thread.
  local timeline
  timeline=$(api_get "/users/$author_id/tweets" \
    "max_results=100" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS") || timeline='{"data":[]}'

  jq -n \
    --argjson root "$root" \
    --argjson leaf "$leaf" \
    --argjson timeline "$timeline" \
    --arg conv_id "$conv_id" '
    {
      conversation_id: $conv_id,
      root: $root.data,
      leaf: $leaf.data,
      thread: ([$root.data, $leaf.data] + ($timeline.data // []))
              | unique_by(.id)
              | map(select(.conversation_id == $conv_id))
              | sort_by(.created_at),
      includes: ($root.includes // {}) * ($leaf.includes // {}) * ($timeline.includes // {})
    }'
}

usage() {
  cat <<'EOF'
x-read — read-only X (Twitter) v2 API client.

Usage:
  x-read.sh [--pretty] [--max N] <subcommand> [args]

Subcommands:
  tweet <url-or-id>          Read a single tweet
  tweets <id1,id2,...>       Read up to 100 tweets in one call
  timeline <user>            User's recent posts (max 100)
  mentions [user]            Mentions of a user (defaults to $X_USER_ID)
  bookmarks                  Your bookmarks (needs X_USER_OAUTH_TOKEN)
  likes [user]               Liked tweets (needs X_USER_OAUTH_TOKEN if private)
  search '<query>'           Recent search (last 7 days)
  whois <username>           Resolve username to user object + id
  thread <url-or-id>         Reconstruct a thread by conversation_id

Flags:
  --pretty   Indented JSON
  --max N    max_results for list endpoints (default 10, cap 100)

Env:
  X_BEARER_TOKEN          required for public reads
  X_USER_OAUTH_TOKEN      required for bookmarks (and private likes)
  X_USER_ID               optional convenience for "my" reads
EOF
}

main() {
  require_bin curl
  require_bin jq

  local args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --pretty)   PRETTY=1; shift ;;
      --max)      MAX_RESULTS=$2; shift 2 ;;
      -h|--help)  usage; exit 0 ;;
      *)          args+=("$1"); shift ;;
    esac
  done
  set -- "${args[@]}"

  local sub=${1:-}
  [ -n "$sub" ] || { usage; exit 1; }
  shift

  case "$sub" in
    tweet)     cmd_tweet "$@" ;;
    tweets)    cmd_tweets "$@" ;;
    timeline)  cmd_timeline "$@" ;;
    mentions)  cmd_mentions "$@" ;;
    bookmarks) cmd_bookmarks "$@" ;;
    likes)     cmd_likes "$@" ;;
    search)    cmd_search "$@" ;;
    whois)     cmd_whois "$@" ;;
    thread)    cmd_thread "$@" ;;
    help|--help) usage ;;
    *) die "unknown subcommand: $sub  (try --help)" ;;
  esac
}

main "$@"
