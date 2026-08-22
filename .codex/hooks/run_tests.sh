#!/usr/bin/env bash
# Stop hook for Chants.
#
# Blocks an agent turn from finishing while the Flutter test suite fails. flutter test
# is this repo's primary gate: it is the largest suite and needs no Firebase
# config (nothing under test/ imports firebase_options.dart), so it runs on a
# fresh clone. The backend suites (functions, seed, test_rules) have their own
# toolchains and run on demand, see AGENTS.md.
#
# Contract:
#   exit 0  tests passed, or the toolchain is absent, let the stop proceed
#   exit 2  tests failed, block the stop and feed stderr back to the agent
#
# A missing Flutter SDK exits 0 on purpose. A Stop hook cannot gate on a
# toolchain that is not installed, and blocking forever would trap the session.
# On a real Flutter dev machine flutter is present and the gate is live.

set -uo pipefail

hook_input="$(</dev/stdin)"
if [[ $hook_input =~ \"stop_hook_active\"[[:space:]]*:[[:space:]]*true ]]; then
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$repo_root" || exit 0

if ! command -v flutter >/dev/null 2>&1; then
  echo "run_tests.sh: flutter is not on PATH, cannot run the test gate here. Install Flutter and the suite will gate on every stop." >&2
  exit 0
fi

if output="$(flutter test 2>&1)"; then
  exit 0
fi

echo "$output" | tail -40 >&2
echo "" >&2
echo "Stop blocked: flutter test failed. Work with failing tests is not complete." >&2
exit 2
