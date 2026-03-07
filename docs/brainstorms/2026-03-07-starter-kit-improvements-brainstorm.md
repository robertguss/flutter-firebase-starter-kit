# Brainstorm: Flutter Firebase Starter Kit - Comprehensive Improvement Plan

**Date:** 2026-03-07 **Status:** Active **Audience:** Robert (primary user,
building apps on this kit) **Approach:** Phased releases

---

## What We're Building

A comprehensive upgrade to the Flutter Firebase Starter Kit across four
dimensions: architectural integrity, developer experience, test quality, and new
capabilities. The goal is to make this the foundation Robert reaches for every
time he starts a new app -- fast to configure, confident to build on, and honest
about what it provides.

---

## Why This Approach

Robert is building for himself first. That means:

- **Correctness over marketing** -- fix what's broken before adding polish
- **Confidence over coverage** -- test the flows that matter, not vanity metrics
- **Real behavior over scaffolding** -- environment config should DO something,
  not just exist
- **Speed to first feature** -- every minute spent configuring is a minute not
  building

Phased releases let us ship value incrementally while keeping the kit stable
enough to build on.

---

## Key Decisions

| Decision              | Choice                           | Rationale                                                            |
| --------------------- | -------------------------------- | -------------------------------------------------------------------- |
| Primary audience      | Robert himself                   | Scratch your own itch; community benefits second                     |
| Monetization          | RevenueCat stays, fully polished | Core to Robert's app strategy                                        |
| Release strategy      | Phased (4 releases)              | Ship value incrementally, stay buildable                             |
| Environment config    | Make it functional               | Infrastructure without behavior is worse than no infrastructure      |
| Shared/auth violation | Fix it                           | Starter kits teach by example; violations propagate                  |
| Riverpod              | Adopt @riverpod codegen          | Better ergonomics, auto-dispose by default, cleaner family providers |
| State restoration     | Document only                    | Firebase handles auth/data persistence; document when to add it      |
| Flutter flavors       | Full setup                       | Proper Android productFlavors + iOS schemes for dev/staging/prod     |
| Internationalization  | Include l10n scaffolding         | Painful to retrofit; set up with English, strings in .arb files      |
| Profile depth         | Full profile page                | Avatar, name, email, preferences, notifications, account actions     |

---

## Phase 1: Foundation Integrity (v1.1)

_Fix what's broken or misleading. After this phase, the kit is honest and
architecturally sound._

### 1.1 Fix shared/ importing from features/auth/

Three shared providers (`sign_out_provider`, `delete_account_provider`,
`post_auth_bootstrap_provider`) import from `features/auth/`. This contradicts
the stated rule that shared/ never imports from features/.

**Recommendation:** Move them into `features/auth/providers/` since they're
fundamentally auth operations. Update imports accordingly.

### 1.2 Migrate to Riverpod codegen

- Add `riverpod_generator`, `build_runner`, and `riverpod_annotation` (already
  in pubspec) to dev_dependencies
- Migrate all ~15 existing providers to `@riverpod` /
  `@Riverpod(keepAlive: true)` annotations
- Generate `.g.dart` files, update all imports
- Add `build_runner` commands to Makefile and CLAUDE.md
- Remove any truly unused deps after migration audit

### 1.3 Clean up dead artifacts

- Archive or remove `todos/` directory (25 items all marked complete --
  confusing for new developers)
- Remove agent-generated analysis files from project root if present

### 1.4 Security fixes

- Add `android:allowBackup="false"` to AndroidManifest.xml (prevents ADB data
  extraction)
- Add `flutter_secure_storage` as a dependency with usage guidance (when to use
  vs SharedPreferences)
- Replace placeholder `example.com` legal URLs with a clear `TODO` marker that
  fails loudly
- Make FCM `onTokenRefresh` actually update the server-side token (currently a
  no-op)
- Add string length limits to Firestore security rules (DoS prevention)

### 1.5 ThemeMode system default

