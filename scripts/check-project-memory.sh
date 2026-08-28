#!/usr/bin/env bash
set -euo pipefail

memory_mode=${1:-structure}

if [ "$memory_mode" != "structure" ] && [ "$memory_mode" != "--staged" ] && [ "$memory_mode" != "--range" ]; then
  echo "Usage: $0 [--staged | --range <base>]" >&2
  exit 2
fi

if [ "$memory_mode" = "--range" ] && [ "$#" -ne 2 ]; then
  echo "Usage: $0 --range <base>" >&2
  exit 2
fi

memory_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
memory_candidate_root=$(CDPATH= cd -- "$memory_script_dir/.." && pwd)

if memory_git_root=$(git -C "$memory_candidate_root" rev-parse --show-toplevel 2>/dev/null); then
  memory_project_root=$memory_git_root
else
  memory_project_root=$memory_candidate_root
fi

memory_failed=0

for memory_file in docs/EXECUTION.md docs/LEARNINGS.md docs/INTERFACE.md; do
  if [ ! -f "$memory_project_root/$memory_file" ]; then
    echo "Missing project memory: $memory_file" >&2
    memory_failed=1
  fi
done

if [ ! -f "$memory_project_root/AGENTS.md" ]; then
  echo "Missing AGENTS.md project instructions" >&2
  memory_failed=1
else
  for memory_reference in docs/EXECUTION.md docs/LEARNINGS.md docs/INTERFACE.md; do
    if ! grep -F "$memory_reference" "$memory_project_root/AGENTS.md" >/dev/null 2>&1; then
      echo "AGENTS.md does not reference $memory_reference" >&2
      memory_failed=1
    fi
  done
fi

if [ "$memory_failed" -ne 0 ]; then
  exit 1
fi

if [ "$memory_mode" = "--staged" ] || [ "$memory_mode" = "--range" ]; then
  if ! git -C "$memory_project_root" rev-parse --git-dir >/dev/null 2>&1; then
    echo "$memory_mode requires a Git repository" >&2
    exit 2
  fi

  memory_has_implementation_change=0
  memory_staged_paths=$(mktemp "${TMPDIR:-/tmp}/project-memory-paths.XXXXXX")
  trap 'rm -f "$memory_staged_paths"' EXIT HUP INT TERM
  if [ "$memory_mode" = "--staged" ]; then
    if ! git -C "$memory_project_root" diff \
      --cached \
      --name-only \
      --diff-filter=ACMR \
      -z >"$memory_staged_paths"; then
      echo "Could not read staged paths for the project-memory check." >&2
      exit 2
    fi
  else
    memory_base=$2
    if ! git -C "$memory_project_root" rev-parse --verify "$memory_base^{commit}" >/dev/null 2>&1; then
      echo "Project-memory range base is not a commit: $memory_base" >&2
      exit 2
    fi
    if ! git -C "$memory_project_root" diff \
      "$memory_base...HEAD" \
      --name-only \
      --diff-filter=ACMR \
      -z >"$memory_staged_paths"; then
      echo "Could not read changed paths for the project-memory range check." >&2
      exit 2
    fi
  fi

  while IFS= read -r -d '' memory_path; do
    case "$memory_path" in
      docs/*|*.md|*.txt|LICENSE*|.gitignore|.gitattributes)
        ;;
      *)
        memory_has_implementation_change=1
        ;;
    esac
  done <"$memory_staged_paths"

  if [ "$memory_has_implementation_change" -eq 1 ] && [ "${PROJECT_MEMORY_LANE:-}" != "0" ]; then
    memory_execution_unchanged=no
    if [ "$memory_mode" = "--staged" ]; then
      if git -C "$memory_project_root" diff --cached --quiet -- docs/EXECUTION.md; then
        memory_execution_unchanged=yes
      fi
    elif git -C "$memory_project_root" diff "$memory_base...HEAD" --quiet -- docs/EXECUTION.md; then
      memory_execution_unchanged=yes
    fi

    if [ "$memory_execution_unchanged" = "yes" ]; then
      echo "Implementation changes require a docs/EXECUTION.md update in the same review range." >&2
      echo "For a confirmed Lane 0 mechanical change, rerun with PROJECT_MEMORY_LANE=0." >&2
      exit 1
    fi
  fi
fi

echo "Project memory contract passes."
