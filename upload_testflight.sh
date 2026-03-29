#!/bin/bash
set -e

# p8 키 파일 확인
KEY_PATH=~/private_keys/AuthKey_UA7846SN46.p8
if [ ! -f "$KEY_PATH" ]; then
  echo "❌ $KEY_PATH 파일이 없습니다. .p8 키를 해당 경로에 넣어주세요."
  exit 1
fi

BUILD_NUMBER=$(date +%s)

echo "🔨 IPA 빌드 시작 (build-number: $BUILD_NUMBER)..."
flutter build ipa --release --build-number="$BUILD_NUMBER" --export-options-plist=ios/ExportOptions.plist

echo "🚀 App Store Connect 업로드 중..."
xcrun altool --upload-app \
  -f build/ios/ipa/*.ipa \
  -t ios \
  --apiKey UA7846SN46 \
  --apiIssuer 94e71d33-8698-4faa-a187-43ca74a4cadd

echo "✅ 완료!"
