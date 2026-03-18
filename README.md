# flutter_base

Flutter 앱 개발을 위한 베이스 프로젝트.
새 앱을 만들 때 이 저장소를 복제하여 시작합니다.

---

## 기술 스택

| 모듈 | 패키지 | 설명 |
|------|---------|------|
| **Google 로그인** | `google_sign_in` | Google OAuth 인증 및 토큰 관리 |
| **Gemini API** | `http` | Gemini REST API를 통한 AI 텍스트 생성 |
| **Google Drive 백업** | `googleapis` | appDataFolder를 이용한 DB 백업/복구 |
| **상태 관리** | `provider` | ChangeNotifier 기반 상태 관리 |
| **로컬 저장소** | `shared_preferences` | 키-값 기반 경량 데이터 저장 |
| **파일 시스템** | `path_provider`, `path` | 앱 문서 디렉토리 접근 |
| **UI 유틸** | `auto_size_text`, `cupertino_icons`, `sign_in_button` | 자동 크기 텍스트, 아이콘, 로그인 버튼 |
| **앱 정보** | `package_info_plus` | 앱 버전/빌드 번호 조회 |

---

## 프로젝트 구조

```
lib/
├── main.dart                        # 앱 진입점 및 서비스 초기화
└── services/
    ├── services.dart                # barrel export
    ├── google_auth_service.dart     # Google 로그인 / 토큰 관리
    ├── gemini_api_service.dart      # Gemini API 호출
    └── google_drive_service.dart    # Drive 백업/복구
```

---

## 시작하기

### 1. 저장소 복제 후 패키지명/앱 이름 변경

```bash
# 패키지명(Bundle ID) 변경
fix_package_name.bat    # Windows
# 또는 수동으로:
dart pub global activate rename
dart pub global run rename setBundleId --targets ios,android --value "com.yourcompany.yourapp"

# 앱 이름 변경
fix_app_name.bat        # Windows
# 또는 수동으로:
dart pub global run rename setAppName --targets ios,android --value "앱이름"
```

### 2. 서비스 초기화 (`main.dart`)

모든 서비스는 `configure()`로 초기화한 뒤 `factory` 생성자로 어디서든 접근합니다.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleAuthService.configure(
    serverClientId: 'YOUR_CLIENT_ID.apps.googleusercontent.com',
    scopes: ['https://www.googleapis.com/auth/drive.appdata'],
  );

  GeminiApiService.configure(model: 'gemini-2.5-flash');

  GoogleDriveService.configure(
    backupFileName: 'my_backup.sqlite',
    localDbFileName: 'my_db.sqlite',
    onBeforeRestore: () async => db.close(),
    onAfterRestore: () async => db.reopen(),
  );

  runApp(const MyApp());
}
```

### 3. 서비스 사용

```dart
import 'package:flutter_base/services/services.dart';

// Google 로그인
final user = await GoogleAuthService().signIn();

// Gemini API 호출
final result = await GeminiApiService().generateContent(prompt: '질문');

// Drive 백업 / 복구
await GoogleDriveService().backupDatabase();
await GoogleDriveService().restoreDatabase();
```

---

## 빌드 명령어

```bash
flutter pub get                                            # 의존성 설치
flutter run                                                # 앱 실행
flutter build apk --debug                                  # 디버그 APK 빌드
flutter build apk --release                                # 릴리즈 APK 빌드
flutter analyze                                            # 정적 분석
dart run build_runner build --delete-conflicting-outputs    # 코드 생성
```

---

## CI/CD (GitHub Actions)

`main` 브랜치에 push하면 GitHub Actions가 디버그 APK를 자동 빌드하여 **GitHub Releases**에 업로드합니다.

### GitHub Secrets 설정

아래 4개의 Secret을 **Repository Settings > Secrets and variables > Actions**에 등록해야 합니다.

| Secret 이름 | 설명 | 값 생성 방법 |
|-------------|------|-------------|
| `KEYSTORE_BASE64` | 디버그 키스토어 파일을 Base64로 인코딩한 문자열 | `base64 -w 0 debug.keystore` (Linux/Mac) 또는 `certutil -encode debug.keystore encoded.txt` (Windows) |
| `KEY_ALIAS` | 키스토어 별칭 | 디버그 키스토어 기본값: `androiddebugkey` |
| `KEY_PASSWORD` | 키 비밀번호 | 디버그 키스토어 기본값: `android` |
| `STORE_PASSWORD` | 키스토어 비밀번호 | 디버그 키스토어 기본값: `android` |

### 디버그 키스토어 생성

기본 디버그 키스토어가 없는 경우 아래 명령어로 생성합니다.

```bash
keytool -genkey -v -keystore debug.keystore \
  -alias androiddebugkey \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass android -keypass android \
  -dname "CN=Android Debug,O=Android,C=US"
```

### 디버그 키스토어 해시 추출

Google Cloud Console에서 OAuth 클라이언트를 등록할 때 SHA-1 인증서 지문이 필요합니다.

```bash
# SHA-1 해시 추출
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android

# 출력에서 "SHA1:" 줄의 값을 복사하여 Google Cloud Console에 등록
```

---

## 앱 아이콘 변경

`pubspec.yaml`의 `flutter_launcher_icons` 설정에서 아이콘 경로를 수정한 뒤:

```bash
dart run flutter_launcher_icons
```

---

## Android 서명 구조

| 환경 | key.properties 경로 | 용도 |
|------|---------------------|------|
| 로컬 릴리즈 빌드 | `../../build/android/key.properties` (프로젝트 외부) | 릴리즈 APK 서명 |
| GitHub Actions | `android/key.properties` (CI에서 자동 생성) | 디버그 APK 서명 |

릴리즈 빌드는 ProGuard + minify + shrinkResources가 활성화되어 있습니다.
