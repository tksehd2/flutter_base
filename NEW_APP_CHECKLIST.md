# New App Checklist

이 문서 하나만 보고 새 앱 브랜딩, 기능 설정, 빌드, 배포 준비까지 끝내는 것을 목표로 합니다.

## 0. 앱 초기화 CLI 실행

### 대화형으로 진행

```bash
dart run tool/create_app.dart
```

앱 이름, Bundle/Application ID, 사용할 feature를 순서대로 입력합니다.

### 비대화형으로 진행

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
- [`app_manifest.yaml`](/Users/tksehd2/Documents/flutter_proj/flutter_base/app_manifest.yaml) 갱신
- [`lib/app/config/app_features.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/app/config/app_features.dart) 갱신

기능 구성이 바뀌면 수동으로 두 파일을 따로 고치기보다 CLI를 다시 실행하는 쪽을 권장합니다.

## 1. 브랜딩 자산 적용

- 1024x1024 원본 아이콘을 `assets/icon/app_icon.png` 로 준비
- 아이콘 교체 후 아래 명령 실행
- 기본 placeholder 문구가 남아 있다면 [`lib/app/presentation/app_home_page.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/app/presentation/app_home_page.dart) 부터 수정
- 앱별로 스플래시/런치 화면이 필요하면 같이 점검

```bash
dart run flutter_launcher_icons
```

## 2. Google / API 설정

Google 기능을 켰다면 Google Cloud Platform 에서 아래 OAuth Client 를 준비합니다.

- Android
- iOS
- 웹 애플리케이션

`flutter run` 에 넣는 `GOOGLE_SERVER_CLIENT_ID` 는 GCP 의 "웹 애플리케이션" Client ID 입니다.

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
```

Google 기능을 켰다면 최소 확인:

- 플랫폼별 OAuth Client 등록
- 웹 애플리케이션 Client ID 준비
- Android keystore SHA-1 등록

Android debug keystore SHA-1 확인:

```bash
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android
```

release keystore 를 따로 쓰면 그 SHA-1 도 GCP 에 추가합니다.

## 3. GitHub Actions 시크릿 설정

GitHub repo > `Settings > Secrets and variables > Actions`

### Android signing secrets

| Secret            | 값                               |
| ----------------- | ------------------------------- |
| `KEYSTORE_BASE64` | base64 -i debug.keystore        |
| `KEY_ALIAS`       | 디버그 키스토어 기본값: `androiddebugkey` |
| `KEY_PASSWORD`    | 디버그 키스토어 기본값: `android`         |
| `STORE_PASSWORD`  | 디버그 키스토어 기본값: `android`         |

키스토어가 없다면:

```bash
keytool -genkey -v -keystore debug.keystore \
  -alias androiddebugkey \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass android -keypass android \
  -dname "CN=Android Debug,O=Android,C=US"
