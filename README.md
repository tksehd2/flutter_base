# flutter_base

Flutter 앱 팩토리용 템플릿 저장소. 새 앱을 만들 때 이 저장소를 복제한 뒤, 필요한 기능만 켜고 나머지는 끄는 방식으로 시작합니다.

기본 초기화 명령:

```bash
dart run tool/create_app.dart
```

새 앱으로 시작할 때는 먼저 [`app_manifest.yaml`](/Users/tksehd2/Documents/flutter_proj/flutter_base/app_manifest.yaml) 과 [`NEW_APP_CHECKLIST.md`](/Users/tksehd2/Documents/flutter_proj/flutter_base/NEW_APP_CHECKLIST.md) 를 확인하세요.  
실제 브랜딩, 시크릿 설정, 빌드, 배포 준비 절차는 `NEW_APP_CHECKLIST.md` 하나를 기준으로 따라가면 됩니다.

## 구조 원칙

- `app/`: 앱 시작점, feature flag, 부트스트랩, production app shell
- `core/`: 대부분의 앱에서 계속 쓸 공통 인프라
- `features/`: 끄거나 뺄 수 있는 선택 기능

`core/` 에 두는 것:
- 공통 네트워크 클라이언트
- 공통 데이터베이스 기반
- 공통 provider
- 여러 앱에서 반복적으로 재사용될 인프라

`features/` 에 두는 것:
- Google Auth, Google Drive, Gemini 같은 선택 기능
- 앱별로 아예 빠질 수 있는 외부 연동/제품 기능
- feature별 provider, data, presentation 코드

Drift와 Dio는 지금 템플릿에서 선택적으로 끌 수는 있지만, 역할 자체는 제품 기능이 아니라 기반 인프라라서 `core/` 에 둡니다.  
`features/` 설계 규칙은 [`lib/features/README.md`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/features/README.md) 를 우선 기준으로 봅니다.

## 새 앱으로 복제할 때 먼저 볼 파일

- [`tool/create_app.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/tool/create_app.dart): 크로스플랫폼 앱 초기화 CLI
- [`app_manifest.yaml`](/Users/tksehd2/Documents/flutter_proj/flutter_base/app_manifest.yaml): 앱 이름, ID, feature 사용 여부, billing/analytics/backup 기대치
- [`NEW_APP_CHECKLIST.md`](/Users/tksehd2/Documents/flutter_proj/flutter_base/NEW_APP_CHECKLIST.md): 복제 후 실제 작업 순서와 세부 명령/설정 절차
- [`lib/app/config/app_features.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/app/config/app_features.dart): feature flag 단일 진입점
- [`lib/app/presentation/app_home_page.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/app/presentation/app_home_page.dart): 기본 앱 시작 화면
- [`lib/app/bootstrap/app_bootstrap.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/app/bootstrap/app_bootstrap.dart): 앱 시작 시 실제 초기화 위치

## 현재 구조

```text
lib/
├── main.dart
├── app/
│   ├── bootstrap/
│   │   └── app_bootstrap.dart
│   ├── config/
│   │   └── app_features.dart
│   └── presentation/
│       └── app_home_page.dart
├── core/
│   ├── core.dart
│   ├── database/
│   │   ├── app_database.dart
│   │   └── app_database.g.dart
│   ├── network/
│   │   └── app_dio.dart
│   └── providers/
│       └── app_providers.dart
└── features/
    ├── README.md
    ├── gemini/
    │   ├── gemini.dart
    │   ├── data/
    │   │   └── gemini_api_service.dart
    │   └── providers/
    │       └── gemini_providers.dart
    ├── google_auth/
    │   ├── google_auth.dart
    │   ├── data/
    │   │   └── google_auth_service.dart
    │   └── providers/
    │       └── google_auth_providers.dart
    └── google_drive/
        ├── google_drive.dart
        ├── data/
        │   └── google_drive_service.dart
        └── providers/
            └── google_drive_providers.dart
```

## Feature Flags

