#!/usr/bin/env bash
# Builds the Android version of the game (run from Git Bash, in the project folder).
#
#   bash tools/build/build_android.sh            -> build/android/herdeiro.aab (Google Play)
#   bash tools/build/build_android.sh apk        -> build/android/herdeiro.apk (install by cable)
#   bash tools/build/build_android.sh apk debug  -> build/android/herdeiro-debug.apk (F1/F2 debug keys)
#
# The upload key never lives in the project. Its folder (default below, or HERDEIRO_KEY_DIR)
# holds upload.keystore and assinatura.properties with three lines: path=..., user=...,
# password=... The values reach Godot through its environment variables.
#
# Before each new upload to Google Play, raise version/code in export_presets.cfg (Play refuses
# a code it has already seen).
#
# Not a Python script on purpose: the Python from the Microsoft Store / install manager runs
# its child processes in an app container that hides %LOCALAPPDATA%\Android from Godot.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="/c/Godot/Godot_v4.7.2-stable_win64_console.exe"
KEY_DIR="${HERDEIRO_KEY_DIR:-/c/Users/assantos/Documents/HerdeiroDosCeus_chave}"
KIND="${1:-aab}"
MODE="${2:-release}"
PRESETS="$ROOT/export_presets.cfg"

suffix=""
[ "$MODE" = "debug" ] && suffix="-debug"
OUT="$ROOT/build/android/herdeiro$suffix.$KIND"
mkdir -p "$ROOT/build/android"
rm -f "$OUT"

if [ "$MODE" != "debug" ]; then
	prop() { grep "^$1=" "$KEY_DIR/assinatura.properties" | head -1 | cut -d= -f2- | tr -d '\r'; }
	export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$(prop path)"
	export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$(prop user)"
	export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(prop password)"
fi

# export_format: 0 = apk, 1 = aab. The file always goes back to aab afterwards.
fmt=1
[ "$KIND" = "apk" ] && fmt=0
sed -i "s#^gradle_build/export_format=.*#gradle_build/export_format=$fmt#" "$PRESETS"
trap 'sed -i "s#^gradle_build/export_format=.*#gradle_build/export_format=1#" "$PRESETS"' EXIT

# No Gradle daemon: a daemon left running keeps the console open and the script never ends.
export GRADLE_OPTS="${GRADLE_OPTS:-} -Dorg.gradle.daemon=false"

flag="--export-release"
[ "$MODE" = "debug" ] && flag="--export-debug"
"$GODOT" --headless --path "$ROOT" --install-android-build-template "$flag" Android "$OUT" || true

if [ -f "$OUT" ]; then
	echo "BUILD_OK $OUT"
else
	echo "BUILD_FAILED"
	exit 1
fi
