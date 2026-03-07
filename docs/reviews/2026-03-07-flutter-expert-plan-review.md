# Flutter Expert Review: Comprehensive Improvement Plan

Reviewed: 2026-03-07 Reviewer: Claude (flutter-expert skill) Target:
`docs/plans/2026-03-07-feat-starter-kit-comprehensive-improvement-plan.md`

---

## Phase 1: Riverpod Codegen Migration

### What the plan gets right

- Correct mapping of `Provider` -> `@Riverpod(keepAlive: true)` vs `@riverpod`
  (autoDispose).
- Identifying that `Provider<Function>` (sign_out, delete_account) needs
  restructuring.
- Recognizing test override syntax will change.

### What the plan gets wrong or underspecifies

1. **`StateNotifierProvider` is deprecated in codegen.** The skill's reference
   examples still show `StateNotifierProvider`, but codegen uses
   `Notifier`/`AsyncNotifier`. The plan mentions this for `onboarding_provider`
   and `theme_provider` but doesn't show the actual migration pattern. Here is
   the correct codegen form:

```dart
// BEFORE (manual)
final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();
}

// AFTER (codegen)
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() => const OnboardingState();
  // methods unchanged
}
// Access: ref.watch(onboardingNotifierProvider)
```

2. **Provider<Function> migration is the hardest part and needs a concrete
   pattern.** Do not create a codegen provider that returns a function. Convert
   to a Notifier with a method:

```dart
// BEFORE
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(authServiceProvider).signOut();
  };
});

// AFTER (codegen) -- convert to a stateless action notifier
@riverpod
class SignOutAction extends _$SignOutAction {
  @override
  FutureOr<void> build() {}  // no-op initial state

  Future<void> execute() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).signOut();
    });
  }
}
// Usage: ref.read(signOutActionProvider.notifier).execute()
```

This pattern gives you loading/error states for free, which the current
`Provider<Function>` approach lacks entirely.

3. **Missing: `part` file generation order.** The plan says "add
   `part '<filename>.g.dart'`" but doesn't warn that you must run
   `dart run build_runner build --delete-conflicting-outputs` before the project
   will compile. During migration, do it file-by-file with `build_runner watch`
   running, not all 20 at once.

4. **Missing: `ref.watch` vs `ref.read` audit.** Codegen changes provider names
   (e.g., `themeProvider` becomes `themeModeNotifierProvider`). Every
   `ref.watch(oldName)` and `ref.read(oldName)` call across the codebase must be
   updated. The plan should include a grep-and-replace step.

5. **`StateProvider<bool>` for isPremium.** The plan says "migrate to a Notifier
   with explicit state" but the simpler codegen equivalent is:

```dart
@riverpod
class IsPremium extends _$IsPremium {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
```

### What's missing

- **Rollback strategy.** If codegen migration breaks halfway, how do you revert?
  Recommend: migrate in a single PR with a feature branch, do not merge partial
  codegen.
