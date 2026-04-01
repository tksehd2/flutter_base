#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_NUMBER=$(date +%s)
OUTPUT_DIR="$SCRIPT_DIR/build/app/outputs/bundle/release"
BUNDLE_ID=$(grep -m1 'applicationId *= *"' android/app/build.gradle.kts | sed -E 's/.*applicationId *= *"([^"]+)".*/\1/')

echo "🔨 AAB 빌드 시작 (build-number: $BUILD_NUMBER)..."
flutter build appbundle --release --build-number="$BUILD_NUMBER"

ARTIFACT_PATH=$(find "$OUTPUT_DIR" -maxdepth 1 -name "*.aab" | head -n 1)
if [ -n "$ARTIFACT_PATH" ]; then
  MARKER_PATH="$(dirname "$ARTIFACT_PATH")/${BUNDLE_ID}.${BUILD_NUMBER}.android"
  touch "$MARKER_PATH"
  echo "Created marker: $MARKER_PATH"
fi

echo "📦 빌드 완료: $OUTPUT_DIR"

if [ -d "$OUTPUT_DIR" ]; then
  open "$OUTPUT_DIR"
fi
