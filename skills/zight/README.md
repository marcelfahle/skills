# Zight Skill for Claude Code

Automatically analyze [Zight](https://zight.com) screenshots and screen recordings inside Claude Code. When a `share.zight.com` link appears — in a ticket, a message, or a bug report — this skill fetches the content, extracts frames, transcribes audio, and produces a structured analysis.

**Images** are downloaded and analyzed visually with zero dependencies.

**Screen recordings** are downloaded, split into frames with ffmpeg, transcribed with whisper-cpp, and correlated into a timestamped summary of what the user sees and says.

## Install

```bash
npx skills add marcelfahle/zight-skill
```

Or manually copy the skill files into your project or global skills directory:

```bash
# Project-level
cp -r . .claude/skills/zight/

# Global (all projects)
cp -r . ~/.claude/skills/zight/
```

## Dependencies

**Image analysis** works out of the box — no extra dependencies needed.

**Video analysis** requires:

| Tool | Install | Purpose |
|------|---------|---------|
| [ffmpeg](https://ffmpeg.org) | `brew install ffmpeg` | Frame extraction, audio conversion |
| [whisper-cpp](https://github.com/ggerganov/whisper.cpp) | `brew install whisper-cpp` | Audio transcription |

After installing whisper-cpp, download the English base model:

```bash
mkdir -p ~/.local/share/whisper-cpp/models
curl -L -o ~/.local/share/whisper-cpp/models/ggml-base.en.bin \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
```

If video dependencies are missing, the skill degrades gracefully — it will analyze the video thumbnail as a static image instead.

## Permissions

Add these to your `.claude/settings.local.json` to avoid permission prompts:

```json
{
  "permissions": {
    "allow": [
      "WebFetch(domain:share.zight.com)",
      "WebFetch(domain:oembed.zight.com)",
      "Bash(curl:*)",
      "Bash(ffmpeg:*)",
      "Bash(ffprobe:*)",
      "Bash(whisper-cli:*)"
    ]
  }
}
```

Or run Claude Code with `--dangerously-skip-permissions` if you're in a trusted environment.

## Usage

The skill triggers automatically when Claude sees a `share.zight.com` link. You can also invoke it manually:

```
/zight https://share.zight.com/abc123
```

### What it does

1. Hits the Zight oEmbed endpoint to detect content type (image vs video)
2. **Images/GIFs**: Downloads and analyzes visually
3. **Videos**: Downloads the MP4, extracts frames at adaptive intervals, transcribes audio, reads each frame, and correlates the timeline
4. Returns a structured summary with timeline, bug description, and investigation suggestions

### Example output for a screen recording

```
## Screen Recording Analysis

**Duration**: 45 seconds
**Application area**: Settings > Session Types

### Timeline
- **0:00-0:08**: User navigates to session type creation page
- **0:08-0:15**: Fills in "Weekly Retro" as name, selects 60 min duration
- **0:15-0:25**: Selects "Custom URL" for location, enters Zoom link
- **0:25-0:35**: Clicks "Create Session Type" button
- **0:35-0:45**: Error toast appears: "Cal.com team not configured"

### Bug/Issue Summary
Session type creation fails with a Cal.com configuration error when
using Custom URL location type.

### Suggested Investigation Areas
- Cal.com team/branding setup flow
- Session type creation controller
- Error handling for missing Cal.com configuration
```

## How it works

Zight share pages embed metadata in a JavaScript config object (`window.Copernicus` or `window.gon`). The skill extracts the content URL from this object and the oEmbed endpoint, then processes the content locally.

- **CDN subdomains vary** (`p198.p4.n0.cdn.zight.com`, `p199...`, etc.), so downloads always use `curl` rather than domain-locked fetch tools
- **Transcription** first checks if Zight's AI already generated a transcript (available on paid plans), and falls back to local whisper-cpp
- **Frame extraction rate** adapts to video length: every 2s for short clips, every 5s for longer recordings
- Runs with `context: fork` so video analysis doesn't consume your main conversation's context window

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill definition and step-by-step workflow |
| `reference.md` | Zight page structure, oEmbed docs, ffmpeg/whisper commands |

## License

MIT
