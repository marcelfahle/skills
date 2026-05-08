# X API auth setup

Two tokens. The cheap public reads only need (1); bookmarks and private likes need (2).

## 1. App Bearer token (5 minutes)

1. https://developer.x.com → sign in as Marcel.
2. Create a Project + App if missing. Free tier is gone — accept the pay-per-use plan.
3. App settings → "Keys and tokens" → **Bearer Token**. Copy.
4. Set in the gateway env (Albert is the OpenClaw gateway host):

   ```bash
   ssh albert
   echo 'export X_BEARER_TOKEN="..."' >> ~/.profile
   systemctl --user restart openclaw-gateway.service
   ```

5. Smoke-test:

   ```bash
   ./scripts/x-read.sh whois marcelfahle
   ```

   Should print a JSON object with `data.id`. If it 401s, the token is wrong.

## 2. User OAuth 2.0 PKCE token (for bookmarks / private likes)

The bearer token is app-scoped and cannot read user-private resources like
bookmarks. For those you need a user-context token via OAuth 2.0 PKCE.

### Register a redirect URI

In the app's "User authentication settings":
- Type: Web App, Automated App or Bot.
- App permissions: Read.
- Callback URI: `http://localhost:8723/callback` (or any host you control).
- Required scopes: `tweet.read users.read bookmark.read like.read offline.access`.

### One-shot mint (do this once, refresh forever)

```bash
# 1. Generate a PKCE pair.
verifier=$(openssl rand -base64 96 | tr -dc 'A-Za-z0-9' | head -c 96)
challenge=$(printf '%s' "$verifier" | openssl dgst -sha256 -binary | base64 \
            | tr '+/' '-_' | tr -d '=')
client_id="<your_app_client_id>"

# 2. Open this URL in a browser, approve, copy the ?code= param from the redirect.
echo "https://x.com/i/oauth2/authorize?response_type=code&client_id=${client_id}&redirect_uri=http%3A%2F%2Flocalhost%3A8723%2Fcallback&scope=tweet.read%20users.read%20bookmark.read%20like.read%20offline.access&state=local&code_challenge=${challenge}&code_challenge_method=S256"

# 3. Exchange the code for an access + refresh token.
code="<paste here>"
curl -sX POST https://api.x.com/2/oauth2/token \
  -u "${client_id}:" \
  -d "code=${code}" \
  -d "grant_type=authorization_code" \
  -d "redirect_uri=http://localhost:8723/callback" \
  -d "code_verifier=${verifier}" | jq .
```

The response contains `access_token` (2-hour lifetime) and `refresh_token` (long-lived).

### Wire it into the gateway

The script reads `X_USER_OAUTH_TOKEN` directly. Two options:

**Quick & dirty (for V1):** stick the access token in the env and refresh it
manually when it expires:

```bash
echo 'export X_USER_OAUTH_TOKEN="..."' >> ~/.profile
echo 'export X_USER_ID="..."' >> ~/.profile
echo 'export X_REFRESH_TOKEN="..."' >> ~/.profile
```

**Better (V1.5):** add a tiny refresher that swaps in a new access token before each
call when the cached one is older than 100 minutes. Pseudocode:

```bash
refresh() {
  curl -sX POST https://api.x.com/2/oauth2/token \
    -u "${client_id}:" \
    -d "grant_type=refresh_token" \
    -d "refresh_token=${X_REFRESH_TOKEN}" | jq -r .access_token
}
```

Cache the result in `~/.openclaw/secrets/x-user-token` with mtime as the freshness check.

### Scope quick-reference

| Scope | Lets you read |
| --- | --- |
| `tweet.read` | public tweet text and metadata |
| `users.read` | user profile and id lookup |
| `bookmark.read` | the authenticated user's bookmarks |
| `like.read` | the authenticated user's likes (when private) |
| `offline.access` | issues a refresh_token alongside access_token |

Do NOT request `tweet.write`, `like.write`, `bookmark.write`, `follows.write` — this
skill is read-only on purpose, and write scopes increase blast radius if the token
leaks.
