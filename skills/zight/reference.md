# Zight Technical Reference

## The Page Config Object (`Copernicus` / `gon`)

Every Zight share page (`share.zight.com/{hash_id}`) embeds metadata in a
`<script>` tag. Older pages use `window.gon`, newer pages use
`window.Copernicus` (with a `store` property containing the item data).
Check for both when extracting metadata.

### Title-Based Type Detection (Fallback)

Zight uses the naming convention **"Zight Recording YYYY-MM-DD at HH.MM.SS"**
for animated content (screen recordings, GIFs). Static screenshots use the
captured window/page title instead. This is a reliable secondary signal when
oEmbed returns `"photo"` for a GIF (since GIFs are technically images to oEmbed).

Check the oEmbed `title` or `gon.name` field — if it starts with "Zight Recording",
treat it as animated content even if oEmbed says `"photo"`.

### Key Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique hash ID (e.g., `p9um0gx0`) |
| `type` | string | Content type: `"image"`, `"video"`, `"screen_recording"` |
| `name` | string | Original filename |
| `content_url` | string | Direct CDN URL to the file |
| `thumbnail_url` | string | Thumbnail CDN URL |
| `download_url` | string | CDN URL with attachment disposition |
| `share_url` | string | Public share page URL |
| `status` | string | Processing status: `"completed"` |
| `created_at` | string | ISO 8601 timestamp |
| `view_counter` | number | View count |
| `checksum` | string | MD5 checksum of the file |
| `sharing` | string | `"un"` = unrestricted |
| `password_protected` | boolean | Whether password is required |

### Transcription Fields

```javascript
gon.transcription = {
  data: "Full transcript text...",  // null if not available
  meta: {
    status: "completed"             // null, "processing", "completed"
  }
}
```

Transcription requires Zight's AI add-on ($5/user/month). When available,
it includes auto-generated captions in 50+ languages. When `data` is null,
use local whisper-cli transcription as fallback.

### Organization Fields

```javascript
gon.organization = {
  id: "wrF5r95",                    // FounderWell org ID
  plan: "Pro Annual",
  custom_domain: "https://www.founderwell.com/",
  comments_disabled: true,
  reactions_disabled: true,
  download_button_hidden: true
}
```

## oEmbed Endpoint

**URL**: `https://oembed.zight.com/oembed?url={share_url}&format=json`

### Image Response

```json
{
  "version": "1.0",
  "type": "photo",
  "title": "Screenshot title",
  "url": "https://pN.p4.n0.cdn.zight.com/items/HASH/UUID.jpg",
  "width": 1542,
  "height": 942,
  "provider_name": "Created with Zight",
  "provider_url": "https://zight.com",
  "html": "<iframe src=\"...\"></iframe>"
}
```

### Video Response (expected)

```json
{
  "version": "1.0",
  "type": "video",
  "title": "Recording title",
  "html": "<iframe src=\"...?embed=true\" ...></iframe>",
  "width": 1920,
  "height": 1080,
  "provider_name": "Created with Zight"
}
```

For videos, the direct MP4 URL is NOT in the oEmbed response. Extract it
from the `gon.content_url` field on the share page instead.

## CDN URL Patterns

| Purpose | Pattern |
|---------|---------|
| Content | `https://p{N}.p4.n0.cdn.zight.com/items/{hash}/{uuid}.{ext}` |
| Thumbnail | `https://thumbnail.cdn.zight.com/i/{hash}/{dimensions}/...` |
| Download | Content URL + `?response-content-disposition=attachment` |

The `p{N}` prefix varies per request (load balancing). Always use `curl`
for downloads since WebFetch domain permissions can't wildcard subdomains.

## Extracting `gon` from HTML

The `gon` object is set in a `<script>` tag like:

```html
<script>window.gon = {...};</script>
```

To extract it from the fetched HTML, use WebFetch on the share page and look
for the `gon` configuration in the response. The WebFetch tool processes HTML
to markdown, so you may need to ask specifically for the gon/config data in
your prompt, or use curl + grep:

```bash
curl -sL "https://share.zight.com/HASH" | grep -o 'gon\s*=\s*{[^;]*' | head -1
```

Note: the gon object can be large. For reliable extraction, pipe through
python's json module:

```bash
curl -sL "https://share.zight.com/HASH" \
  | grep -oP '(?<=window\.gon\s=\s).*?(?=;\s*<)' \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps({k:d[k] for k in ['type','content_url','name','transcription']}, indent=2))"
```

## whisper-cli Reference

```bash
# Basic transcription with SRT output
whisper-cli \
  --model ~/.local/share/whisper-cpp/models/ggml-base.en.bin \
  --output-txt \
  --output-srt \
  --file /path/to/audio.wav

# Output files created alongside the input:
#   /path/to/audio.wav.txt  (plain text)
#   /path/to/audio.wav.srt  (timestamped subtitles)
```

Audio must be 16kHz mono WAV. Convert with:

```bash
ffmpeg -i input.mp4 -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```

## ffmpeg Frame Extraction

```bash
# Extract 1 frame every N seconds
ffmpeg -i video.mp4 -vf "fps=1/N" -q:v 2 frames/frame-%04d.jpg

# Get video duration
ffprobe -v quiet -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 video.mp4
```

Frame rate guidelines based on duration:
- Under 30s → `fps=1/2` (every 2 seconds)
- 30s-120s → `fps=1/3` (every 3 seconds)
- Over 120s → `fps=1/5` (every 5 seconds)
