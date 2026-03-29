#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_NUMBER=$(date +%s)
OUTPUT_DIR="$SCRIPT_DIR/build/app/outputs/bundle/release"

echo "🔨 AAB 빌드 시작 (build-number: $BUILD_NUMBER)..."
flutter build appbundle --release --build-number="$BUILD_NUMBER"

echo "📦 빌드 완료: $OUTPUT_DIR"

if [ -d "$OUTPUT_DIR" ]; then
  open "$OUTPUT_DIR"
fi
