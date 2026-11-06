---
name: video-teardown
description: Pull a video apart — download, transcribe, grab frames, and write a structured breakdown to the vault. Works on X/Twitter, YouTube, TikTok, Instagram, Loom (public share links), direct mp4 URLs, and local video files. Use when Marcel pastes a video link and says "pull this apart", "break this video down", "what's in this video", "tear down this demo", "watch this Loom", "what can we learn from this", or "what features does this product have". Two lenses: `content` (why a social video works — hook, structure, format, outlier ratio, what to reuse) and `demo` (product demo / Loom — timestamped feature inventory with frame evidence, UX patterns, ideas). Read-only; never posts anything.
metadata:
  {
    "openclaw": { "emoji": "🔬" }
  }
---

# video-teardown

One script produces the raw materials; you (the agent) write the breakdown from them. Never write a breakdown from memory or from the post text alone. Every claim cites a transcript timestamp or a frame.

## 1. Run the script

```bash
~/openclaw/skills/video-teardown/scripts/teardown.py "<url-or-file>" [--mode auto|short|demo] [--language en]
```

- `--mode auto` (default): `short` for social URLs (x/tiktok/instagram/shorts) or videos up to 3 min; `demo` for anything longer (Loom, YouTube long-form, screen recordings).
  - `short`: evenly spaced frames (24 by default) in 4×2 grids at 480 px per cell.
  - `demo`: scene-change detection (catches UI and slide changes in screen recordings) plus a coverage floor. Up to 90 frames at 1280 px, in 3×2 grids at 640 px per cell, so UI text stays readable.
- Tuning: `--max-frames N`, `--interval SEC`, `--scene 0.08` (lower = more frames for subtle UI changes), `--force` (re-extract frames only).
- Idempotent: re-runs reuse the download and transcript. Prints `summary.json` to stdout. The `asset_dir` field is where everything landed (default `~/.openclaw/workspace/research/teardowns/<date>-<slug>/`).
- **Don't run it to "check usage".** Use `-h`, which exits without fetching anything.

**Cost:** Whisper costs $0.006/min ($0.06 for a 10-min clip, about $0.36 for an hour-long Loom), plus $0.005 for the X metrics read on x.com URLs. Put the `cost_estimate_usd` in the delivery line. Runtime is about 45 s for 10 min and about 2 min for 30 min.

**Exit codes:** `2` = usage error or missing `OPENAI_API_KEY`. `3` = download failed. `4` = Whisper failed. Surface the message verbatim.

### Loom specifics

- Public share links (`loom.com/share/<id>`) work directly.
- Private, password-protected, or workspace-restricted Looms fail with exit 3. Ask Marcel to hit Download in Loom and drop the mp4 on Albert (or any direct URL). Then run the script on the **file path**; local files are supported.

## 2. Read the materials (file-output discipline)

- `summary.json`, `meta.json`: title, duration, uploader. For X: `x_post.metrics`, `author_followers`, `impressions_per_follower`.
- `transcript.txt`: `[m:ss] text` lines. For long videos (>30 min / >5k words), read it in chunks with offset/limit; don't slurp it into one turn.
- `sheets/sNN.jpg`: view these images to skim visually. `frames.tsv` maps each sheet cell to its exact timestamp and full-res frame (`frames/t_0h12m34s.jpg`). Open the full-res frame when you need to read UI detail.
- Don't paste the transcript into chat or into the vault note. Quote short lines only.

## 3. Write the breakdown

Write it to the vault, then send Marcel a short summary plus the note path.

| Lens | Vault path |
|---|---|
| `content` | `obsidian/_WORK/Social/Teardowns/YYYY-MM-DD <author> - <short title>.md` |
| `demo` (product) | `obsidian/_WORK/Bold Video/Research/Teardowns/YYYY-MM-DD <product> demo.md` if Marcel framed it for Bold, otherwise `obsidian/_WORK/Research/Teardowns/` |

The raw assets (video, frames) stay in `asset_dir`. **Never copy video or frame files into the vault** (sync bloat). Link to `asset_dir` in the note's frontmatter instead.

Frontmatter (both lenses):

```yaml
source: <url>
author: <uploader>
duration: <m:ss>
lens: content | demo
assets: <asset_dir>
cost_usd: <cost_estimate_usd>
date: YYYY-MM-DD
```

### Lens `content` (social video): sections

1. **TL;DR**: 2–3 lines on what it is and why it worked.
2. **Performance**: raw metrics + `impressions_per_follower` (outlier ratio; >10× = the video did it, not the audience). Note save/like ratio when available (bookmarks > likes = reference content).
3. **Hook**: first 3–8 s verbatim, and what kind of hook (credential, contrarian, promise, curiosity gap).
4. **Structure**: timestamped beats.
5. **Format**: the reusable container (e.g. "slides + facecam explainer", "$1 vs $X comparison", "challenge quiz"). Name it so it can become a format-library card.
6. **Core ideas**: the substance, with timestamps.
7. **Claims to verify**: every self-reported number, flagged as unverified.
8. **What we could reuse**: concrete, not generic.

### Lens `demo` (product demo / Loom): sections

1. **TL;DR**: what the product is and the 3 most interesting things in it.
2. **Feature inventory**: a table with `timestamp | feature | what it does | frame` (link the `frames/…jpg` filename). Be exhaustive; the point is that Marcel can jump to 14:32 and see it.
3. **UX patterns worth noting**: interaction details, empty states, onboarding, AI touches, pricing/plan gates seen on screen.
4. **Open questions**: things shown but not explained.
5. **Ideas for Bold**: only when Marcel framed the request for Bold (or another project). Otherwise stay neutral, per the research scope rule. When it's in scope, read `_WORK/Bold Video/Roadmap.md` and `Positioning.md` first and map each idea to what exists versus what's new.

## Don'ts

- Don't invent what's on screen. If a frame is unreadable, say so or open the full-res frame.
- Don't treat creator claims as facts ("70M views in 10 videos" stays *claimed*).
- Don't re-run with `--force` just to re-read; the materials are already on disk.
- Don't download private videos with cookies or by logging in on someone's behalf. Ask Marcel for the file instead.
