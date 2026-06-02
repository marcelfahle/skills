---
name: linkedin-archive
description: Archive Marcel's recent LinkedIn posts into the Obsidian vault as weekly markdown files matching the social-corpus format. Use when Marcel says "archive my LinkedIn", "pull my LinkedIn", "/linkedin-archive", "update the social corpus", or "what did I post on LinkedIn this week — and capture it". Runs as a Claude cowork skill on Marcel's own machine (logged-in browser session); does NOT run on the gateway VM. Companion to the Twitter side (`~/.openclaw/bin/social-archive-x.mjs`, auto-cron Sat 21:00 Madrid) which uses the X API and runs unattended. LinkedIn API doesn't allow own-timeline reads at consumer tier, so this is intentionally manual/assisted.
---

# linkedin-archive

Capture LinkedIn posts into the Obsidian vault for the social-media-calendar corpus. Weekly files at `_WORK/Social/linkedin/YYYY-WXX.md` mirror the Twitter side so Merrick can read both as one source when planning content.

This skill runs in **Claude cowork** on Marcel's laptop — i.e. a Claude instance with browser tools and direct access to the synced Obsidian vault on disk. It does NOT run on the gateway VM (Albert). The OpenClaw side reads the vault but does not write to it from this skill.

## When to invoke

Trigger when Marcel says:
- "archive my LinkedIn" / "pull my LinkedIn"
- "/linkedin-archive"
- "update the social corpus" (LinkedIn half — pair with the Twitter cron status)
- "what did I post on LinkedIn this week" + any "and capture it" framing
- "catch up the LinkedIn archive" (backfill mode)

Do NOT trigger when:
- The request is about drafting *new* LinkedIn posts → that's a content task, not archiving.
- The request is about *competitors'* LinkedIn → use `linkedin-research` (Apify-based) instead.

## Vault layout (read first, don't re-derive)

```
<vault-root>/_WORK/Social/
├── linkedin/
│   └── YYYY-WXX.md       # ISO-week, this skill writes here
└── twitter/
    └── YYYY-WXX.md       # ISO-week, written by the X API cron — read-only for this skill
```

Find `<vault-root>` once per session: it's the Obsidian vault folder that contains `_WORK/`. On Marcel's Mac it's typically `~/obsidian/mf/` (matches the gateway VM path). If unsure, ask once, then remember for the rest of the session.

## File format (match exactly)

Each weekly file:

```markdown
---
source: linkedin
profile: https://www.linkedin.com/in/marcelfahle/
week: YYYY-WXX
---

# LinkedIn — YYYY Week NN

## YYYY-MM-DD — Title (first clause, ≤70 chars)
Reactions: N · Comments: N · Reposts: N
[View post](https://www.linkedin.com/feed/update/urn:li:activity:NNNNNNNNNNNNNNNNNNN/)

<full post text, preserving paragraph breaks>

<!-- id:NNNNNNNNNNNNNNNNNNN -->

---
```

Rules:
- `id` = the numeric portion of `urn:li:activity:NNNN…`. Stable across renames.
- ISO week of `YYYY-MM-DD` (Mon–Sun, year-of-Thursday) decides which file an entry lands in.
- Order entries newest-first inside each week file.
- Preserve emoji, line breaks, and link text exactly as posted. Don't summarize or paraphrase the body.
- For shared/reposted/comment-only items: still capture if Marcel authored the comment; mark `Type: Comment on @<author>'s post` and quote the parent in a `>` blockquote, mirroring the Twitter side's reply context.

## Workflow

### Step 1 — Pick a mode

**Mode A: Browser scrape (default if cowork has a working browser tool).**
1. Open `https://www.linkedin.com/in/marcelfahle/recent-activity/all/`.
2. Scroll until the earliest visible post is older than the most recent `<!-- id:… -->` marker already present across the linkedin/ weekly files (find that marker first to know where to stop).
3. For each visible activity card, extract:
   - `activity_id` (from the `data-urn` attribute or the "Copy link to post" menu — `urn:li:activity:NNN`)
   - `posted_at` (the relative date on the card — resolve to absolute YYYY-MM-DD using today as anchor)
   - `text` (full body — expand "see more" before extracting)
   - `reactions`, `comments`, `reposts` (footer counters; treat blank as 0)
   - Post URL: `https://www.linkedin.com/feed/update/urn:li:activity:NNN/`
4. Skip cards Marcel didn't author (likes/saves of others). Keep comments Marcel wrote on others' posts — they're part of his voice.

**Mode B: Paste mode (use if browser scrape is blocked or rate-limited).**
1. Ask Marcel to scroll to his recent activity and paste a chunk (multiple posts) of the page text.
2. Parse the paste for activity blocks. LinkedIn's copy-paste leaves the same fields recognizable: byline, relative date, body, reaction counts.
3. For activity IDs, Marcel can right-click → "Copy link to post" per item; ask for a small batch of links once you've parsed the bodies so you can fill in the `id` and URL fields.

### Step 2 — Dedup against existing files

For every candidate post:
1. Read the target week file (compute it from `posted_at`).
2. If the file already contains `<!-- id:<this-id> -->`, skip.
3. Otherwise, insert the new entry **newest-first** (above existing entries in that week's H2 stream, after the frontmatter + H1).

If the week file doesn't exist, create it with the frontmatter + H1 header shown above, then add the entry.

### Step 3 — Write to disk

Write the markdown files directly to `<vault-root>/_WORK/Social/linkedin/YYYY-WXX.md`. Obsidian Sync will push to the gateway VM where Merrick can read it.

### Step 4 — Report back

End with a short summary in this shape (≤6 lines), so Marcel can spot misses:

```
LinkedIn archive: <total new> posts added across <N> weeks
  YYYY-WXX: +N (top: <title>, eng=R/C/R)
  YYYY-WYY: +N
Vault: <vault-root>/_WORK/Social/linkedin/
```

## Anti-patterns

1. **Never invent post text, dates, or engagement numbers.** If a field is missing from the source page or paste, leave it blank rather than guess. Engagement counts are a known LinkedIn-UI hide pattern at low values — `0` is fine, made-up `2` is not.
2. **Never overwrite an existing entry.** Idempotency depends on the `<!-- id:N -->` markers. If you spot a wrong entry, fix it in place; do not delete + re-add.
3. **Never publish, edit, or react to LinkedIn posts from this skill.** Read-only.
4. **Don't write to `_WORK/Social/twitter/`** — that side is owned by the X API cron on the gateway. Crossing the lane will fight the dedup on that side.
5. **Don't summarize the body.** The corpus is for Merrick to read Marcel's actual voice; paraphrase ≠ voice sample.
6. **Don't fall through to `linkedin-research`.** That skill is for *other people's* LinkedIn (competitors, prospects), not Marcel's own archive.

## Cadence

- Marcel triggers this manually, typically weekly (Saturday or Sunday), to keep parity with the Twitter cron.
- A future companion (`scripts/linkedin-archive.mjs`) could be added if Marcel decides to let cowork drive Playwright on a schedule. Not built yet — LinkedIn's anti-automation makes the manual trigger less brittle.

## Reference

- Sibling skill: `skills/x-read/` (X API, read-only).
- Sibling automation: `~/.openclaw/bin/social-archive-x.mjs` on the gateway (auto Sat 21:00 Madrid).
- Project context: `_WORK/Social/` is the social-media calendar corpus; both halves feed Merrick's content planning. See `project_social_corpus.md` in the gateway memory.
