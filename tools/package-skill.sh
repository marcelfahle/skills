#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <skill-dir> [output-dir]" >&2
  exit 1
fi

SKILL_DIR="$1"
OUT_DIR="${2:-dist}"
python3 /home/linuxbrew/.linuxbrew/lib/node_modules/openclaw/skills/skill-creator/scripts/package_skill.py "$SKILL_DIR" "$OUT_DIR"
