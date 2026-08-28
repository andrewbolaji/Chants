#!/usr/bin/env bash
set -euo pipefail

governance_script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
governance_temp_root="$(mktemp -d "${TMPDIR:-/tmp}/chants-governance-tests.XXXXXX")"
trap 'rm -rf "$governance_temp_root"' EXIT HUP INT TERM

fail() {
  echo "Governance regression failed: $1" >&2
  exit 1
}

assert_native_failure() {
  local repo_path=$1
  local expected_message=$2
  local fixture_name=$3
  local failure_output="$governance_temp_root/$fixture_name.stderr"

  if "$repo_path/scripts/check-native-project.sh" \
    >/dev/null 2>"$failure_output"; then
    fail "$fixture_name unexpectedly passed the native contract"
  fi
  if ! grep -Fx "Native project contract failed: $expected_message" \
    "$failure_output" >/dev/null 2>&1; then
    fail "$fixture_name failed at the wrong native-contract boundary"
  fi
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
  mkdir -p \
    "$repo_path/ios/Runner.xcodeproj" \
    "$repo_path/ios/Runner" \
    "$repo_path/android/app/src/main" \
    "$repo_path/scripts"
  cp "$governance_script_dir/check-native-project.sh" "$repo_path/scripts/"
  printf '%s\n' \
    'flutter:' \
    '  config:' \
    "    enable-swift-package-manager: $swiftpm_flag" >"$repo_path/pubspec.yaml"
  printf '%s\n' \
    'PODS:' \
    '  - share_plus (0.0.1):' \
    '  - url_launcher_ios (0.0.1):' \
    '  - app_links (7.0.0):' \
    '  - firebase_auth (6.6.1):' \
    '  - flutter_facebook_auth (7.1.5):' \
    '  - google_sign_in_ios (0.0.1):' \
    '  - shared_preferences_foundation (0.0.1):' \
    >"$repo_path/ios/Podfile.lock"
  if [ "$swiftpm_marker" = true ]; then
    printf '%s\n' 'FlutterGeneratedPluginSwiftPackage' \
      >"$repo_path/ios/Runner.xcodeproj/project.pbxproj"
  else
    printf '%s\n' \
      '// CocoaPods project' \
      'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;' \
      >"$repo_path/ios/Runner.xcodeproj/project.pbxproj"
  fi
  printf '%s\n' \
    'com.apple.developer.applesignin' \
    'applinks:auth.chantsfc.com' \
    'applinks:chantsfc.com' >"$repo_path/ios/Runner/Runner.entitlements"
  printf '%s\n' \
    '<manifest>' \
    'android.permission.INTERNET' \
    'android:autoVerify="true"' \
    'android:host="auth.chantsfc.com"' \
    'android:pathPrefix="/finish-sign-in"' \
    'android:host="chantsfc.com"' \
    'android:pathPrefix="/chants/"' \
    'android:pathPrefix="/performances/"' \
    'android:pathPrefix="/creators/"' \
    '</manifest>' >"$repo_path/android/app/src/main/AndroidManifest.xml"
  printf '%s\n' \
    'throw GradleException("Release signing is not configured.")' \
    'gradle.taskGraph.whenReady {}' \
    >"$repo_path/android/app/build.gradle.kts"
  printf '%s\n' '{}' >"$repo_path/android/app/google-services.json.example"
  printf '%s\n' '<plist/>' \
    >"$repo_path/ios/Runner/GoogleService-Info.plist.example"
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

git -C "$memory_impl_repo" commit -qm 'implementation with execution memory'
memory_range_base=$(git -C "$memory_impl_repo" rev-parse HEAD^)
"$memory_impl_repo/scripts/check-project-memory.sh" --range "$memory_range_base" >/dev/null || \
  fail 'an implementation range with execution evidence was rejected'

printf '%s\n' 'void additionalChange() {}' >>"$memory_impl_repo/lib/change.dart"
git -C "$memory_impl_repo" add lib/change.dart
git -C "$memory_impl_repo" commit -qm 'implementation without execution memory'
if "$memory_impl_repo/scripts/check-project-memory.sh" --range HEAD^ >/dev/null 2>&1; then
  fail 'an implementation range passed without an execution update'
fi

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
assert_native_failure \
  "$native_flag_repo" \
  'pubspec.yaml must keep the V1 iOS graph on CocoaPods' \
  'native-flag'

native_marker_repo="$governance_temp_root/native-marker"
initialize_native_repo "$native_marker_repo" false true
assert_native_failure \
  "$native_marker_repo" \
  'tracked iOS source contains generated Flutter SwiftPM integration' \
  'native-marker'

native_root_resolution_repo="$governance_temp_root/native-root-resolution"
initialize_native_repo "$native_root_resolution_repo"
printf '%s\n' '{}' >"$native_root_resolution_repo/ios/Package.resolved"
git -C "$native_root_resolution_repo" add ios/Package.resolved
assert_native_failure \
  "$native_root_resolution_repo" \
  'a generated SwiftPM resolution file is tracked under ios/' \
  'native-root-resolution'

native_nested_resolution_repo="$governance_temp_root/native-nested-resolution"
initialize_native_repo "$native_nested_resolution_repo"
mkdir -p "$native_nested_resolution_repo/ios/Runner.xcworkspace/xcshareddata/swiftpm"
printf '%s\n' '{}' \
  >"$native_nested_resolution_repo/ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved"
git -C "$native_nested_resolution_repo" add \
  ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved
assert_native_failure \
  "$native_nested_resolution_repo" \
  'a generated SwiftPM resolution file is tracked under ios/' \
  'native-nested-resolution'

native_share_pod_repo="$governance_temp_root/native-share-pod"
initialize_native_repo "$native_share_pod_repo"
printf '%s\n' \
  'PODS:' \
  '  - url_launcher_ios (0.0.1):' \
  '  - app_links (7.0.0):' \
  '  - firebase_auth (6.6.1):' \
  '  - flutter_facebook_auth (7.1.5):' \
  '  - google_sign_in_ios (0.0.1):' \
  '  - shared_preferences_foundation (0.0.1):' \
  >"$native_share_pod_repo/ios/Podfile.lock"
assert_native_failure \
  "$native_share_pod_repo" \
  'ios/Podfile.lock is missing share_plus (0.0.1)' \
  'native-share-pod'

native_url_pod_repo="$governance_temp_root/native-url-pod"
initialize_native_repo "$native_url_pod_repo"
printf '%s\n' \
  'PODS:' \
  '  - share_plus (0.0.1):' \
  '  - app_links (7.0.0):' \
  '  - firebase_auth (6.6.1):' \
  '  - flutter_facebook_auth (7.1.5):' \
  '  - google_sign_in_ios (0.0.1):' \
  '  - shared_preferences_foundation (0.0.1):' \
  >"$native_url_pod_repo/ios/Podfile.lock"
assert_native_failure \
  "$native_url_pod_repo" \
  'ios/Podfile.lock is missing url_launcher_ios (0.0.1)' \
  'native-url-pod'

native_android_debug_signing_repo="$governance_temp_root/native-android-debug-signing"
initialize_native_repo "$native_android_debug_signing_repo"
printf '%s\n' 'signingConfig = signingConfigs.getByName("debug")' \
  >>"$native_android_debug_signing_repo/android/app/build.gradle.kts"
assert_native_failure \
  "$native_android_debug_signing_repo" \
  'the Android release build still uses debug signing' \
  'native-android-debug-signing'

native_android_aggregate_signing_repo="$governance_temp_root/native-android-aggregate-signing"
initialize_native_repo "$native_android_aggregate_signing_repo"
sed -i.bak '/gradle.taskGraph.whenReady/d' \
  "$native_android_aggregate_signing_repo/android/app/build.gradle.kts"
assert_native_failure \
  "$native_android_aggregate_signing_repo" \
  'an aggregate Android build can bypass the release signing gate' \
  'native-android-aggregate-signing'

native_android_link_repo="$governance_temp_root/native-android-link"
initialize_native_repo "$native_android_link_repo"
printf '%s\n' \
  '<manifest>' \
  'android.permission.INTERNET' \
  'android:autoVerify="true"' \
  'android:host="auth.chantsfc.com"' \
  'android:host="chantsfc.com"' \
  'android:pathPrefix="/chants/"' \
  'android:pathPrefix="/performances/"' \
  'android:pathPrefix="/creators/"' \
  '</manifest>' >"$native_android_link_repo/android/app/src/main/AndroidManifest.xml"
assert_native_failure \
  "$native_android_link_repo" \
  'the Android app-link contract is missing android:pathPrefix="/finish-sign-in"' \
  'native-android-link'

native_git_error_repo="$governance_temp_root/native-git-error"
initialize_native_repo "$native_git_error_repo"
native_fake_bin="$governance_temp_root/native-fake-bin"
mkdir -p "$native_fake_bin"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'for native_git_arg in "$@"; do' \
  '  if [ "$native_git_arg" = ls-files ]; then' \
  '    exit 2' \
  '  fi' \
  'done' \
  'exec "$GOVERNANCE_REAL_GIT" "$@"' \
  >"$native_fake_bin/git"
chmod +x "$native_fake_bin/git"
governance_real_git=$(command -v git)
native_git_error_output="$governance_temp_root/native-git-error.stderr"
if PATH="$native_fake_bin:$PATH" \
  GOVERNANCE_REAL_GIT="$governance_real_git" \
  "$native_git_error_repo/scripts/check-native-project.sh" \
  >/dev/null 2>"$native_git_error_output"; then
  fail 'a Git ls-files error was treated as no tracked SwiftPM resolution'
fi
if ! grep -Fx \
  'Native project contract failed: tracked iOS source could not be scanned for SwiftPM resolution files' \
  "$native_git_error_output" >/dev/null 2>&1; then
  fail 'the Git ls-files error failed at the wrong native-contract boundary'
fi

echo 'Project governance regressions pass.'
