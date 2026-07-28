#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SCRIPT="$SCRIPT_DIR/../scripts/x-read.sh"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

cat >"$TEMP_DIR/curl" <<'EOF'
#!/usr/bin/env bash
printf 'curl must not run during plan or approval-gate tests\n' >&2
exit 99
EOF
chmod +x "$TEMP_DIR/curl"

mkdir "$TEMP_DIR/approved"
cat >"$TEMP_DIR/approved/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$CURL_CAPTURE_ARGS"
cat >"$CURL_CAPTURE_CONFIG"
printf '[]'
EOF
chmod +x "$TEMP_DIR/approved/curl"

run_plan() {
  env -u APIFY_TOKEN PATH="$TEMP_DIR:$PATH" "$SCRIPT" \
    --source xquik --plan --max-charge 0.25 "$@"
}

tweet_plan=$(run_plan tweet 1234567890)
jq -e '
  .actor == "xquik~x-tweet-scraper"
  and .actor_url == "https://apify.com/xquik/x-tweet-scraper"
  and .input.mode == "tweet"
  and .input.tweetId == "1234567890"
  and .input.maxItems == 1
  and .max_total_charge_usd == 0.25
' <<<"$tweet_plan" >/dev/null

tweets_plan=$(run_plan tweets 123,456)
jq -e '
  .input.mode == "tweets"
  and .input.tweetIds == ["123", "456"]
  and .input.maxItems == 2
' <<<"$tweets_plan" >/dev/null

timeline_plan=$(run_plan timeline @nasa --max 7)
jq -e '
  .input.mode == "profileTweets"
  and .input.twitterHandles == ["nasa"]
  and .input.maxItems == 7
' <<<"$timeline_plan" >/dev/null

search_plan=$(run_plan search "open source agents" --max 8)
jq -e '
  .input.mode == "search"
  and .input.searchTerms == ["open source agents"]
  and .input.queryType == "Latest + Top"
  and .input.includeSearchTerms == true
  and .input.maxItems == 8
' <<<"$search_plan" >/dev/null

thread_plan=$(run_plan thread https://x.com/example/status/123 --max 9)
jq -e '
  .input.mode == "thread"
  and .input.threadTweetIds == ["123"]
  and .input.maxItems == 9
' <<<"$thread_plan" >/dev/null

followers_plan=$(run_plan followers 44196397 --relation verified_followers --max 6)
jq -e '
  .actor == "xquik~x-follower-scraper"
  and .actor_url == "https://apify.com/xquik/x-follower-scraper"
  and .input.userIds == ["44196397"]
  and .input.relation == "verified_followers"
  and .input.outputMode == "compact"
  and .input.includeTargetMetadata == true
  and .input.dedupeMode == "none"
  and .input.maxItems == 6
' <<<"$followers_plan" >/dev/null

set +e
approval_output=$(env -u APIFY_TOKEN PATH="$TEMP_DIR:$PATH" "$SCRIPT" \
  --source xquik --max-charge 0.25 tweet 123 2>"$TEMP_DIR/approval-error")
approval_status=$?
set -e
[ "$approval_status" -eq 2 ]
jq -e '.input.tweetId == "123"' <<<"$approval_output" >/dev/null
grep -Fq 'add --approve-paid-run' "$TEMP_DIR/approval-error"

set +e
env -u APIFY_TOKEN PATH="$TEMP_DIR:$PATH" "$SCRIPT" \
  --source xquik --plan --max-charge 1e2 tweet 123 \
  >"$TEMP_DIR/invalid-charge-output" 2>"$TEMP_DIR/invalid-charge-error"
invalid_charge_status=$?
set -e
[ "$invalid_charge_status" -eq 2 ]
grep -Fq 'positive decimal number' "$TEMP_DIR/invalid-charge-error"

approved_output=$(env \
  APIFY_TOKEN=test-apify-token \
  CURL_CAPTURE_ARGS="$TEMP_DIR/curl-args" \
  CURL_CAPTURE_CONFIG="$TEMP_DIR/curl-config" \
  PATH="$TEMP_DIR/approved:$PATH" \
  "$SCRIPT" --source xquik --max-charge 0.25 --approve-paid-run tweet 123)
jq -e '
  .data == []
  and .meta.source == "xquik-apify"
  and .meta.actor == "xquik~x-tweet-scraper"
' <<<"$approved_output" >/dev/null
grep -Fq 'Authorization: Bearer test-apify-token' "$TEMP_DIR/curl-config"
grep -Fq 'maxTotalChargeUsd=0.25' "$TEMP_DIR/curl-args"
if grep -Fq 'test-apify-token' "$TEMP_DIR/curl-args"; then
  printf 'credential found in curl arguments\n' >&2
  exit 1
fi

set +e
env -u X_BEARER_TOKEN "$SCRIPT" --source xquik mentions \
  >"$TEMP_DIR/mentions-output" 2>"$TEMP_DIR/mentions-error"
mentions_status=$?
set -e
[ "$mentions_status" -eq 2 ]
grep -Fq 'official API source' "$TEMP_DIR/mentions-error"

set +e
env -u X_BEARER_TOKEN "$SCRIPT" --plan tweet 123 \
  >"$TEMP_DIR/api-plan-output" 2>"$TEMP_DIR/api-plan-error"
api_plan_status=$?
set -e
[ "$api_plan_status" -eq 2 ]
grep -Fq 'require --source xquik' "$TEMP_DIR/api-plan-error"

"$SCRIPT" --help | grep -Fq -- '--source api|xquik'
if grep -Eq '[?&](token|apiKey)=' "$SCRIPT"; then
  printf 'credential found in a query string\n' >&2
  exit 1
fi

printf 'x-read Xquik plan tests passed\n'
