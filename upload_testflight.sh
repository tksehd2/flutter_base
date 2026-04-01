#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# p8 키 파일 확인
KEY_PATH=~/private_keys/AuthKey_UA7846SN46.p8
if [ ! -f "$KEY_PATH" ]; then
  echo "❌ $KEY_PATH 파일이 없습니다. .p8 키를 해당 경로에 넣어주세요."
  exit 1
fi

BUILD_NUMBER=$(date +%s)
IPA_DIR="$SCRIPT_DIR/build/ios/ipa"
BUNDLE_ID=$(grep -m1 'PRODUCT_BUNDLE_IDENTIFIER = ' ios/Runner.xcodeproj/project.pbxproj | sed -E 's/.*PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);/\1/')

echo "🔨 IPA 빌드 시작 (build-number: $BUILD_NUMBER)..."
flutter build ipa --release --build-number="$BUILD_NUMBER" --export-options-plist=ios/ExportOptions.plist

IPA_PATH=$(find "$IPA_DIR" -maxdepth 1 -name "*.ipa" | head -n 1)
if [ -n "$IPA_PATH" ]; then
  MARKER_PATH="$(dirname "$IPA_PATH")/${BUNDLE_ID}.${BUILD_NUMBER}.ios"
  touch "$MARKER_PATH"
  echo "Created marker: $MARKER_PATH"
fi

echo "🚀 App Store Connect 업로드 중..."
xcrun altool --upload-app \
  -f build/ios/ipa/*.ipa \
  -t ios \
  --apiKey UA7846SN46 \
  --apiIssuer 94e71d33-8698-4faa-a187-43ca74a4cadd

echo "✅ 완료!"
