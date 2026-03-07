# Repository Guidelines

## Project Structure & Module Organization
This repository is a Flutter + Firebase starter kit. App code lives in `lib/`, organized by feature so each area stays self-contained: `lib/features/auth`, `lib/features/onboarding`, `lib/features/paywall`, `lib/features/settings`, and `lib/features/notifications`. Shared app-wide code lives in `lib/shared/`, routing in `lib/routing/`, and runtime configuration in `lib/config/`. Tests mirror the app structure under `test/` (for example, `test/features/auth/services/`). Native platform files are in `android/` and `ios/`.

## Build, Test, and Development Commands
- `flutter pub get` installs dependencies.
- `flutter run --dart-define=ENV=dev` starts the app with the dev environment.
- `flutter build ios --dart-define=ENV=prod` builds a production iOS app.
- `flutter test` runs the full test suite.
- `flutter analyze` runs Dart analyzer checks with `flutter_lints` and `custom_lint`.
- `dart run build_runner build --delete-conflicting-outputs` regenerates code when Riverpod generators are involved.
- `flutterfire configure` syncs Firebase app configuration before local development.

## Coding Style & Naming Conventions
Follow standard Dart formatting: 2-space indentation, trailing commas where they improve formatting, and one class/widget per focused file. Use `UpperCamelCase` for types, `lowerCamelCase` for members, and `snake_case.dart` for filenames. Keep the existing feature-folder pattern and prefer Riverpod providers and service classes over large stateful widgets. Run `dart format .` before opening a PR.

## Testing Guidelines
Use `flutter_test` for unit and widget coverage, plus `fake_cloud_firestore`, `mockito`, and `mocktail` where appropriate. Place tests beside the matching feature area and name them with the `_test.dart` suffix, such as `auth_service_test.dart` or `router_test.dart`. Add or update tests for any routing, provider, service, or widget behavior you change.

## Commit & Pull Request Guidelines
Recent history follows Conventional Commit-style subjects such as `feat: add integration smoke test`. Keep commit messages short, imperative, and scoped when useful (`fix:`, `test:`, `docs:`). PRs should describe the user-visible change, note any Firebase or RevenueCat configuration impact, link the relevant issue, and include screenshots or recordings for UI changes.

## Configuration & Security Notes
Do not commit secrets. Review `lib/config/app_config.dart`, `lib/config/environment.dart`, and `lib/config/theme.dart` when bootstrapping a new app, and keep environment selection explicit with `--dart-define=ENV=...`.