- **Generated file `.gitignore` decision.** Convention: commit `.g.dart` files
  for starter kits (so cloners don't need build_runner immediately). Document
  this choice explicitly.

---

## Phase 2: Flutter Flavors Setup

### What the plan gets right

- Correct Android `productFlavors` structure with `applicationIdSuffix`.
- Identifying that `flutterfire configure` must run per flavor.
- Noting iOS scheme setup requires manual Xcode steps.

### What the plan gets wrong

1. **`String.fromEnvironment('FLAVOR')` does not read `--flavor`.** The
   `--flavor` flag is an Android/iOS build system concept. It does NOT set a
   Dart define. You need BOTH:

```bash
flutter run --flavor dev --dart-define=FLAVOR=dev
```

Or better, use `--dart-define-from-file`:

```bash
# config/dev.json
{ "FLAVOR": "dev", "API_BASE": "https://dev.api.example.com" }

flutter run --flavor dev --dart-define-from-file=config/dev.json
```

This is a common mistake. The plan's environment.dart code will silently always
return `dev` without the `--dart-define`.

2. **Missing: `flutter_flavorizr` recommendation.** For a starter kit, manually
   configuring iOS schemes, plists, xcconfig files, and Android flavors is
   error-prone and hard to document. Consider using `flutter_flavorizr` package
   which automates this:

```yaml
dev_dependencies:
  flutter_flavorizr: ^2.2.3

flavorizr:
  flavors:
    dev:
      app:
        name: "StarterKit Dev"
      android:
        applicationId: "com.example.starterkit.dev"
      ios:
        bundleId: "com.example.starterkit.dev"
    staging:
      app:
        name: "StarterKit Staging"
      android:
        applicationId: "com.example.starterkit.staging"
      ios:
        bundleId: "com.example.starterkit.staging"
    prod:
      app:
        name: "StarterKit"
      android:
        applicationId: "com.example.starterkit"
      ios:
        bundleId: "com.example.starterkit"
```

Then `dart run flutter_flavorizr` generates all platform config. Much more
reliable for a starter kit.

3. **Missing: Firebase options per flavor.** The plan mentions per-flavor
   `google-services.json` but doesn't address `firebase_options.dart`. With
   multiple flavors, you need either:
   - Multiple `firebase_options_*.dart` files selected at runtime, OR
   - Use `flutterfire configure` with `--out` flag per flavor:

```bash
flutterfire configure \
  --project=my-project-dev \
  --out=lib/firebase_options_dev.dart \
  --android-package-name=com.example.starterkit.dev

flutterfire configure \
  --project=my-project-prod \
  --out=lib/firebase_options_prod.dart \
  --android-package-name=com.example.starterkit
```

Then in `main.dart`:

```dart
final options = switch (EnvironmentConfig.current) {
  Environment.dev => DefaultFirebaseOptions_Dev.currentPlatform,
  Environment.staging => DefaultFirebaseOptions_Staging.currentPlatform,
  Environment.prod => DefaultFirebaseOptions_Prod.currentPlatform,
};
await Firebase.initializeApp(options: options);
```

4. **Missing: iOS entitlements per flavor.** Each flavor needs its own
   entitlements file for push notifications, sign-in-with-apple, and associated
   domains. Document this.

---

## Phase 2: l10n Implementation

### What the plan gets right

- Correct `l10n.yaml` configuration.
- Correct `AppLocalizations.of(context)!` usage pattern.
- Smart exclusion of Firebase error messages from l10n.
- Good list of files to extract strings from.

### What the plan gets wrong

1. **`AppLocalizations.of(context)!` is fragile.** The `!` null assertion
   crashes if the widget is outside the localization scope. Use the extension
   method instead:

```dart
// In l10n.yaml, add:
nullable-getter: false

// Then usage becomes (no bang operator):
Text(AppLocalizations.of(context).signInPrompt)

// Or even better, create an extension:
// lib/l10n/l10n_extension.dart
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// Usage:
Text(context.l10n.signInPrompt)
```

2. **Missing: ARB key naming convention.** For ~50+ strings, establish a
   convention upfront:

```json
{
  "@@locale": "en",
  "authSignInTitle": "Sign In",
  "@authSignInTitle": { "description": "Title on the sign-in screen" },
  "authSignInWithGoogle": "Sign in with Google",
  "authSignInWithApple": "Sign in with Apple",
  "onboardingStep1Title": "Welcome",
  "settingsThemeLabel": "Theme",
  "settingsDarkMode": "Dark Mode",
  "commonLoading": "Loading...",
  "commonRetry": "Retry",
  "errorGeneric": "Something went wrong"
}
```

Pattern: `{feature}{screen/context}{element}` for feature strings, `common*` for
shared, `error*` for errors.

3. **Missing: `context.l10n` in tests.** Widget tests need localization
   delegates pumped:

```dart
Widget buildTestWidget(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
```

This should be part of the shared test helpers in Phase 3.

---

## Phase 3: Widget Testing Patterns

### What the plan gets right

- Deleting zero-value tests (testing that a provider exists is worthless).
- Creating shared test helpers with `createMockProviderContainer`.
- Fixing router redirect tests to use real GoRouter behavior.

### What the plan gets wrong or underspecifies

1. **Missing: `pumpWidget` helper with all required ancestors.** The most common
   Flutter testing pain point is missing ancestors (Theme, MediaQuery,
   Localizations, Router). Create one helper:

```dart
// test/helpers/pump_app.dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    GoRouter? router,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          routerConfig: router ?? _testRouter(widget),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await pump(); // allow async providers to resolve
  }
}

GoRouter _testRouter(Widget child) => GoRouter(
  routes: [GoRoute(path: '/', builder: (_, __) => child)],
);
```

2. **Missing: `AsyncValue` testing pattern.** With Riverpod, most providers
   return `AsyncValue`. Test all three states:

```dart
testWidgets('shows loading state', (tester) async {
  await tester.pumpApp(
    const ProfileScreen(),
    overrides: [
      userProfileProvider.overrideWith((ref) => const AsyncLoading()),
    ],
  );
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('shows error state', (tester) async {
  await tester.pumpApp(
    const ProfileScreen(),
    overrides: [
      userProfileProvider.overrideWith(
        (ref) => AsyncError(Exception('fail'), StackTrace.current),
      ),
    ],
  );
  expect(find.text('Something went wrong'), findsOneWidget);
});

testWidgets('shows data state', (tester) async {
  await tester.pumpApp(
    const ProfileScreen(),
    overrides: [
      userProfileProvider.overrideWith((ref) => AsyncData(mockProfile)),
    ],
  );
  expect(find.text('John Doe'), findsOneWidget);
});
```

3. **Missing: golden tests recommendation.** For a starter kit with a defined
   theme, golden tests lock down visual regressions cheaply:

```dart
testWidgets('auth screen matches golden', (tester) async {
  await tester.pumpApp(const AuthScreen());
  await expectLater(
    find.byType(AuthScreen),
    matchesGoldenFile('goldens/auth_screen.png'),
  );
});
```

4. **Integration test section is too thin.** The plan says "mock all Firebase
   services" but doesn't show how. With codegen providers, overrides look
   different:

```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full auth flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => Stream.value(mockUser)),
          userProfileProvider.overrideWith((ref) => Stream.value(mockProfile)),
          // ... all external service providers
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    // assertions...
  });
}
```

---

## Phase 4: Firebase Storage + image_picker Integration

### What the plan gets right

- Correct storage path pattern `users/{uid}/avatar.jpg`.
- Separating storage service from provider from widget.
- Including camera AND gallery as sources.

### What the plan gets wrong or underspecifies

1. **Missing: image compression before upload.** Raw camera photos are 5-10MB.
   Always compress:

```dart
// Use image_picker's built-in compression
final XFile? image = await ImagePicker().pickImage(
  source: ImageSource.gallery,
  maxWidth: 512,
  maxHeight: 512,
  imageQuality: 75, // JPEG quality 0-100
);
```

2. **Missing: upload progress tracking.** Firebase Storage supports upload tasks
   with progress. The provider should expose this:

```dart
@riverpod
class AvatarUpload extends _$AvatarUpload {
  @override
  FutureOr<double?> build() => null; // null = not uploading

  Future<String> upload(XFile file, String uid) async {
    final ref = FirebaseStorage.instance.ref('users/$uid/avatar.jpg');
    final task = ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    task.snapshotEvents.listen((snapshot) {
      state = AsyncData(
        snapshot.bytesTransferred / snapshot.totalBytes,
      );
    });

    final snapshot = await task;
    state = const AsyncData(null); // done
    return await snapshot.ref.getDownloadURL();
  }
}
```

3. **Missing: platform permissions.** `image_picker` requires Info.plist entries
   on iOS:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Select a profile photo</string>
<key>NSCameraUsageDescription</key>
<string>Take a profile photo</string>
```

And Android 13+ requires `READ_MEDIA_IMAGES` instead of `READ_EXTERNAL_STORAGE`.
Document this.

4. **Missing: cached_network_image for avatar display.** Don't re-download the
   avatar every time:

```dart
dependencies:
  cached_network_image: ^3.4.1

// In widget:
CachedNetworkImage(
  imageUrl: profile.avatarUrl ?? '',
  placeholder: (_, __) => const CircleAvatar(child: Icon(Icons.person)),
  errorWidget: (_, __, ___) => const CircleAvatar(child: Icon(Icons.person)),
  imageBuilder: (_, imageProvider) => CircleAvatar(
    backgroundImage: imageProvider,
  ),
)
```

5. **Missing: old avatar cleanup.** When uploading a new avatar, the old one at
   the same path gets overwritten (good), but if you ever change the path
   scheme, orphaned files remain. Consider adding a `deleteAvatar` method to the
   storage service.

---

## Phase 4: State Management for Profile CRUD

### What the plan underspecifies

The plan creates a `profile_edit_provider.dart` but doesn't show the pattern.
Here's what it should be:

```dart
@freezed
class ProfileEditState with _$ProfileEditState {
  const factory ProfileEditState({
    @Default('') String displayName,
    @Default(false) bool isSaving,
    String? avatarUrl,
    String? error,
  }) = _ProfileEditState;
}

@riverpod
class ProfileEdit extends _$ProfileEdit {
  @override
  ProfileEditState build() {
    // Initialize from current profile
    final profile = ref.watch(userProfileProvider).valueOrNull;
    return ProfileEditState(
      displayName: profile?.displayName ?? '',
      avatarUrl: profile?.avatarUrl,
    );
  }

  void updateDisplayName(String name) {
    state = state.copyWith(displayName: name, error: null);
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await ref.read(userProfileServiceProvider).updateProfile(
        displayName: state.displayName,
        avatarUrl: state.avatarUrl,
      );
      // Profile stream auto-updates via Firestore listener
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
```

Key points:

- Use `@freezed` for the edit state (immutable, copyWith, equality).
- Initialize from the live profile stream in `build()`.
- Separate "editing" state from "persisted" state -- the `userProfileProvider`
  stream handles the source of truth; `ProfileEdit` is the form buffer.
- Add `freezed` and `freezed_annotation` to dependencies if not already present.

---

## Cross-Cutting Concerns the Plan Misses

1. **`const` constructor audit.** The flutter-expert skill mandates `const`
   constructors wherever possible. The plan never mentions this. Add a lint rule
   or a manual pass.

2. **`Key` parameters on list items.** The skill requires proper keys for lists.
   Any new list widgets (profile fields, settings items) must use `ValueKey` or
   similar.

3. **DevTools profiling.** The skill says "Profile with DevTools, fix jank." The
   plan adds Firebase Storage uploads and image picking -- both can cause jank.
   Recommend testing avatar upload flow with DevTools timeline.

4. **Dependency injection for testability.** The plan's `ProfileStorageService`
   should take `FirebaseStorage` as a constructor parameter (injected via
   Riverpod), not use `FirebaseStorage.instance` directly. Same for
   `ImagePicker`. This is critical for testing:

```dart
@riverpod
ImagePicker imagePicker(Ref ref) => ImagePicker();

@riverpod
FirebaseStorage firebaseStorage(Ref ref) => FirebaseStorage.instance;

// Service uses injected instances
class ProfileStorageService {
  final FirebaseStorage _storage;
  ProfileStorageService(this._storage);
  // ...
}
```

5. **Error handling pattern.** The plan mentions error handling but doesn't
   establish a pattern. With codegen + AsyncNotifier, use `AsyncValue.guard()`
   consistently:

```dart
Future<void> someAction() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    // do work
    return result;
  });
}
```

This ensures errors are always caught and surfaced through the provider state.

---

## Summary Verdict

The plan is solid in scope and phasing. The dependency ordering is correct. The
main gaps are:

| Area                                  | Severity   | Issue                                             |
| ------------------------------------- | ---------- | ------------------------------------------------- |
| Flavors `--flavor` vs `--dart-define` | **High**   | Plan's code won't work as written                 |
| Provider<Function> migration pattern  | **High**   | No concrete replacement shown                     |
| Image compression                     | **Medium** | Missing from avatar upload                        |
| `AppLocalizations.of(context)!`       | **Medium** | Fragile; use extension + `nullable-getter: false` |
| Platform permissions for image_picker | **Medium** | Not documented                                    |
| DI for Storage/ImagePicker            | **Medium** | Needed for testability                            |
| `const` constructor audit             | **Low**    | Skill requirement, not in plan                    |
| Golden tests                          | **Low**    | Nice-to-have for a starter kit                    |
