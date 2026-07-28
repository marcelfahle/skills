#!/usr/bin/env bash
# x-read - read-only client for the X API and optional Xquik Apify Actors.
# Usage: x-read.sh <subcommand> [args...]
# Requires: curl, jq. Env: X_BEARER_TOKEN (required for most), X_USER_OAUTH_TOKEN (bookmarks),
# X_USER_ID (optional convenience for "my" reads), APIFY_TOKEN (approved Actor runs).

set -euo pipefail

API="https://api.x.com/2"
APIFY_API="https://api.apify.com/v2"
XQUIK_TWEET_ACTOR="xquik~x-tweet-scraper"
XQUIK_FOLLOWER_ACTOR="xquik~x-follower-scraper"
XQUIK_TWEET_URL="https://apify.com/xquik/x-tweet-scraper"
XQUIK_FOLLOWER_URL="https://apify.com/xquik/x-follower-scraper"
TWEET_FIELDS="id,text,author_id,created_at,conversation_id,referenced_tweets,public_metrics,lang,entities"
USER_FIELDS="id,name,username,verified,public_metrics"
EXPANSIONS="author_id,referenced_tweets.id,referenced_tweets.id.author_id,attachments.media_keys"
MEDIA_FIELDS="media_key,type,url,preview_image_url,alt_text"

PRETTY=0
MAX_RESULTS=""
SOURCE="api"
PLAN_ONLY=0
PAID_RUN_APPROVED=0
MAX_TOTAL_CHARGE_USD=""
FOLLOWER_RELATION="followers"

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

print_json() {
  if [ "$PRETTY" -eq 1 ]; then
    jq .
  else
    jq -c .
  fi
}

validate_positive_number() {
  local value=$1 label=$2
  [[ $value =~ ^[0-9]+([.][0-9]+)?$ ]] \
    || die "$label must be a positive decimal number" 2
  jq -en --arg value "$value" '$value | tonumber? | . != null and . > 0' >/dev/null \
    || die "$label must be a positive decimal number" 2
}

validate_max_results() {
  local value=$1
  [[ $value =~ ^[0-9]+$ ]] || die "--max must be an integer from 1 to 100" 2
  [ "$value" -ge 1 ] && [ "$value" -le 100 ] \
    || die "--max must be an integer from 1 to 100" 2
}

