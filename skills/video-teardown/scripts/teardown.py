#!/usr/bin/env python3
"""video-teardown: fetch a video by URL and produce raw teardown materials.

Outputs (in one asset dir, never in the vault):
  meta.json        yt-dlp metadata (+ X post metrics/followers for x.com URLs)
  video.mp4        <=720p download
  transcript.txt   "[h:mm:ss] text" lines (Whisper API, chunked for long videos)
  transcript.json  raw segments with absolute timestamps
  frames/          individual JPGs named by timestamp (t_0h12m34s.jpg)
  frames.tsv       idx, seconds, timestamp, file, sheet, cell
  sheets/          contact sheets (grids) for fast visual skim
  summary.json     what was produced + cost estimate (also printed to stdout)

Usage:
  teardown.py <url | local-file> [--mode auto|short|demo] [--out DIR] [--max-frames N]
              [--interval SEC] [--scene 0.0-1.0] [--language en] [--force]

Idempotent: re-running reuses existing download/transcript/frames unless --force.
Exit codes: 0 ok, 2 usage/missing secret, 3 download failed, 4 transcription failed.
"""

import argparse
import json
import math
import os
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

WHISPER_USD_PER_MIN = 0.006
X_READ_USD = 0.005
CHUNK_SECONDS = 1200  # 20 min audio chunks stay well under Whisper's 25 MB cap
DEFAULT_ROOT = Path.home() / ".openclaw/workspace/research/teardowns"
X_READ = Path(__file__).resolve().parents[2] / "x-read/scripts/x-read.sh"


def die(msg, code):
    print(f"teardown: {msg}", file=sys.stderr)
    sys.exit(code)


def run(cmd, **kw):
    return subprocess.run(cmd, check=True, text=True, capture_output=True, **kw)


def load_env():
    """Gateway env lives in ~/.openclaw/.env; exec'd agents usually inherit it, CLI users may not."""
    envf = Path.home() / ".openclaw/.env"
    if not envf.exists():
        return
    for line in envf.read_text().splitlines():
        m = re.match(r"^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$", line)
        if m and m.group(1) not in os.environ:
            os.environ[m.group(1)] = m.group(2).strip().strip("'\"")


def hms(sec):
    sec = int(sec)
    h, m, s = sec // 3600, (sec % 3600) // 60, sec % 60
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


def slugify(s, n=50):
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s or "video").strip("-").lower()
    return s[:n].strip("-") or "video"


def fetch_meta(url):
    try:
        out = run(["yt-dlp", "--no-update", "-J", "--no-playlist", url]).stdout
    except subprocess.CalledProcessError as e:
        die(f"yt-dlp metadata failed: {e.stderr.strip()[-500:]}", 3)
    j = json.loads(out)
    keep = ["id", "title", "description", "uploader", "uploader_id", "channel", "webpage_url",
            "extractor_key", "duration", "upload_date", "timestamp", "view_count", "like_count",
            "comment_count", "repost_count", "channel_follower_count", "width", "height"]
    return {k: j.get(k) for k in keep if j.get(k) is not None}


def x_post_metrics(url):
    """For x.com/twitter.com URLs: public metrics + author followers (enables the outlier ratio)."""
    m = re.search(r"(?:x|twitter)\.com/[^/]+/status/(\d+)", url)
    if not m or not X_READ.exists() or not os.environ.get("X_BEARER_TOKEN"):
        return None
    try:
        j = json.loads(run([str(X_READ), "tweet", m.group(1)]).stdout)
    except Exception as e:  # metrics are a nice-to-have; never block the teardown
        return {"error": str(e)[:300]}
    d = j.get("data", {})
    u = (j.get("includes", {}).get("users") or [{}])[0]
    pm, followers = d.get("public_metrics", {}), u.get("public_metrics", {}).get("followers_count")
    out = {"text": d.get("text"), "created_at": d.get("created_at"), "author": u.get("username"),
           "author_followers": followers, "metrics": pm}
    if followers and pm.get("impression_count"):
        out["impressions_per_follower"] = round(pm["impression_count"] / followers, 1)
    return out


def download(url, outdir):
    vid = outdir / "video.mp4"
    if vid.exists():
        return vid
    try:
        run(["yt-dlp", "--no-update", "-q", "--no-playlist",
             "-f", "bv*[height<=720]+ba/b[height<=720]/bv*+ba/b",
             "--merge-output-format", "mp4", "-o", str(vid), url])
    except subprocess.CalledProcessError as e:
        die(f"download failed: {e.stderr.strip()[-500:]}", 3)
    return vid


def probe_duration(vid):
    return float(run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                      "-of", "csv=p=0", str(vid)]).stdout.strip())


