#!/usr/bin/env bash
set -euo pipefail

native_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
native_candidate_root=$(CDPATH= cd -- "$native_script_dir/.." && pwd)

if native_git_root=$(git -C "$native_candidate_root" rev-parse --show-toplevel 2>/dev/null); then
  native_project_root=$native_git_root
else
  native_project_root=$native_candidate_root
fi

native_fail() {
  echo "Native project contract failed: $1" >&2
  exit 1
}

if ! grep -F 'enable-swift-package-manager: false' \
  "$native_project_root/pubspec.yaml" >/dev/null 2>&1; then
  native_fail 'pubspec.yaml must keep the V1 iOS graph on CocoaPods'
fi

if git -C "$native_project_root" grep -n -F \
  'FlutterGeneratedPluginSwiftPackage' -- ios >/dev/null 2>&1; then
  native_fail 'tracked iOS source contains generated Flutter SwiftPM integration'
else
  native_grep_status=$?
  if [ "$native_grep_status" -gt 1 ]; then
    native_fail 'tracked iOS source could not be scanned for SwiftPM integration'
  fi
fi

native_resolved_paths=$(mktemp "${TMPDIR:-/tmp}/chants-native-resolved.XXXXXX")
trap 'rm -f "$native_resolved_paths"' EXIT HUP INT TERM
if ! git -C "$native_project_root" ls-files -z -- \
  'ios/Package.resolved' \
  ':(glob)ios/**/Package.resolved' >"$native_resolved_paths"; then
  native_fail 'tracked iOS source could not be scanned for SwiftPM resolution files'
fi
if [ -s "$native_resolved_paths" ]; then
  native_fail 'a generated SwiftPM resolution file is tracked under ios/'
fi

for native_pod in 'share_plus (0.0.1)' 'url_launcher_ios (0.0.1)'; do
  if ! grep -F "$native_pod" "$native_project_root/ios/Podfile.lock" >/dev/null 2>&1; then
    native_fail "ios/Podfile.lock is missing $native_pod"
  fi
done

echo 'Native project contract passes.'
