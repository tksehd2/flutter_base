# New App Checklist

이 문서 하나만 보고 새 앱 브랜딩, 기능 설정, 빌드, 배포 준비까지 끝내는 것을 목표로 합니다.

## 0. 기본 초기화 명령 실행

권장 명령:

```bash
dart run tool/create_app.dart
```

비대화형 예시:

```bash
dart run tool/create_app.dart \
  --app-name "PlanB" \
  --bundle-id "com.example.planb" \
  --google-auth true \
  --google-drive true \
  --gemini false \
  --drift-db true \
  --dio-network true \
  --demo-mode false
```

이 CLI가 자동으로 처리하는 것:
- 앱 이름 rename 흐름 실행
- Bundle/Application ID rename 흐름 실행
- `app_manifest.yaml` 갱신
- `lib/app/config/app_features.dart` 갱신

## 1. 앱 기본 정보 확정

먼저 아래 항목을 확정하고 [`app_manifest.yaml`](/Users/tksehd2/Documents/flutter_proj/flutter_base/app_manifest.yaml) 에 기록합니다.

- 앱 이름
- Bundle ID / Application ID
- 켤 feature
- billing 필요 여부
- analytics 필요 여부
- backup 필요 여부
- 앱 리뷰나 데모 관련 메모

## 2. 앱 이름 / 패키지명 변경

### 수동 명령

```bash
dart pub global activate rename
dart pub global run rename setBundleId --targets ios,android --value "com.yourcompany.yourapp"
dart pub global run rename setAppName --targets ios,android --value "앱이름"
```

수정 후 확인:
- Android package name
- iOS bundle identifier
- 앱 런처 이름
- [`ios/ExportOptions.plist`](/Users/tksehd2/Documents/flutter_proj/flutter_base/ios/ExportOptions.plist) 안의 Bundle ID

## 3. 먼저 수정할 파일

아래 파일을 우선 수정합니다.

- [`app_manifest.yaml`](/Users/tksehd2/Documents/flutter_proj/flutter_base/app_manifest.yaml)
- [`lib/app/config/app_features.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/app/config/app_features.dart)
- [`lib/app/presentation/app_home_page.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/app/presentation/app_home_page.dart)
- [`pubspec.yaml`](/Users/tksehd2/Documents/flutter_proj/flutter_base/pubspec.yaml)
- [`ios/ExportOptions.plist`](/Users/tksehd2/Documents/flutter_proj/flutter_base/ios/ExportOptions.plist)

## 4. feature 선택

[`lib/app/config/app_features.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/app/config/app_features.dart) 에서 필요한 기능만 켭니다.

기본 플래그:
- `googleAuth`
- `googleDrive`
- `gemini`
- `driftDb`
- `dioNetwork`

권장 확인:
- Google 기능을 안 쓰면 `googleAuth`, `googleDrive`, `gemini` 를 같이 검토
- 로컬 저장이 필요 없으면 `driftDb` 검토
- 외부 API 호출이 거의 없으면 `dioNetwork` 검토

## 5. 브랜딩 자산 적용

- 앱 아이콘 교체
- 스플래시/런치 화면 확인
- 앱 설명/문구를 실제 앱에 맞게 수정

아이콘 생성:

```bash
dart run flutter_launcher_icons
```

주의:
- 아이콘 원본은 1024x1024 권장

## 6. Google / API 시크릿 설정

### 로컬/런타임

- `GOOGLE_SERVER_CLIENT_ID`

예:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
```

### Google 기능이 켜져 있으면 확인할 것

- OAuth Client ID가 올바른지
- Android SHA-1 등록이 되어 있는지
- 필요한 scope가 맞는지

SHA-1 확인:

```bash
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android
```

## 7. GitHub Actions 시크릿 설정

GitHub repo > `Settings > Secrets and variables > Actions`

### Android Secrets

- `KEYSTORE_BASE64`
- `KEY_ALIAS`
- `KEY_PASSWORD`
- `STORE_PASSWORD`

디버그 키스토어가 없다면:

```bash
keytool -genkey -v -keystore debug.keystore \
  -alias androiddebugkey \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass android -keypass android \
  -dname "CN=Android Debug,O=Android,C=US"
```

### iOS Secrets

- `P12_BASE64`
- `P12_PASSWORD`
- `PROVISIONING_PROFILE_BASE64`
- `PROVISIONING_PROFILE_NAME`
- `KEYCHAIN_PASSWORD`

### App Store Connect API

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_BASE64`

추가 확인:
- [`ios/ExportOptions.plist`](/Users/tksehd2/Documents/flutter_proj/flutter_base/ios/ExportOptions.plist) 의 team id / bundle id / 프로파일 이름 수정
- `.mobileprovision` 파일명과 내부 프로파일 이름을 동일하게 유지

프로파일 내부 이름 확인:

```bash
security cms -D -i your_profile.mobileprovision | plutil -extract Name raw -
```

## 8. 기능 검증

켜둔 기능만 검증하면 됩니다.

- Google Auth: 로그인 / 로그아웃 / 토큰 획득
- Google Drive: 업로드 / 메타데이터 조회 / 다운로드 / 삭제
- Gemini: 텍스트 요청 / 이미지 요청
- Drift: DB 생성 / 읽기 / 쓰기
- Dio: 기본 API 호출

중요:
- Gemini 와 Google Drive 는 토큰을 직접 받습니다.
- 호출부가 bearer token 획득 책임을 가집니다.

## 9. 코드/빌드 검증

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

## 10. Android 빌드 확인

로컬 AAB 빌드:

```bash
./build_aab.sh
```

동작:
- 현재 시각 기반 build number 사용
- AAB 빌드 완료 후 결과 폴더 열기

## 11. iOS 빌드/업로드 확인

로컬 TestFlight 업로드 스크립트:

```bash
./upload_testflight.sh
```

사전 확인:
- `~/private_keys/AuthKey_<API_KEY_ID>.p8` 존재
- [`ios/ExportOptions.plist`](/Users/tksehd2/Documents/flutter_proj/flutter_base/ios/ExportOptions.plist) 값이 현재 앱 기준인지
- provisioning profile / certificate / App Store Connect API 설정 완료

## 12. 최종 점검

- 앱 이름 / Bundle ID / Application ID가 모든 플랫폼에서 맞는지
- `app_manifest.yaml` 과 실제 feature flag 상태가 일치하는지
- billing / analytics / backup 기대치와 실제 구현 계획이 일치하는지
- 권한 문구 / 아이콘 / 앱 설명이 실제 앱 기준인지
- GitHub Actions로 Android/iOS 자동 빌드가 가능한지
- 스토어 제출 전 리뷰 노트가 필요한지