```

Base64 인코딩 예시:

```bash
base64 -i debug.keystore | tr -d '\n'
```

### iOS signing secrets

| Secret                        | 값                                                       |
| ----------------------------- | ------------------------------------------------------- |
| `P12_BASE64`                  | base64 -i distribution.p12                              |
| `P12_PASSWORD`                | `distribution.p12` 생성 시 넣은 비밀번호                         |
| `PROVISIONING_PROFILE_BASE64` | base64 -i your_profile.mobileprovision                  |
| `PROVISIONING_PROFILE_NAME`   | 프로파일 내부 이름. 예: `your_app_provision`                     |
| `KEYCHAIN_PASSWORD`           | GitHub Actions 임시 keychain 비밀번호. 예: `your_app_keychain` |

### App Store Connect API secrets

| Secret                             | 값                             |
| ---------------------------------- | ----------------------------- |
| `APP_STORE_CONNECT_API_KEY_ID`     | App Store Connect API Key ID  |
| `APP_STORE_CONNECT_ISSUER_ID`      | App Store Connect Issuer ID   |
| `APP_STORE_CONNECT_API_KEY_BASE64` | base64 -i AuthKey_<KEY_ID>.p8 |

API Key 발급:

- App Store Connect > 사용자 및 액세스 > 통합 > 키
- `+` > 역할 `Developer` 이상 > `.p8` 다운로드
- `.p8` 파일은 한 번만 다운로드 가능

iOS 추가 확인:

- [`ios/ExportOptions.plist`](/Users/tksehd2/Documents/flutter_proj/flutter_base/ios/ExportOptions.plist) 의 `teamID`, bundle id, 프로파일 이름 수정
- `.mobileprovision` 파일명과 내부 프로파일 이름을 동일하게 유지
- `PROVISIONING_PROFILE_NAME` 은 내부 프로파일 이름과 동일하게 입력

프로파일 내부 이름 확인:

```bash
security cms -D -i your_profile.mobileprovision | plutil -extract Name raw -
```

P12 생성 절차 예시:

```bash
openssl genrsa -out distribution.key 2048
openssl req -new -key distribution.key -out distribution.csr -subj "/emailAddress=your@email.com/CN=Your Name/C=KR"
openssl x509 -inform DER -in distribution.cer -out distribution.pem
openssl pkcs12 -export -out distribution.p12 -inkey distribution.key -in distribution.pem
```

Provisioning Profile 생성 순서:

1. Apple Developer > Devices 에서 테스트 기기 UDID 등록
2. Apple Developer > Identifiers 에서 App ID 등록
3. Apple Developer > Profiles 에서 목적에 맞는 프로파일 생성 후 다운로드

기기 추가 후 프로파일을 다시 생성했다면 `PROVISIONING_PROFILE_BASE64` 와 `PROVISIONING_PROFILE_NAME` 도 같이 갱신합니다.

## 4. 기능 검증

켜둔 기능만 검증하면 됩니다.

구조/의존성 규칙은 [`lib/features/README.md`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/features/README.md) 를 같이 봅니다.

- Google Auth: 로그인 / 로그아웃 / 토큰 획득
- Google Drive: 업로드 / 메타데이터 조회 / 다운로드 / 삭제
- Gemini: 텍스트 요청 / 이미지 요청
- Drift: DB 생성 / 읽기 / 쓰기
- Dio: 기본 API 호출
- Demo Mode: 데모 모드 진입 조건과 노출 여부

중요:

- Gemini 와 Google Drive 는 토큰을 직접 받습니다.
- 호출부가 bearer token 획득 책임을 가집니다.

## 5. 코드 검증

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

## 6. Android 배포용 AAB 생성

로컬 릴리즈 AAB 생성:

```bash
./build_aab.sh
```

동작:

- 현재 시각 기반 build number 사용
- AAB 빌드 완료 후 결과 폴더 열기

이 단계는 검증용이 아니라 배포용 산출물 생성입니다.

## 7. iOS TestFlight 업로드

로컬에서 바로 TestFlight 업로드:

```bash
./upload_testflight.sh
```

사전 확인:

- `~/private_keys/AuthKey_<API_KEY_ID>.p8` 존재
- [`ios/ExportOptions.plist`](/Users/tksehd2/Documents/flutter_proj/flutter_base/ios/ExportOptions.plist) 값이 현재 앱 기준인지
- provisioning profile / certificate / App Store Connect API 설정 완료

이 단계는 단순 빌드 확인이 아니라 실제 업로드 흐름입니다.

## 8. 최종 점검

- 앱 이름 / Bundle ID / Application ID가 모든 플랫폼에서 맞는지
- 권한 문구 / 아이콘 / 앱 설명이 실제 앱 기준인지
- Google 기능을 켰다면 실제 계정으로 로그인/토큰/권한 흐름이 되는지
- GitHub Actions로 Android/iOS 자동 빌드와 업로드가 가능한지
- 스토어 제출 전 리뷰 노트가 필요한지
