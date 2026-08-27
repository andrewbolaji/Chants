#!/usr/bin/env bash
set -euo pipefail

style_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
style_candidate_root=$(CDPATH= cd -- "$style_script_dir/.." && pwd)

if style_git_root=$(git -C "$style_candidate_root" rev-parse --show-toplevel 2>/dev/null); then
  style_root=$style_git_root
else
  style_root=$style_candidate_root
fi

if ! git -C "$style_root" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Writing-style check requires a Git repository." >&2
  exit 2
fi

style_hits=$(mktemp "${TMPDIR:-/tmp}/writing-style-hits.XXXXXX")
style_errors=$(mktemp "${TMPDIR:-/tmp}/writing-style-errors.XXXXXX")
trap 'rm -f "$style_hits" "$style_errors"' EXIT HUP INT TERM

if git -C "$style_root" grep \
  --cached \
  -n \
  -I \
  -e '—' \
  -- \
  '*.md' \
  '*.mdx' \
  '*.txt' >"$style_hits" 2>"$style_errors"; then
  style_status=0
else
  style_status=$?
fi

case "$style_status" in
  0)
    echo "Em dash found in tracked prose:" >&2
    cat "$style_hits" >&2
    echo "Rewrite with a comma, period, colon, or parentheses." >&2
    exit 1
    ;;
  1)
    echo "Writing-style check passes."
    ;;
  *)
    echo "Writing-style scan failed:" >&2
    cat "$style_errors" >&2
    exit "$style_status"
    ;;
esac