중앙 플래그는 [`lib/app/config/app_features.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/app/config/app_features.dart) 에서 관리합니다.

기본 플래그:
- `googleAuth`
- `googleDrive`
- `gemini`
- `driftDb`
- `dioNetwork`

실제 동작에는 의존성을 반영한 effective getter 를 씁니다.
- `googleDriveEnabled = googleAuth && googleDrive`
- `geminiEnabled = googleAuth && gemini`

기능을 끄려면 한 곳만 바꾸면 됩니다.

```dart
static const bool gemini = false;
```

CLI로도 같은 항목을 바꿀 수 있습니다.

```bash
dart run tool/create_app.dart --app-name "PlanB" --bundle-id "com.example.planb" --gemini false
```

## 기능이 꺼질 때 동작

- `googleAuth`: bootstrap 에서 초기화하지 않음, auth provider/service 접근 시 `UnsupportedError`
- `googleDrive`: OAuth scope 에서 빠짐, provider/service 접근 시 `UnsupportedError`
- `gemini`: bootstrap 에서 초기화하지 않음, provider/service 접근 시 `UnsupportedError`
- `driftDb`: provider 접근 차단
- `dioNetwork`: provider 접근 차단

## 앱 시작 흐름

`main.dart` 는 얇게 유지합니다.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppBootstrap.initialize();
  runApp(const ProviderScope(child: MyApp()));
}
```

초기화는 [`lib/app/bootstrap/app_bootstrap.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/app/bootstrap/app_bootstrap.dart) 에만 둡니다. 새 기능을 추가할 때도 startup wiring 은 여기로 모읍니다.

## Production App Shell

[`lib/app/presentation/app_home_page.dart`](/Users/tksehd2/Documents/flutter_proj/flutter_base/lib/app/presentation/app_home_page.dart) 는 이제 기본 production 시작 화면입니다.

- enabled feature 상태를 보여줌
- 템플릿을 복제한 뒤 무엇을 먼저 바꿔야 하는지 안내함
- demo 전용 버튼/로그 화면 없이 실제 앱 출발점 역할을 함

가벼운 확장 포인트는 여기서 시작하는 것을 권장합니다.
- billing 진입 섹션
- analytics/privacy 안내 섹션
- 앱 설정 화면 진입점
- 앱 버전 / 빌드 번호 표시

이 항목들은 아직 시스템으로 만들어두지 않았고, 앱별 요구사항이 정해진 뒤 `app/` 또는 적절한 `features/` 아래에 추가하는 것을 권장합니다.

## 새 optional feature 추가 방법

예: Firebase Remote Config 같은 새 선택 기능을 넣는 경우

1. `lib/features/firebase_remote_config/` 폴더 생성
2. `data/`, 필요하면 `providers/`, `presentation/` 추가
3. `lib/features/firebase_remote_config/firebase_remote_config.dart` barrel 추가
4. `lib/app/config/app_features.dart` 에 플래그 추가
5. 초기화가 필요하면 `lib/app/bootstrap/app_bootstrap.dart` 에만 연결
6. 공통 인프라가 아니면 `core/` 에 넣지 않음

앱 전역 설정이나 앱별 메타데이터는 새 feature로 만들기 전에 먼저 `app_manifest.yaml` 에 기록해 두는 편이 좋습니다.

## 공통 사용 예시

```dart
import 'package:flutter_base/core/core.dart';
import 'package:flutter_base/features/google_auth/google_auth.dart';
import 'package:flutter_base/features/gemini/gemini.dart';
import 'package:flutter_base/features/google_drive/google_drive.dart';

final db = ref.read(appDatabaseProvider);
final dio = ref.read(dioProvider);

final user = await ref.read(googleAuthStateProvider.notifier).signIn();
final accessToken = await ref.read(googleAccessTokenProvider.future) ?? '';

final text = await ref.read(geminiApiServiceProvider).generateText(
  prompt: '질문',
  accessToken: accessToken,
);

final folderId = await ref.read(googleDriveServiceProvider).getOrCreateFolder(
  accessToken: accessToken,
  folderName: 'MyAppFiles',
);
```

Gemini 와 Google Drive 는 bearer token 을 직접 받습니다. 토큰 획득 책임은 호출부에 있습니다.

빌드/배포 명령, 시크릿 설정, 앱 이름/Bundle ID 변경 절차는 [`NEW_APP_CHECKLIST.md`](/Users/tksehd2/Documents/flutter_proj/flutter_base/NEW_APP_CHECKLIST.md) 에 모아두었습니다. 기본 경로는 `tool/create_app.dart` 입니다.
