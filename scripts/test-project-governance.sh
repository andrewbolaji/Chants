#!/usr/bin/env bash
set -euo pipefail

governance_script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
governance_temp_root="$(mktemp -d "${TMPDIR:-/tmp}/chants-governance-tests.XXXXXX")"
trap 'rm -rf "$governance_temp_root"' EXIT HUP INT TERM

fail() {
  echo "Governance regression failed: $1" >&2
  exit 1
}

initialize_memory_repo() {
  local repo_path=$1
  mkdir -p "$repo_path/docs" "$repo_path/scripts"
  cp "$governance_script_dir/check-project-memory.sh" "$repo_path/scripts/"
  printf '%s\n' \
    '# Agent references' \
    'docs/EXECUTION.md' \
    'docs/LEARNINGS.md' \
    'docs/INTERFACE.md' >"$repo_path/AGENTS.md"
  printf '%s\n' '# Execution' >"$repo_path/docs/EXECUTION.md"
  printf '%s\n' '# Learnings' >"$repo_path/docs/LEARNINGS.md"
  printf '%s\n' '# Interface' >"$repo_path/docs/INTERFACE.md"
  git -C "$repo_path" init -q
  git -C "$repo_path" config user.email tests@chants.invalid
  git -C "$repo_path" config user.name 'Chants tests'
  git -C "$repo_path" add .
  git -C "$repo_path" commit -qm baseline
}

initialize_style_repo() {
  local repo_path=$1
  mkdir -p "$repo_path/docs" "$repo_path/scripts"
  cp "$governance_script_dir/check-writing-style.sh" "$repo_path/scripts/"
  printf '%s\n' 'Clean prose.' >"$repo_path/docs/clean.md"
  git -C "$repo_path" init -q
  git -C "$repo_path" config user.email tests@chants.invalid
  git -C "$repo_path" config user.name 'Chants tests'
  git -C "$repo_path" add .
  git -C "$repo_path" commit -qm baseline
}

initialize_native_repo() {
  local repo_path=$1
  local swiftpm_flag=${2:-false}
  local swiftpm_marker=${3:-false}
  mkdir -p "$repo_path/ios/Runner.xcodeproj" "$repo_path/scripts"
  cp "$governance_script_dir/check-native-project.sh" "$repo_path/scripts/"
  printf '%s\n' \
    'flutter:' \
    '  config:' \
    "    enable-swift-package-manager: $swiftpm_flag" >"$repo_path/pubspec.yaml"
  printf '%s\n' \
    'PODS:' \
    '  - share_plus (0.0.1):' \
    '  - url_launcher_ios (0.0.1):' >"$repo_path/ios/Podfile.lock"
  if [ "$swiftpm_marker" = true ]; then
    printf '%s\n' 'FlutterGeneratedPluginSwiftPackage' \
      >"$repo_path/ios/Runner.xcodeproj/project.pbxproj"
  else
    printf '%s\n' '// CocoaPods project' \
      >"$repo_path/ios/Runner.xcodeproj/project.pbxproj"
  fi
  git -C "$repo_path" init -q
  git -C "$repo_path" config user.email tests@chants.invalid
  git -C "$repo_path" config user.name 'Chants tests'
  git -C "$repo_path" add .
  git -C "$repo_path" commit -qm baseline
}

memory_space_repo="$governance_temp_root/memory-space"
initialize_memory_repo "$memory_space_repo"
mkdir -p "$memory_space_repo/docs/review notes"
printf '%s\n' 'Documentation only.' >"$memory_space_repo/docs/review notes/plan"
git -C "$memory_space_repo" add 'docs/review notes/plan'
"$memory_space_repo/scripts/check-project-memory.sh" --staged >/dev/null || \
  fail 'a documentation path containing spaces was split and misclassified'

memory_impl_repo="$governance_temp_root/memory-implementation"
initialize_memory_repo "$memory_impl_repo"
mkdir -p "$memory_impl_repo/lib"
printf '%s\n' 'void main() {}' >"$memory_impl_repo/lib/change.dart"
git -C "$memory_impl_repo" add lib/change.dart
if "$memory_impl_repo/scripts/check-project-memory.sh" --staged >/dev/null 2>&1; then
  fail 'an implementation change passed without a staged execution update'
fi
printf '%s\n' 'Implementation evidence.' >>"$memory_impl_repo/docs/EXECUTION.md"
git -C "$memory_impl_repo" add docs/EXECUTION.md
"$memory_impl_repo/scripts/check-project-memory.sh" --staged >/dev/null || \
  fail 'an implementation change with staged execution evidence was rejected'

memory_error_repo="$governance_temp_root/memory-error"
initialize_memory_repo "$memory_error_repo"
if GIT_INDEX_FILE="$memory_error_repo/.git" \
  "$memory_error_repo/scripts/check-project-memory.sh" --staged >/dev/null 2>&1; then
  fail 'a Git index read error was treated as an empty staged diff'
fi

style_repo="$governance_temp_root/style"
initialize_style_repo "$style_repo"
printf 'Untracked scratch \342\200\224 outside the index.\n' >"$style_repo/scratch.md"
"$style_repo/scripts/check-writing-style.sh" >/dev/null || \
  fail 'untracked scratch prose affected the index-scoped writing check'
printf 'Tracked prose \342\200\224 must fail.\n' >"$style_repo/docs/bad.md"
git -C "$style_repo" add docs/bad.md
if "$style_repo/scripts/check-writing-style.sh" >/dev/null 2>&1; then
  fail 'a forbidden dash in tracked prose passed'
fi

style_error_repo="$governance_temp_root/style-error"
initialize_style_repo "$style_error_repo"
if GIT_INDEX_FILE="$style_error_repo/.git" \
  "$style_error_repo/scripts/check-writing-style.sh" >/dev/null 2>&1; then
  fail 'a Git index read error was treated as a clean scan'
fi

native_clean_repo="$governance_temp_root/native-clean"
initialize_native_repo "$native_clean_repo"
"$native_clean_repo/scripts/check-native-project.sh" >/dev/null || \
  fail 'the CocoaPods-native project contract was rejected'

native_flag_repo="$governance_temp_root/native-flag"
initialize_native_repo "$native_flag_repo" true
if "$native_flag_repo/scripts/check-native-project.sh" >/dev/null 2>&1; then
  fail 'a project without the CocoaPods ownership flag passed'
fi

native_marker_repo="$governance_temp_root/native-marker"
initialize_native_repo "$native_marker_repo" true true
if "$native_marker_repo/scripts/check-native-project.sh" >/dev/null 2>&1; then
  fail 'tracked Flutter SwiftPM integration passed the native contract'
fi

echo 'Project governance regressions pass.'
