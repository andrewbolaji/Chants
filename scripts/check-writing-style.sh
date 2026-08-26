#!/bin/sh
set -eu

style_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
style_candidate_root=$(CDPATH= cd -- "$style_script_dir/.." && pwd)

if style_git_root=$(git -C "$style_candidate_root" rev-parse --show-toplevel 2>/dev/null); then
  style_root=$style_git_root
else
  style_root=$style_candidate_root
fi

style_hits=$(mktemp "${TMPDIR:-/tmp}/writing-style-hits.XXXXXX")
trap 'rm -f "$style_hits"' EXIT HUP INT TERM

find "$style_root" \
  -type d \( \
    -name .git -o \
    -name node_modules -o \
    -name vendor -o \
    -name dist -o \
    -name build -o \
    -name .next -o \
    -name .venv \
  \) -prune -o \
  -type f \( -name '*.md' -o -name '*.mdx' -o -name '*.txt' \) \
  -exec grep -nH '—' {} + >"$style_hits" 2>/dev/null || true

if [ -s "$style_hits" ]; then
  echo "Em dash found in prose:" >&2
  cat "$style_hits" >&2
  echo "Rewrite with a comma, period, colon, or parentheses." >&2
  exit 1
fi

echo "Writing-style check passes."