def has_audio(vid):
    out = run(["ffprobe", "-v", "error", "-select_streams", "a", "-show_entries",
               "stream=index", "-of", "csv=p=0", str(vid)]).stdout.strip()
    return bool(out)


def transcribe(vid, outdir, duration, language):
    txt, js = outdir / "transcript.txt", outdir / "transcript.json"
    if txt.exists() and js.exists():
        return json.loads(js.read_text())
    key = os.environ.get("OPENAI_API_KEY")
    if not key:
        die("missing OPENAI_API_KEY (needed for Whisper transcription)", 2)
    adir = outdir / "audio"
    adir.mkdir(exist_ok=True)
    segments = []
    for i in range(math.ceil(duration / CHUNK_SECONDS)):
        start = i * CHUNK_SECONDS
        chunk = adir / f"chunk{i:02d}.mp3"
        run(["ffmpeg", "-v", "error", "-y", "-ss", str(start), "-t", str(CHUNK_SECONDS),
             "-i", str(vid), "-vn", "-ac", "1", "-ar", "16000", "-b:a", "32k", str(chunk)])
        cmd = ["curl", "-sS", "--max-time", "600", "https://api.openai.com/v1/audio/transcriptions",
               "-H", f"Authorization: Bearer {key}", "-F", f"file=@{chunk}",
               "-F", "model=whisper-1", "-F", "response_format=verbose_json",
               "-F", "timestamp_granularities[]=segment"]
        if language:
            cmd += ["-F", f"language={language}"]
        try:
            resp = json.loads(run(cmd).stdout)
        except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
            die(f"whisper call failed on chunk {i}: {str(e)[:300]}", 4)
        if "error" in resp:
            die(f"whisper error on chunk {i}: {resp['error'].get('message', resp['error'])}", 4)
        for s in resp.get("segments", []):
            segments.append({"start": round(s["start"] + start, 2), "end": round(s["end"] + start, 2),
                             "text": s["text"].strip()})
    js.write_text(json.dumps(segments, indent=1))
    txt.write_text("".join(f"[{hms(s['start'])}] {s['text']}\n" for s in segments))
    shutil.rmtree(adir, ignore_errors=True)
    return segments


def pick_times(vid, duration, mode, max_frames, interval, scene):
    """short: even interval. demo: scene changes (UI changes in screen recordings) + a floor of
    evenly spaced frames so long static stretches still get covered; min 3 s apart, capped."""
    if mode == "short":
        step = interval or max(2.0, duration / max_frames)
        return [round(t, 2) for t in frange(step / 2, duration, step)][:max_frames]
    res = subprocess.run(["ffmpeg", "-v", "info", "-i", str(vid), "-an", "-vf",
                          f"select='gt(scene,{scene})',showinfo", "-f", "null", "-"],
                         text=True, capture_output=True)
    scenes = [float(x) for x in re.findall(r"pts_time:([\d.]+)", res.stderr)]
    floor_step = interval or max(30.0, duration / (max_frames / 2))
    times = sorted(set([round(t, 2) for t in scenes] + list(frange(1.0, duration, floor_step))))
    kept = []
    for t in (t for t in times if t <= duration - 1.0):  # seeking to the final frame yields nothing
        if not kept or t - kept[-1] >= 3.0:
            kept.append(t)
    if len(kept) > max_frames:  # thin evenly, keep first/last
        idx = [round(i * (len(kept) - 1) / (max_frames - 1)) for i in range(max_frames)]
        kept = [kept[i] for i in sorted(set(idx))]
    return kept


def frange(a, b, step):
    t = a
    while t < b:
        yield t
        t += step


