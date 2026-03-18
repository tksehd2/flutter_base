# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter 앱 개발용 베이스 프로젝트. Google 로그인, Google Drive 백업/복구, Gemini API 연동이 포함된 템플릿.
새 프로젝트 시작 시 이 저장소를 복제하여 사용한다.

## Common Commands

```bash
flutter pub get                                    # 의존성 설치
flutter run                                        # 앱 실행
flutter build apk --debug                          # 디버그 APK 빌드
flutter build apk --release                        # 릴리즈 APK 빌드
flutter analyze                                    # 정적 분석
dart run build_runner build --delete-conflicting-outputs  # 코드 생성 (build_runner)
```

### 앱 이름/패키지명 변경 (Windows)
- `fix_app_name.bat` - 앱 표시 이름 변경 (rename 패키지 사용)
- `fix_package_name.bat` - Bundle ID 변경 (예: com.example.app)

## Architecture

### Services (`lib/services/`)
모든 서비스는 `configure()` → `factory` 싱글톤 패턴. `main()`에서 초기화, 이후 어디서든 `ServiceName()`으로 접근.
`lib/services/services.dart`가 barrel export 파일.

- **GoogleAuthService** - Google 로그인 및 OAuth 토큰 관리. `getAccessToken()`으로 다른 서비스에 토큰 공급.
- **GeminiApiService** - Gemini REST API 호출. 모델명 설정 가능. GoogleAuthService에서 Bearer 토큰을 받아 사용.
- **GoogleDriveService** - `appDataFolder`에 SQLite DB 백업/복구. `onBeforeRestore`/`onAfterRestore` 콜백으로 DB 연결 관리.

### 인증 흐름
GoogleAuthService가 모든 Google API 인증의 중심. `_currentUser`를 메모리에 유지하여 반복 로그인 팝업 방지.
`getAccessToken()` → `signInSilently()` (실패 시) → 수동 `signIn()` 필요.

## CI/CD

GitHub Actions (`.github/workflows/deploy.yml`): main 브랜치 push 시 디버그 APK 자동 빌드 후 GitHub Releases에 업로드.

필요한 GitHub Secrets:
- `KEYSTORE_BASE64` - Base64 인코딩된 키스토어 파일
- `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD` - 서명 정보

## Android Signing

`android/app/build.gradle.kts`에서 키스토어 설정을 두 경로로 분기:
1. 로컬 릴리즈: `../../build/android/key.properties` (프로젝트 외부)
2. GitHub Actions 디버그: `android/key.properties` (CI에서 생성)

릴리즈 빌드는 minify + shrinkResources 활성화, ProGuard 적용.

## Key Dependencies

- `google_sign_in` + `extension_google_sign_in_as_googleapis_auth` - Google OAuth
- `googleapis` - Drive API 클라이언트
- `http` - Gemini REST API 호출
- `provider` - 상태 관리
- `shared_preferences` - 로컬 키-값 저장
- `path_provider` - 앱 문서 디렉토리 접근

## Notes

- Dart SDK: ^3.11.1
- Android namespace: `com.toyapps.base.flutter_base`
- 린트: `package:flutter_lints/flutter.yaml` 사용
- 서비스 설정값(serverClientId, 모델명, 파일명 등)은 `main.dart`의 `configure()` 호출에서 관리
