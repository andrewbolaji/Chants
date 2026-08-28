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

for native_pod in \
  'share_plus (0.0.1)' \
  'url_launcher_ios (0.0.1)' \
  'app_links (' \
  'firebase_auth (' \
  'flutter_facebook_auth (' \
  'google_sign_in_ios (' \
  'shared_preferences_foundation ('; do
  if ! grep -F "$native_pod" "$native_project_root/ios/Podfile.lock" >/dev/null 2>&1; then
    native_fail "ios/Podfile.lock is missing $native_pod"
  fi
done

if ! grep -F 'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;' \
  "$native_project_root/ios/Runner.xcodeproj/project.pbxproj" >/dev/null 2>&1; then
  native_fail 'the iOS target is missing the reviewed Runner entitlements'
fi

for native_entitlement in \
  'com.apple.developer.applesignin' \
  'applinks:auth.chantsfc.com' \
  'applinks:chantsfc.com'; do
  if ! grep -F "$native_entitlement" \
    "$native_project_root/ios/Runner/Runner.entitlements" >/dev/null 2>&1; then
    native_fail "Runner.entitlements is missing $native_entitlement"
  fi
done

if ! grep -F 'android.permission.INTERNET' \
  "$native_project_root/android/app/src/main/AndroidManifest.xml" >/dev/null 2>&1; then
  native_fail 'the Android app is missing the INTERNET permission'
fi

for native_app_link_part in \
  'android:autoVerify="true"' \
  'android:host="auth.chantsfc.com"' \
  'android:pathPrefix="/finish-sign-in"' \
  'android:host="chantsfc.com"' \
  'android:pathPrefix="/chants/"' \
  'android:pathPrefix="/performances/"' \
  'android:pathPrefix="/creators/"'; do
  if ! grep -F "$native_app_link_part" \
    "$native_project_root/android/app/src/main/AndroidManifest.xml" >/dev/null 2>&1; then
    native_fail "the Android app-link contract is missing $native_app_link_part"
  fi
done

if grep -F 'signingConfig = signingConfigs.getByName("debug")' \
  "$native_project_root/android/app/build.gradle.kts" >/dev/null 2>&1; then
  native_fail 'the Android release build still uses debug signing'
fi

if ! grep -F 'Release signing is not configured.' \
  "$native_project_root/android/app/build.gradle.kts" >/dev/null 2>&1; then
  native_fail 'the Android release signing boundary is not fail-closed'
fi

if ! grep -F 'gradle.taskGraph.whenReady' \
  "$native_project_root/android/app/build.gradle.kts" >/dev/null 2>&1; then
  native_fail 'an aggregate Android build can bypass the release signing gate'
fi

if [ ! -f "$native_project_root/android/app/google-services.json.example" ]; then
  native_fail 'the Android clean-build Firebase fixture is missing'
fi

if [ ! -f "$native_project_root/ios/Runner/GoogleService-Info.plist.example" ]; then
  native_fail 'the iOS clean-build Firebase fixture is missing'
fi

echo 'Native project contract passes.'