apify_run() {
  # apify_run <actor-rest-id> <actor-store-url> <input-json>
  local actor_id=$1 actor_url=$2 input_json=$3
  [ -n "$MAX_TOTAL_CHARGE_USD" ] \
    || die "--max-charge is required for an Xquik Actor request" 2
  validate_positive_number "$MAX_TOTAL_CHARGE_USD" "--max-charge"
  local max_charge
  max_charge=$(jq -nr --arg value "$MAX_TOTAL_CHARGE_USD" '$value | tonumber')

  local plan
  plan=$(jq -cn \
    --arg actor "$actor_id" \
    --arg actor_url "$actor_url" \
    --argjson input "$input_json" \
    --argjson max_charge "$max_charge" \
    '{
      source: "xquik-apify",
      actor: $actor,
      actor_url: $actor_url,
      input: $input,
      max_total_charge_usd: $max_charge
    }')

  if [ "$PLAN_ONLY" -eq 1 ]; then
    printf '%s' "$plan" | print_json
    return
  fi
  if [ "$PAID_RUN_APPROVED" -ne 1 ]; then
    printf '%s' "$plan" | print_json
    die "review current schema, pricing, input, and spend; then add --approve-paid-run" 2
  fi

  require_token APIFY_TOKEN
  local endpoint max_charge_query response
  max_charge_query=$(jq -nr --arg value "$max_charge" '$value | @uri')
  endpoint="$APIFY_API/acts/$actor_id/run-sync-get-dataset-items?maxTotalChargeUsd=$max_charge_query"
  response=$(printf 'header = "Authorization: Bearer %s"\n' "$APIFY_TOKEN" \
    | curl -fsSL --config - --max-time 300 \
      -X POST \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      --data "$input_json" \
      "$endpoint") \
    || die "Xquik Actor request failed; inspect the approved run in Apify" 1

  printf '%s' "$response" \
    | jq -e --arg actor "$actor_id" --arg actor_url "$actor_url" '
        if type != "array" then error("Actor output is not an array")
        else {data: ., meta: {source: "xquik-apify", actor: $actor, actor_url: $actor_url}}
        end
      ' \
    | print_json
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

# ---- Official API subcommands ----

cmd_tweet_api() {
  local input=${1:-}
  [ -n "$input" ] || die "usage: x-read.sh tweet <url-or-id>"
  local id; id=$(extract_id_from_url "$input")
  api_get "/tweets/$id" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS" \
    "media.fields=$MEDIA_FIELDS"
}

cmd_tweets_api() {
  local ids=${1:-}
  [ -n "$ids" ] || die "usage: x-read.sh tweets <id1,id2,...>  (max 100)"
  api_get "/tweets" \
    "ids=$ids" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS" \
    "media.fields=$MEDIA_FIELDS"
}

cmd_timeline_api() {
  local who=${1:-}
  [ -n "$who" ] || die "usage: x-read.sh timeline <username-or-id>"
  local max=${MAX_RESULTS:-10}
  local id; id=$(resolve_user_id "$who")
  api_get "/users/$id/tweets" \
    "max_results=$max" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS"
}

cmd_mentions_api() {
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

cmd_bookmarks_api() {
  local id; id=$(require_my_id)
  local max=${MAX_RESULTS:-10}
  api_get_user_oauth "/users/$id/bookmarks" \
    "max_results=$max" \
    "tweet.fields=$TWEET_FIELDS" \
    "expansions=$EXPANSIONS" \
    "user.fields=$USER_FIELDS"
}

cmd_likes_api() {
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

cmd_search_api() {
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

cmd_whois_api() {
  local who=${1:-}
  [ -n "$who" ] || die "usage: x-read.sh whois <username>"
  who=${who#@}
  api_get "/users/by/username/$who" "user.fields=$USER_FIELDS"
}

cmd_thread_api() {
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

# ---- Xquik Actor subcommands ----

cmd_tweet_xquik() {
  local input=${1:-}
  [ -n "$input" ] || die "usage: x-read.sh tweet <url-or-id>"
  local id; id=$(extract_id_from_url "$input")
  local actor_input
  actor_input=$(jq -cn --arg id "$id" '{
    mode: "tweet",
    tweetId: $id,
    maxItems: 1,
    outputVariant: "rich",
    fieldStyle: "camelCase",
    outputPreset: "nested"
  }')
  apify_run "$XQUIK_TWEET_ACTOR" "$XQUIK_TWEET_URL" "$actor_input"
}

cmd_tweets_xquik() {
  local ids=${1:-}
  [ -n "$ids" ] || die "usage: x-read.sh tweets <id1,id2,...>  (max 100)"
  local actor_input
  actor_input=$(jq -cn --arg ids "$ids" '
    ($ids | split(",") | map(gsub("^\\s+|\\s+$"; ""))) as $tweet_ids
    | if ($tweet_ids | length) < 1
        or ($tweet_ids | length) > 100
        or any($tweet_ids[]; test("^[0-9]+$") | not)
      then error("tweets needs 1 to 100 comma-separated numeric IDs")
      else {
        mode: "tweets",
        tweetIds: $tweet_ids,
        maxItems: ($tweet_ids | length),
        outputVariant: "rich",
        fieldStyle: "camelCase",
        outputPreset: "nested"
      }
      end
  ') || die "tweets needs 1 to 100 comma-separated numeric IDs" 2
  apify_run "$XQUIK_TWEET_ACTOR" "$XQUIK_TWEET_URL" "$actor_input"
}

cmd_timeline_xquik() {
  local handle=${1:-}
  [ -n "$handle" ] || die "usage: x-read.sh timeline <username>"
  handle=${handle#@}
  [[ $handle =~ ^[A-Za-z0-9_]{1,15}$ ]] \
    || die "Xquik timeline needs an X handle, not a numeric user ID or URL" 2
  local max=${MAX_RESULTS:-10}
  local actor_input
  actor_input=$(jq -cn --arg handle "$handle" --argjson max "$max" '{
    mode: "profileTweets",
    twitterHandles: [$handle],
    maxItems: $max,
    outputVariant: "rich",
    fieldStyle: "camelCase",
    outputPreset: "nested"
  }')
  apify_run "$XQUIK_TWEET_ACTOR" "$XQUIK_TWEET_URL" "$actor_input"
}

cmd_search_xquik() {
  local query=${1:-}
  [ -n "$query" ] || die "usage: x-read.sh search '<query>'"
  local max=${MAX_RESULTS:-10}
  local actor_input
  actor_input=$(jq -cn --arg query "$query" --argjson max "$max" '{
    mode: "search",
    searchTerms: [$query],
    maxItems: $max,
    includeSearchTerms: true,
    queryType: "Latest + Top",
    outputVariant: "rich",
    fieldStyle: "camelCase",
    outputPreset: "nested"
  }')
  apify_run "$XQUIK_TWEET_ACTOR" "$XQUIK_TWEET_URL" "$actor_input"
}

cmd_thread_xquik() {
  local input=${1:-}
  [ -n "$input" ] || die "usage: x-read.sh thread <url-or-id>"
  local id; id=$(extract_id_from_url "$input")
  local max=${MAX_RESULTS:-100}
  local actor_input
  actor_input=$(jq -cn --arg id "$id" --argjson max "$max" '{
    mode: "thread",
    threadTweetIds: [$id],
    maxItems: $max,
    outputVariant: "rich",
    fieldStyle: "camelCase",
    outputPreset: "nested"
  }')
  apify_run "$XQUIK_TWEET_ACTOR" "$XQUIK_TWEET_URL" "$actor_input"
}

cmd_followers_xquik() {
  local target=${1:-}
  [ -n "$target" ] || die "usage: x-read.sh followers <username-or-id>" 2
  case "$FOLLOWER_RELATION" in
    followers|following|verified_followers) ;;
    *) die "--relation must be followers, following, or verified_followers" 2 ;;
  esac

  local max=${MAX_RESULTS:-10}
  local target_field target_value
  if [[ $target =~ ^[0-9]+$ ]]; then
    target_field="userIds"
    target_value=$target
  else
    target_value=${target#@}
    [[ $target_value =~ ^[A-Za-z0-9_]{1,15}$ ]] \
      || die "followers needs an X handle or numeric user ID" 2
    target_field="twitterHandles"
  fi

  local actor_input
  actor_input=$(jq -cn \
    --arg target_field "$target_field" \
    --arg target "$target_value" \
    --arg relation "$FOLLOWER_RELATION" \
    --argjson max "$max" \
    '{
      relation: $relation,
      maxItems: $max,
      outputMode: "compact",
      includeTargetMetadata: true,
      dedupeMode: "none"
    } + {($target_field): [$target]}')
  apify_run "$XQUIK_FOLLOWER_ACTOR" "$XQUIK_FOLLOWER_URL" "$actor_input"
}

# ---- Source routing ----

dispatch_api() {
  local command=$1
  shift
  case "$command" in
    tweet)     cmd_tweet_api "$@" ;;
    tweets)    cmd_tweets_api "$@" ;;
    timeline)  cmd_timeline_api "$@" ;;
    mentions)  cmd_mentions_api "$@" ;;
    bookmarks) cmd_bookmarks_api "$@" ;;
    likes)     cmd_likes_api "$@" ;;
    search)    cmd_search_api "$@" ;;
    whois)     cmd_whois_api "$@" ;;
    thread)    cmd_thread_api "$@" ;;
    followers) die "followers requires --source xquik" 2 ;;
    help|--help) usage ;;
    *) die "unknown subcommand: $command  (try --help)" ;;
  esac
}

