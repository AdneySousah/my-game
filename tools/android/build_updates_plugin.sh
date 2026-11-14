#!/usr/bin/env bash
# Builds the Android plugin that checks Google Play for a new version of the game
# (addons/HerdeiroUpdates/bin/HerdeiroUpdates.aar). Only needed when
# tools/android/updates/src changes; the AAR is committed.
#
#   bash tools/android/build_updates_plugin.sh
#
# Steps: Gradle downloads the Play In-App Update library (to compile against it), javac
# compiles the plugin against it, Godot's Android library and android.jar, and the classes
# plus the manifest are zipped as an AAR. The game's export adds the library itself
# (addons/HerdeiroUpdates/export_plugin.gd).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
JDK="${JAVA_HOME:-/c/Users/assantos/AppData/Local/Programs/jdk-17.0.21+9}"
SDK="${ANDROID_HOME:-/c/Users/assantos/AppData/Local/Android/Sdk}"
SRC="$ROOT/tools/android/updates"
WORK="$ROOT/build/updates_plugin"
OUT="$ROOT/addons/HerdeiroUpdates/bin/HerdeiroUpdates.aar"
export JAVA_HOME="$JDK"

rm -rf "$WORK"
mkdir -p "$WORK/fetch" "$WORK/cp" "$WORK/classes" "$WORK/aar"
cp "$SRC/fetch/build.gradle" "$SRC/fetch/settings.gradle" "$WORK/fetch/"
"$ROOT/android/build/gradlew" -p "$WORK/fetch" grab -q -Dorg.gradle.daemon=false

# Compile classpath: android.jar, Godot's library and the classes inside each downloaded AAR/JAR.
# javac is a Windows program: every entry goes as a Windows path, joined with ";".
win() { cygpath -w "$1" 2>/dev/null || echo "$1"; }
CP="$(win "$SDK/platforms/android-36/android.jar")"
unzip -o -q "$ROOT/android/build/libs/release/godot-lib.template_release.aar" classes.jar -d "$WORK/cp/godot"
CP="$CP;$(win "$WORK/cp/godot/classes.jar")"
for f in "$WORK/fetch/libs/"*; do
	name="$(basename "$f")"
	case "$name" in
		*.aar) unzip -o -q "$f" classes.jar -d "$WORK/cp/$name" && CP="$CP;$(win "$WORK/cp/$name/classes.jar")" ;;
		*.jar) CP="$CP;$(win "$f")" ;;
	esac
done

"$JDK/bin/javac" --release 11 -nowarn -cp "$CP" -d "$WORK/classes" $(find "$SRC/src" -name '*.java')
"$JDK/bin/jar" --create --file "$WORK/aar/classes.jar" -C "$WORK/classes" .
cp "$SRC/AndroidManifest.xml" "$WORK/aar/AndroidManifest.xml"
: > "$WORK/aar/R.txt"
mkdir -p "$WORK/aar/META-INF/com/android/build/gradle"
printf 'aarFormatVersion=1.0\naarMetadataVersion=1.0\nminCompileSdk=1\nminCompileSdkExtension=0\nminAndroidGradlePluginVersion=1.0.0\ncoreLibraryDesugaringEnabled=false\n' \
	> "$WORK/aar/META-INF/com/android/build/gradle/aar-metadata.properties"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
"$JDK/bin/jar" --create --no-manifest --file "$OUT" -C "$WORK/aar" .
echo "PLUGIN_OK $OUT"
