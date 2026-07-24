#!/usr/bin/env bash
# Stop hook for Chants.
#
# Blocks Claude from finishing while the Flutter test suite fails. flutter test
# is this repo's primary gate: it is the largest suite and needs no Firebase
# config (nothing under test/ imports firebase_options.dart), so it runs on a
# fresh clone. The backend suites (functions, seed, test_rules) have their own
# toolchains and run on demand, see CLAUDE.md.
#
# Contract (verified against the Claude Code hooks docs):
#   exit 0  tests passed, or the toolchain is absent, let the stop proceed
#   exit 2  tests failed, block the stop and feed stderr back to Claude
#
# A missing Flutter SDK exits 0 on purpose. A Stop hook cannot gate on a
# toolchain that is not installed, and blocking forever would trap the session.
# On a real Flutter dev machine flutter is present and the gate is live.

set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

if ! command -v flutter >/dev/null 2>&1; then
  echo "run_tests.sh: flutter is not on PATH, cannot run the test gate here. Install Flutter and the suite will gate on every stop." >&2
  exit 0
fi

if output="$(flutter test 2>&1)"; then
  exit 0
fi

echo "$output" | tail -40 >&2
echo "" >&2
echo "Stop blocked: flutter test failed. Fix the failing tests before finishing. Uncommitted, failing work does not exist." >&2
exit 2