dispatch_xquik() {
  local command=$1
  shift
  case "$command" in
    tweet)     cmd_tweet_xquik "$@" ;;
    tweets)    cmd_tweets_xquik "$@" ;;
    timeline)  cmd_timeline_xquik "$@" ;;
    search)    cmd_search_xquik "$@" ;;
    thread)    cmd_thread_xquik "$@" ;;
    followers) cmd_followers_xquik "$@" ;;
    mentions|bookmarks|likes|whois)
      die "$command is available only through the official API source" 2
      ;;
    help|--help) usage ;;
    *) die "unknown subcommand: $command  (try --help)" ;;
  esac
}

usage() {
  cat <<'EOF'
x-read - read-only X data client.

Usage:
  x-read.sh [flags] <subcommand> [args]

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
  followers <user>           Read followers, following, or verified followers

Flags:
  --source api|xquik       Data source (default: api)
  --pretty                 Indented JSON
  --max N                  Result cap (default 10, range 1 to 100)
  --relation RELATION      followers, following, or verified_followers
  --max-charge USD         Required Apify maximum total charge
  --plan                   Print an Xquik Actor plan without running it
  --approve-paid-run       Approve the exact displayed paid Actor request

Env:
  X_BEARER_TOKEN          required for public reads
  X_USER_OAUTH_TOKEN      required for bookmarks (and private likes)
  X_USER_ID               optional convenience for "my" reads
  APIFY_TOKEN             required only for an approved Xquik Actor run

Xquik is an independent third-party service. Not affiliated with X Corp. "Twitter" and "X" are trademarks of X Corp.
EOF
}

main() {
  require_bin curl
  require_bin jq

  local args=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --pretty)
        PRETTY=1
        shift
        ;;
      --max)
        [ -n "${2:-}" ] || die "--max needs a value" 2
        MAX_RESULTS=$2
        shift 2
        ;;
      --source)
        [ -n "${2:-}" ] || die "--source needs api or xquik" 2
        SOURCE=$2
        shift 2
        ;;
      --relation)
        [ -n "${2:-}" ] || die "--relation needs a value" 2
        FOLLOWER_RELATION=$2
        shift 2
        ;;
      --max-charge)
        [ -n "${2:-}" ] || die "--max-charge needs a USD value" 2
        MAX_TOTAL_CHARGE_USD=$2
        shift 2
        ;;
      --plan)
        PLAN_ONLY=1
        shift
        ;;
      --approve-paid-run)
        PAID_RUN_APPROVED=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done
  set -- "${args[@]}"

  case "$SOURCE" in
    api|xquik) ;;
    *) die "--source must be api or xquik" 2 ;;
  esac
  if [ "$SOURCE" = "api" ] \
    && { [ "$PLAN_ONLY" -eq 1 ] \
      || [ "$PAID_RUN_APPROVED" -eq 1 ] \
      || [ -n "$MAX_TOTAL_CHARGE_USD" ]; }; then
    die "--plan, --approve-paid-run, and --max-charge require --source xquik" 2
  fi
  if [ -n "$MAX_RESULTS" ]; then
    validate_max_results "$MAX_RESULTS"
  fi

  local sub=${1:-}
  [ -n "$sub" ] || { usage; exit 1; }
  shift

  case "$SOURCE" in
    api) dispatch_api "$sub" "$@" ;;
    xquik) dispatch_xquik "$sub" "$@" ;;
  esac
}

main "$@"