- Add system-default option to theme toggle (currently only light/dark stored as
  boolean)
- Store as string enum instead of boolean for extensibility

### 1.6 Environment config that works

Make the `dev/staging/prod` enum actually control behavior:

- Different log levels per environment
- Crashlytics enabled only in prod
- Debug banner in dev mode (Flutter's built-in `debugShowCheckedModeBanner`)
- Foundation for per-environment Firebase projects (documented pattern)

---

## Phase 2: Developer Experience (v1.2)

_Make the daily workflow faster and the onboarding honest._

### 2.1 Setup automation

Create a `Makefile` or `scripts/setup.sh` that:

- Checks Flutter SDK version
- Runs `flutter pub get`
- Checks for `firebase_options.dart` and guides through setup if missing
- Runs `flutter analyze` to verify clean state
- Prints a summary of next steps

### 2.2 Honest the "3 files" promise

Update README to accurately describe setup:

- 3 config files for app customization
- Plus Firebase setup (firebase_options.dart generation)
- Plus platform config (bundle IDs)
- Frame as: "3 files to customize + standard Firebase/platform setup"

### 2.3 Feature surgery guides

Create `docs/guides/removing-features.md` with per-feature checklists:

- **Removing Paywall:** files to delete, imports to remove from
  main.dart/router.dart, deps to drop, feature flag to disable
- **Removing Notifications:** same structure
- **Removing Onboarding:** same structure

This is the kit's killer differentiator -- prove the "independently deletable"
claim.

### 2.4 CLAUDE.md improvements

- Reference `docs/` directory so AI tools discover detailed guides
- Add feature-removal instructions
- Document the architectural rules explicitly

### 2.5 Flutter flavors setup

Configure proper per-environment builds:

- Android: `productFlavors` for dev, staging, prod (different applicationId per
  flavor)
- iOS: Xcode schemes + configurations for dev, staging, prod (different bundle
  ID per scheme)
- Per-flavor Firebase config (google-services.json / GoogleService-Info.plist
  per flavor)
- Per-flavor app name and icon (optional but documented)
- Update environment.dart to read from flavor instead of --dart-define

### 2.6 l10n scaffolding

- Enable Flutter's built-in l10n in pubspec.yaml (`generate: true`)
- Create `lib/l10n/` with `app_en.arb` containing all user-facing strings
- Move hardcoded strings from widgets to .arb file references
- Document how to add a new locale
- Single locale (English) to start -- pattern is what matters

### 2.7 CI/CD with GitHub Actions

Create `.github/workflows/`:

- `ci.yml`: flutter analyze + flutter test on PR
- `build.yml`: build APK/IPA on tag (manual trigger)
- Keep simple and extensible

### 2.8 Visual identity

- Add 2-3 screenshots of key screens to README
- Optional: GIF of auth -> onboarding -> home flow

---

## Phase 3: Test Quality (v1.3)

_Build confidence in the foundation. Fix anti-patterns, close critical gaps._

### 3.1 Delete or rewrite zero-value tests

- `purchases_service_test.dart`: Tests mocktail itself, not your code. Zero
  value. Delete or rewrite with real logic testing.
- `app_test.dart`: Misleadingly named, duplicates auth_provider_test. Delete or
  rename.

### 3.2 Fix router redirect tests

- `router_test.dart` lines 116-184: Actually invoke the redirect function and
  assert the resulting location, not just provider state.

### 3.3 Create shared test helpers

Create `test/helpers/`:

- `mocks.dart` -- shared mock declarations (eliminate ~40 lines of duplication
  across 8+ files)
- `pump_app.dart` -- helper wrapping ProviderScope + MaterialApp with common
  overrides
- `fixtures.dart` -- factory methods for UserProfile and other test data

### 3.4 Close critical coverage gaps

Priority tests to add:

- **Sign-in flows** in auth_service_test.dart (Google + Apple -- primary entry
  points untested)
- **Onboarding screen** widget test (page swiping, completion)
- **Notification provider** (FCM service tested but provider wiring isn't)
- **Environment config** (parsing logic)

### 3.5 Fix purchases_provider_test anti-pattern

Stop re-implementing provider logic in test overrides. Test the actual
`isPremiumProvider` with proper dependency mocks.

### 3.6 Integration test foundation

Create `integration_test/` with at least one end-to-end flow:

- Auth -> Onboarding -> Home with mocked Firebase services
- Establishes the pattern for future integration tests

---

## Phase 4: New Capabilities (v1.4)

_Add features that teach real patterns and that Robert will actually use._

### 4.1a Profile CRUD (core)

- Avatar upload to Firebase Storage with image picker
- Display name editing with inline save
- Email display (read-only, from auth)
- Profile completion indicator
- Real example of Firestore CRUD + Storage + reactive UI

### 4.1b Account actions migration

- Move sign out and delete account from Settings to Profile
- Decide what remains in Settings (theme toggle, app version, legal links,
  feedback)
- Clean separation: Profile = your data, Settings = app behavior

### 4.1c Profile preferences

- Notification toggle (ties into FCM)
- Theme selection (ties into existing theme provider)
- Stored in Firestore user doc, synced across devices

### 4.2 Analytics event taxonomy

Design a structured event system:

- Standard events: `screen_view`, `feature_used`, `error_occurred`,
  `purchase_started`
- Analytics helper enforcing consistent parameter naming
- Example implementation in 2-3 screens

### 4.3 Consent gate for analytics/crashlytics

- GDPR/CCPA consent prompt on first launch
- Store consent in SharedPreferences (or secure storage)
- Gate Crashlytics and Analytics initialization on consent
- Increasingly legally required

### 4.4 Offline-first documentation

Document Firestore's built-in offline support (not custom implementation):

- What Firestore handles automatically (local cache, offline reads/writes)
- How to enable/configure persistence
- When you need to add explicit offline handling (connectivity indicators, retry
  UI)
- Add `docs/guides/offline-support.md`

### 4.5 Deep link documentation

- Add `docs/guides/deep-links.md` explaining setup for iOS (Associated Domains)
  and Android (App Links)
- Cover use cases: sharing, transactional emails, push notification routing
- GoRouter integration pattern
- No code scaffolding -- too app-specific

### 4.6 Firestore rules testing

- Firebase emulator setup
- Rules test file
- Inline comments explaining each rule constraint

### 4.7 State restoration documentation

- Add `docs/guides/state-restoration.md`
- Explain when to add RestorationMixin (complex multi-step forms)
- Explain what Firebase already handles (auth session, Firestore data)
- Code example for a form screen with state restoration

---

## Open Questions

_All questions resolved._

---

## Resolved Questions

| Question             | Decision                 | Rationale                                                        |
| -------------------- | ------------------------ | ---------------------------------------------------------------- |
| Target audience      | Robert first             | Scratch your own itch philosophy                                 |
| Keep paywall?        | Yes, polish it           | Core monetization strategy                                       |
| Release strategy     | 4 phased releases        | Ship value incrementally                                         |
| CI/CD                | Include GitHub Actions   | Table stakes for 2026                                            |
| Riverpod approach    | Adopt @riverpod codegen  | Better ergonomics, auto-dispose, cleaner family providers        |
| State restoration    | Document only            | Firebase handles auth/data persistence automatically             |
| Flutter flavors      | Full setup               | Proper productFlavors + Xcode schemes for dev/staging/prod       |
| Internationalization | Include l10n scaffolding | Painful to retrofit; start with English in .arb files            |
| Profile depth        | Full profile page        | Avatar, name, email, preferences, notifications, account actions |

---

## What's NOT in Scope

- Rewriting to a different state management solution (Riverpod is the choice)
- Adding a backend beyond Firebase
- Web/desktop support (mobile focus: iOS + Android)
- Multi-language docs (English only)