def extract_frames(vid, outdir, times, mode, force):
    fdir, sdir = outdir / "frames", outdir / "sheets"
    if force:
        shutil.rmtree(fdir, ignore_errors=True)
        shutil.rmtree(sdir, ignore_errors=True)
    if (outdir / "frames.tsv").exists() and fdir.exists():
        return sum(1 for _ in fdir.glob("*.jpg")), sum(1 for _ in sdir.glob("*.jpg"))
    fdir.mkdir(exist_ok=True)
    sdir.mkdir(exist_ok=True)
    # demo frames keep full 720p width so UI text stays legible; short-form is fine smaller
    width = 1280 if mode == "demo" else 720
    cols, rows, cell_w = (3, 2, 640) if mode == "demo" else (4, 2, 480)
    per_sheet = cols * rows
    tmp = outdir / ".sheetin"
    shutil.rmtree(tmp, ignore_errors=True)
    tmp.mkdir()
    rows_tsv = ["idx\tseconds\ttimestamp\tfile\tsheet\tcell"]
    i = 0
    for t in times:
        h, m, s = int(t) // 3600, (int(t) % 3600) // 60, int(t) % 60
        f = fdir / f"t_{h}h{m:02d}m{s:02d}s.jpg"
        r = subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", str(t), "-i", str(vid), "-frames:v", "1",
                            "-vf", f"scale={width}:-2", "-q:v", "3", str(f)], capture_output=True)
        if r.returncode != 0 or not f.exists():
            continue  # one bad seek shouldn't sink the teardown
        shutil.copy(f, tmp / f"{i:05d}.jpg")
        rows_tsv.append(f"{i}\t{t}\t{hms(t)}\tframes/{f.name}\tsheets/s{i // per_sheet + 1:02d}.jpg\t{i % per_sheet + 1}")
        i += 1
    (outdir / "frames.tsv").write_text("\n".join(rows_tsv) + "\n")
    run(["ffmpeg", "-v", "error", "-y", "-framerate", "1", "-i", str(tmp / "%05d.jpg"),
         "-vf", f"scale={cell_w}:-2,tile={cols}x{rows}:padding=4:color=white",
         str(sdir / "s%02d.jpg")])
    shutil.rmtree(tmp, ignore_errors=True)
    return i, sum(1 for _ in sdir.glob("*.jpg"))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("url")
    ap.add_argument("--mode", choices=["auto", "short", "demo"], default="auto",
                    help="auto = short if <=3 min or a social URL, demo otherwise")
    ap.add_argument("--out", help=f"asset dir (default {DEFAULT_ROOT}/<date>-<slug>)")
    ap.add_argument("--max-frames", type=int, default=0, help="default 24 short / 90 demo")
    ap.add_argument("--interval", type=float, default=0, help="seconds between frames (overrides auto)")
    ap.add_argument("--scene", type=float, default=0.12,
                    help="demo scene-change threshold; lower = more frames (screen recordings change subtly)")
    ap.add_argument("--language", default="", help="ISO code hint for Whisper, e.g. en, es, de")
    ap.add_argument("--force", action="store_true", help="re-extract frames (download/transcript still reused)")
    a = ap.parse_args()
    local = Path(a.url).expanduser()
    is_local = local.is_file()
    if not is_local and not a.url.startswith(("http://", "https://")):
        die(f"not a URL or existing file: {a.url!r} (run with -h for usage)", 2)
    for tool in ("yt-dlp", "ffmpeg", "ffprobe", "curl"):
        if not shutil.which(tool):
            die(f"missing tool: {tool}", 2)
    load_env()

    # local files: private/workspace-restricted Looms that Marcel downloaded by hand
    meta = {"title": local.stem, "source_file": str(local)} if is_local else fetch_meta(a.url)
    social = re.search(r"(x|twitter|tiktok|instagram)\.com|youtube\.com/shorts", a.url)
    outdir = Path(a.out) if a.out else DEFAULT_ROOT / f"{date.today():%Y%m%d}-{slugify(meta.get('title') or meta.get('id'))}"
    outdir.mkdir(parents=True, exist_ok=True)

    xm = None if is_local else x_post_metrics(a.url)
    if xm:
        meta["x_post"] = xm
    meta["source_url"] = a.url
    (outdir / "meta.json").write_text(json.dumps(meta, indent=1, ensure_ascii=False))

    if is_local:
        vid = outdir / "video.mp4"
        if not vid.exists():
            run(["ffmpeg", "-v", "error", "-y", "-i", str(local), "-c", "copy", str(vid)])
    else:
        vid = download(a.url, outdir)
    duration = probe_duration(vid)  # trust the file, not metadata (generic extractors omit it)
    mode = a.mode
    if mode == "auto":
        mode = "short" if social or duration <= 180 else "demo"
    segments = transcribe(vid, outdir, duration, a.language) if has_audio(vid) else []
    max_frames = a.max_frames or (24 if mode == "short" else 90)
    times = pick_times(vid, duration, mode, max_frames, a.interval, a.scene)
    nframes, nsheets = extract_frames(vid, outdir, times, mode, a.force)

    minutes = duration / 60
    summary = {
        "asset_dir": str(outdir), "mode": mode, "title": meta.get("title"),
        "duration": hms(duration), "duration_seconds": round(duration, 1),
        "transcript_segments": len(segments), "transcript_words": sum(len(s["text"].split()) for s in segments),
        "frames": nframes, "sheets": nsheets,
        "files": ["meta.json", "transcript.txt", "transcript.json", "frames.tsv", "frames/", "sheets/", "video.mp4"],
        "cost_estimate_usd": round(minutes * WHISPER_USD_PER_MIN * (1 if segments else 0) + (X_READ_USD if xm else 0), 3),
    }
    if xm and "impressions_per_follower" in xm:
        summary["impressions_per_follower"] = xm["impressions_per_follower"]
    (outdir / "summary.json").write_text(json.dumps(summary, indent=1))
    print(json.dumps(summary, indent=1))


if __name__ == "__main__":
    main()
