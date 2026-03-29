# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains the Flutter app entrypoint and reusable services. Keep startup wiring in `lib/main.dart` and place cross-cutting integrations in `lib/services/` such as `google_auth_service.dart`, `google_drive_service.dart`, and `gemini_api_service.dart`. Native platform configuration lives in `android/` and `ios/`. CI is defined in `.github/workflows/deploy.yml`. Project metadata and dependencies are managed in `pubspec.yaml`; static analysis rules live in `analysis_options.yaml`.

## Build, Test, and Development Commands
Run `flutter pub get` after changing dependencies. Use `flutter run` for local development on a connected simulator or device. Check code health with `flutter analyze`. Produce artifacts with `flutter build apk --debug` or `flutter build apk --release`. Regenerate derived files with `dart run build_runner build --delete-conflicting-outputs` when code generation is introduced or updated. Refresh launcher icons with `dart run flutter_launcher_icons`.

## Coding Style & Naming Conventions
Follow the default `flutter_lints` rules from `analysis_options.yaml`. Use 2-space indentation and keep files formatted with `dart format .` before review. Name Dart files in `snake_case.dart`, classes and enums in `UpperCamelCase`, and methods, variables, and parameters in `lowerCamelCase`. Prefer small service-focused files and expose shared imports through barrel files only when they reduce duplication clearly.

## Testing Guidelines
This repository does not currently include a committed `test/` suite, so new features should add focused widget or unit tests under `test/` as they are introduced. Mirror the source name in test files, for example `lib/services/google_auth_service.dart` -> `test/services/google_auth_service_test.dart`. Run `flutter test` locally before opening a PR.

## Commit & Pull Request Guidelines
Recent history uses short one-line subjects such as `fix` and `readme.md 강화`. Keep commits concise, scoped, and imperative; prefer clearer summaries like `add Drive restore guard` over vague messages. PRs should include a short description, affected platforms (`android`, `ios`, or both), linked issues when applicable, and screenshots or recordings for UI changes. If a change touches signing, secrets, or CI release behavior, call that out explicitly.

## Security & Configuration Tips
Do not commit secrets or local signing files. OAuth, keystore, and release settings should stay in GitHub Secrets or external key/property files as described in `README.md`. When cloning this template for a new app, update the bundle ID, app name, and service configuration in `main.dart` before shipping builds.
