# Features Guide

`features/` 는 이 템플릿에서 선택적으로 켜고 끌 수 있는 기능을 둡니다.

## 무엇을 `features/` 에 두는가

- Google Auth, Google Drive, Gemini 같은 외부 연동 기능
- 특정 앱에서 아예 빠질 수 있는 제품 기능
- feature별 `data/`, `providers/`, `presentation/` 코드

## 무엇을 `core/` 에 두는가

- 대부분의 앱에서 계속 쓰는 공통 인프라
- 공통 DB 기반, 공통 네트워크 클라이언트, 공통 provider
- 특정 기능이 아니라 여러 기능이 공유하는 기반 코드

## 의존성 규칙

- feature는 가능하면 다른 feature를 직접 import하지 않습니다.
- 공통 코드는 `core/` 나 `app/` 를 통해 연결합니다.
- startup wiring 은 feature 내부에서 하지 않고 `app/bootstrap` 에서만 연결합니다.
- 외부에서 사용할 진입점이 필요하면 가능하면 `providers/` 와 feature barrel을 먼저 만듭니다.

## 인증/토큰 규칙

- 가능하면 feature가 직접 인증을 수행하지 않습니다.
- bearer token 이 필요한 feature는 호출부가 토큰 획득 책임을 가집니다.
- 예: Gemini, Google Drive 호출 전에 provider/use case/UI 쪽에서 토큰을 준비해서 넘기는 구조를 우선합니다.
- 즉, Gemini 와 Google Drive 같은 기능은 GoogleAuth feature를 직접 호출하기보다, 호출부에서 받은 토큰을 인자로 받는 구조를 우선합니다.

## 폴더 규칙

권장 구조:

```text
features/<feature_name>/
├── <feature_name>.dart
├── data/
├── providers/
└── presentation/
```

- `<feature_name>.dart` 는 feature의 barrel 파일입니다.
- 외부 코드에서는 가능하면 내부 파일 경로 대신 barrel 또는 provider를 사용합니다.

## 새 feature 추가 순서

1. `features/<feature_name>/` 폴더 생성
2. 필요하면 `data/`, `providers/`, `presentation/` 하위 구조 사용
3. `<feature_name>.dart` barrel 추가
4. `app/config/app_features.dart` 에 플래그 추가
5. 초기화가 필요하면 `app/bootstrap/app_bootstrap.dart` 에 연결

## 피해야 할 것

- feature 내부에서 앱 시작 초기화 수행
- feature끼리 강한 직접 의존성 만들기
- 공통 인프라를 feature 폴더 안에 중복 생성하기
- 인증 토큰 획득 책임을 모든 feature 내부에 다시 넣기
