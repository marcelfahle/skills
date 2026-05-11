---
name: zight
description: >
  Analyze Zight screenshots and screen recordings from share.zight.com links.
  Use this skill automatically when a Zight link appears in a ticket, user
  message, or bug report. Handles both images (view directly) and videos
  (extract frames, transcribe audio, analyze visually). Produces a structured
  summary of what the user sees and says in the recording.
allowed-tools: Bash, Read, Write, WebFetch, Glob, Grep, Task
context: fork
agent: general-purpose
argument-hint: <zight-share-url>
---

# Zight Content Analyzer

Analyze Zight screenshots and screen recordings to understand bug reports,
feature requests, and user feedback.

## Prerequisites

Before processing video content, verify dependencies are installed:

```bash
which ffmpeg    # Required for frame extraction and audio conversion
which ffprobe   # Required for video metadata (installed with ffmpeg)
which whisper-cli  # Required for audio transcription
```

If missing:
- **ffmpeg**: `brew install ffmpeg` (macOS) or `apt install ffmpeg` (Linux)
- **whisper-cli**: `brew install whisper-cpp` (macOS), then download a model:
  `curl -L -o ~/.local/share/whisper-cpp/models/ggml-base.en.bin "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"`

Image analysis requires no external dependencies.

## Quick Reference

- **oEmbed endpoint**: `https://oembed.zight.com/oembed?url=URL&format=json`
- **Whisper model**: `~/.local/share/whisper-cpp/models/ggml-base.en.bin`
- **Whisper CLI**: `whisper-cli`
- **Temp directory**: `/tmp/zight-${session_id}/`

See [reference.md](reference.md) for Zight page structure and field documentation.

## Step 1: Detect Content Type

Fetch the oEmbed metadata to determine if this is an image or video:

```bash
curl -sL "https://oembed.zight.com/oembed?url=ZIGHT_URL&format=json"
```

Check the `type` field:
- `"photo"` → Check the title; if it starts with "Zight Recording" it may be an animated GIF (see Step 2a)
- `"video"` or `"rich"` → Video path (Step 2b)

If oEmbed fails, fall back to fetching the share page with WebFetch and
extracting the content type from the page metadata.

## Step 2a: Image / GIF Analysis

1. Extract the direct image URL from the oEmbed `url` field
2. Download: `curl -sL -o /tmp/zight-img.jpg "CDN_URL"`
3. Read the file to view it (Claude's vision will analyze the image)
4. Describe what is shown, focusing on:
   - UI state, error messages, unexpected behavior
   - Which part of the application is visible
   - Any annotations or highlights the user added

Note: Titles containing "Zight Recording" indicate animated content (GIFs or
screen recordings). GIFs returned as `type: "photo"` can still be viewed as
static images — Claude sees the first frame.

Return the analysis to the caller. Done.

## Step 2b: Video / Screen Recording Analysis

### 2b.1: Extract metadata and download

WebFetch the share page to extract the video metadata. Look for the
`Copernicus` or `gon` config object in the page:
- `content_url` → direct MP4 download URL
- `transcription.data` → existing transcript (may be null)
- `name` → original filename with context

Create a working directory and download the video:

```bash
SESSION_DIR="/tmp/zight-$(date +%s)"
mkdir -p "$SESSION_DIR/frames"
curl -sL -o "$SESSION_DIR/video.mp4" "CONTENT_URL"
```

### 2b.2: Get video info

```bash
ffprobe -v quiet -print_format json -show_format -show_streams "$SESSION_DIR/video.mp4"
```

Note the duration to decide frame extraction rate:
- Under 30s: 1 frame every 2 seconds
- 30s-120s: 1 frame every 3 seconds
- Over 120s: 1 frame every 5 seconds

### 2b.3: Extract key frames

```bash
ffmpeg -i "$SESSION_DIR/video.mp4" \
  -vf "fps=1/INTERVAL" \
  -q:v 2 \
  "$SESSION_DIR/frames/frame-%04d.jpg" 2>&1
```

### 2b.4: Transcribe audio

First check if the page metadata had a transcript. If yes, use that
and skip to step 2b.5.

If no transcript exists, extract and transcribe:

```bash
# Extract audio as 16kHz mono WAV (whisper-cpp requirement)
ffmpeg -i "$SESSION_DIR/video.mp4" \
  -ar 16000 -ac 1 -c:a pcm_s16le \
  "$SESSION_DIR/audio.wav" 2>&1

# Transcribe with timestamps
whisper-cli \
  --model ~/.local/share/whisper-cpp/models/ggml-base.en.bin \
  --output-txt --output-srt \
  --file "$SESSION_DIR/audio.wav" 2>&1
```

The SRT file at `$SESSION_DIR/audio.wav.srt` contains timestamped segments.
The TXT file at `$SESSION_DIR/audio.wav.txt` contains plain text.

Read both files.

### 2b.5: Analyze frames visually

Read each extracted frame image. For each frame, note:
- What screen/page is shown
- Any error messages, toasts, modals
- What the user is interacting with (cursor position, active elements)
- State changes from previous frame

Correlate frame timestamps with transcript timestamps to understand
what the user was describing at each moment.

### 2b.6: Synthesize

Produce a structured summary:

```
## Screen Recording Analysis

**Duration**: X seconds
**Application area**: [which part of the app]

### Timeline
- **0:00-0:05**: User navigates to [page]. Says: "..."
- **0:05-0:12**: Clicks [button]. Error appears: "..."
- ...

### Bug/Issue Summary
[What the user is reporting, what the expected vs actual behavior is]

### Relevant UI States
[Key observations about the application state visible in frames]

### Suggested Investigation Areas
[Files, components, or systems likely involved]
```

### 2b.7: Cleanup

```bash
rm -rf "$SESSION_DIR"
```

## Error Handling

- If oEmbed returns an error, fall back to parsing the share page HTML
- If ffmpeg is not installed, analyze only the thumbnail (available in oEmbed)
- If whisper-cli is not installed or fails, provide frame analysis without transcript
- If the video has no audio track, skip transcription entirely
- Always clean up temp files, even on error

## Notes

- Zight CDN subdomains vary (p198, p199, etc.) — always use curl, not WebFetch for downloads
- Page config is in a `<script>` tag as `window.Copernicus` (newer) or `window.gon` (older)
- Screen recordings are always MP4
- Some recordings may have no narration — that's fine, frame analysis alone is valuable
