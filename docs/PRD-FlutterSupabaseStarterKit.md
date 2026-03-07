# PRD: Flutter + Supabase Starter Kit

**Version:** 1.0 **Date:** March 6, 2026 **Status:** Blueprint for New
Repository

---

## Table of Contents

1. [Purpose](#1-purpose)
2. [Design Principles](#2-design-principles)
3. [Tech Stack](#3-tech-stack)
4. [Project Structure](#4-project-structure)
5. [Feature Modules](#5-feature-modules)
6. [Local Supabase Development](#6-local-supabase-development)
7. [Environment Configuration](#7-environment-configuration)
8. [Data Layer Architecture](#8-data-layer-architecture)
9. [Auth System](#9-auth-system)
10. [Subscription & Paywall](#10-subscription--paywall)
11. [AI Chat Infrastructure](#11-ai-chat-infrastructure)
12. [Theming & Design System](#12-theming--design-system)
13. [Navigation](#13-navigation)
14. [Push Notifications](#14-push-notifications)
15. [Analytics & Error Tracking](#15-analytics--error-tracking)
16. [Shared UI Components](#16-shared-ui-components)
17. [Supabase Schema Templates](#17-supabase-schema-templates)
18. [Edge Function Templates](#18-edge-function-templates)
19. [New App Setup Script](#19-new-app-setup-script)
20. [Testing Strategy](#20-testing-strategy)
21. [CI/CD](#21-cicd)
22. [What Stays OUT](#22-what-stays-out)

---

## 1. Purpose

This starter kit eliminates repeated boilerplate when launching new Flutter +
Supabase apps. Every app we build shares the same auth flow, paywall,
local-first data layer, AI proxy, theming system, and analytics wiring. Instead
of rebuilding these from scratch each time, we clone this repo, run a setup
script, override a few config files, and go straight to building app-specific
features.

**Goal:** Go from `git clone` to a working app with auth, paywall, dark theme,
local database, Supabase sync, and an AI chat endpoint in under 30 minutes.

---

## 2. Design Principles

| Principle                         | What it means                                                                                                                      |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Local-first**                   | All user data writes to local SQLite (Drift) first. Supabase syncs in the background. App works fully offline for non-AI features. |
| **Local Supabase for dev**        | `supabase start` runs Postgres, Auth, Edge Functions, and Storage locally via Docker. No cloud dependency during development.      |
| **Convention over configuration** | Sensible defaults everywhere. New apps override only what's different (colors, tab labels, feature flags).                         |
| **Feature-folder architecture**   | Each feature is self-contained: screens, widgets, providers, and models in one folder. Easy to delete what you don't need.         |
| **Delete what you don't need**    | Every module (chat, paywall, notifications) is opt-in. Remove its folder and its route — nothing breaks.                           |
| **No premature abstraction**      | Concrete implementations, not abstract frameworks. Copy and modify beats "extend and override."                                    |

---

## 3. Tech Stack

| Layer               | Technology                      | Rationale                                                                        |
| ------------------- | ------------------------------- | -------------------------------------------------------------------------------- |
| Framework           | **Flutter**                     | Compiled to native ARM, no JS bridge. Smooth animations and real-time streaming. |
| Language            | **Dart**                        | Type-safe, AOT-compiled, strong async/stream support for AI responses.           |
| State Management    | **Riverpod**                    | Compile-safe, excellent async stream handling, testable.                         |
| Navigation          | **GoRouter**                    | Declarative routing, deep linking, redirect guards for auth/onboarding.          |
| Local Database      | **Drift** (SQLite)              | Offline-first data storage, type-safe queries, migration support.                |
| Key-Value Storage   | **shared_preferences**          | Simple prefs (onboarding complete, theme mode, notification settings).           |
| Backend             | **Supabase**                    | Auth, Postgres, Edge Functions, Realtime, Storage. Open-source, self-hostable.   |
| Local Backend       | **Supabase CLI**                | Full local stack via Docker — Postgres, Auth, Edge Functions, Storage, Studio.   |
| Payments            | **RevenueCat**                  | In-app subscriptions, paywall management, entitlement checks.                    |
| Push Notifications  | **Firebase Cloud Messaging**    | Reliable cross-platform push (FCM works fine alongside Supabase).                |
| Local Notifications | **flutter_local_notifications** | Scheduled daily reminders, streak nudges.                                        |
| Analytics           | **PostHog**                     | Privacy-friendly, open-source, event tracking + funnels.                         |
| Error Tracking      | **Sentry**                      | Crash reporting, performance monitoring.                                         |
| AI Backend          | **OpenAI / Anthropic API**      | Proxied through Supabase Edge Functions — never exposed to client.               |
| Audio (optional)    | **record + just_audio**         | Voice capture and playback for apps that need it.                                |
| Networking          | **connectivity_plus**           | Online/offline detection for sync triggers.                                      |

### Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State & Navigation
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0

  # Supabase
  supabase_flutter: ^2.5.0

  # Local Database
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0

  # Key-Value Storage
  shared_preferences: ^2.2.0

  # Payments
  purchases_flutter: ^6.0.0

  # Push Notifications
  firebase_core: ^2.27.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^17.0.0

  # Analytics & Errors
  posthog_flutter: ^4.0.0
  sentry_flutter: ^7.18.0

  # Networking
  connectivity_plus: ^6.0.0

  # Auth
  google_sign_in: ^6.2.0
  sign_in_with_apple: ^6.1.0

  # Secure Storage
  flutter_secure_storage: ^9.0.0

  # UI
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  flutter_animate: ^4.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
  drift_dev: ^2.16.0
  mockito: ^5.4.0
  mocktail: ^1.0.0
```

---

## 4. Project Structure

```
flutter_supabase_starter/
├── lib/
│   ├── main.dart                          # Entry point — initializes all services
│   ├── app.dart                           # MaterialApp.router + theme + providers
│   │
│   ├── config/
│   │   ├── app_config.dart                # App name, bundle ID, feature flags
│   │   ├── env.dart                       # Environment enum + Supabase URL/key resolution
│   │   ├── theme.dart                     # ThemeData (dark + light)
│   │   ├── colors.dart                    # Color tokens (override per app)
│   │   └── typography.dart                # Text styles scale
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── providers/
│   │   │   │   ├── auth_provider.dart     # Riverpod auth state (session, user)
│   │   │   │   └── auth_notifier.dart     # Sign in/up/out actions
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart      # Email + social login
│   │   │   │   ├── signup_screen.dart     # Create account
│   │   │   │   └── forgot_password_screen.dart
│   │   │   └── widgets/
│   │   │       ├── auth_form.dart         # Shared email/password fields
│   │   │       ├── social_login_buttons.dart # Apple + Google buttons
│   │   │       └── auth_error_banner.dart
│   │   │
│   │   ├── onboarding/
│   │   │   ├── providers/
│   │   │   │   └── onboarding_provider.dart # Tracks step, stores selections
│   │   │   ├── screens/
│   │   │   │   ├── onboarding_shell.dart  # PageView + progress dots
│   │   │   │   ├── welcome_screen.dart    # Step 1: value prop
│   │   │   │   ├── personalize_screen.dart # Step 2: preferences (override per app)
│   │   │   │   └── notifications_screen.dart # Step 3: notification permission
│   │   │   └── widgets/
│   │   │       ├── onboarding_page.dart   # Reusable page template
│   │   │       └── progress_dots.dart     # Step indicator
│   │   │
│   │   ├── paywall/
│   │   │   ├── providers/
│   │   │   │   ├── purchases_provider.dart # RevenueCat initialization + state
│   │   │   │   └── entitlement_provider.dart # Check premium access
│   │   │   ├── screens/
│   │   │   │   └── paywall_screen.dart    # Free vs premium comparison
│   │   │   └── widgets/
│   │   │       ├── feature_comparison_row.dart
│   │   │       ├── price_card.dart
│   │   │       ├── premium_badge.dart
│   │   │       └── restore_purchases_button.dart
│   │   │
│   │   ├── settings/
│   │   │   ├── screens/
│   │   │   │   ├── settings_screen.dart   # Main settings list
│   │   │   │   ├── notification_settings_screen.dart
│   │   │   │   └── about_screen.dart      # Version, licenses, links
│   │   │   └── widgets/
│   │   │       ├── settings_section.dart  # Section header + items
│   │   │       ├── settings_row.dart      # Label + value/toggle/chevron
│   │   │       └── danger_zone.dart       # Delete account, sign out
│   │   │
│   │   ├── chat/                          # OPTIONAL — delete if app has no AI chat
│   │   │   ├── providers/
│   │   │   │   ├── chat_provider.dart     # Message list state
│   │   │   │   └── streaming_provider.dart # SSE stream from Edge Function
│   │   │   ├── screens/
│   │   │   │   └── chat_screen.dart       # Chat UI with input bar
│   │   │   ├── models/
│   │   │   │   └── chat_message.dart      # Message model (role, content, timestamp)
│   │   │   └── widgets/
│   │   │       ├── message_bubble.dart    # User vs AI styled bubbles
│   │   │       ├── typing_indicator.dart  # Animated dots while AI responds
│   │   │       └── chat_input_bar.dart    # Text field + send button
│   │   │
│   │   └── home/
│   │       └── screens/
│   │           └── home_screen.dart       # Placeholder — replaced per app
│   │
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart          # Drift database class definition
│   │   │   ├── app_database.g.dart        # Generated (run build_runner)
│   │   │   ├── tables/
│   │   │   │   ├── user_profiles.dart     # Example Drift table
│   │   │   │   └── sync_queue.dart        # Pending sync items queue
│   │   │   └── daos/
│   │   │       ├── user_profile_dao.dart  # CRUD operations
│   │   │       └── sync_queue_dao.dart    # Queue management
│   │   │
│   │   ├── sync/
│   │   │   ├── sync_service.dart          # Orchestrates local ↔ Supabase sync
│   │   │   ├── sync_status.dart           # Enum: idle, syncing, error
│   │   │   └── conflict_resolver.dart     # Last-write-wins or custom merge
│   │   │
│   │   ├── network/
│   │   │   ├── supabase_client.dart       # Initialization with env-based config
│   │   │   └── connectivity_service.dart  # Online/offline listener + sync trigger
│   │   │
│   │   ├── analytics/
│   │   │   ├── analytics_service.dart     # PostHog wrapper
│   │   │   ├── events.dart                # Type-safe event name constants
│   │   │   └── analytics_observer.dart    # GoRouter NavigatorObserver for screen tracking
│   │   │
│   │   ├── notifications/
│   │   │   ├── fcm_service.dart           # FCM initialization, token registration
│   │   │   ├── local_notification_service.dart # Schedule/cancel local notifications
│   │   │   └── notification_handler.dart  # Route to correct screen on tap
│   │   │
│   │   └── errors/
│   │       ├── sentry_service.dart        # Sentry initialization
│   │       └── error_handler.dart         # Global error boundary
│   │
│   ├── shared/
│   │   └── widgets/
│   │       ├── app_card.dart              # Styled card (rounded corners, border, shadow)
│   │       ├── app_button.dart            # Primary / secondary / text buttons
│   │       ├── app_text_field.dart        # Styled text input
│   │       ├── streak_badge.dart          # Fire icon + count (used by many apps)
│   │       ├── xp_counter.dart            # Animated XP display
│   │       ├── loading_state.dart         # Loading / error / empty wrapper
│   │       ├── premium_gate.dart          # Wraps widget — shows paywall if not premium
│   │       └── app_bottom_sheet.dart      # Styled bottom sheet helper
│   │
│   └── router/
│       ├── router.dart                    # GoRouter config with ShellRoute for tabs
│       ├── guards.dart                    # Auth guard + onboarding guard
│       └── routes.dart                    # Route path constants
│
├── supabase/                              # Supabase local dev + migrations
│   ├── config.toml                        # Local Supabase configuration
│   ├── seed.sql                           # Dev seed data
│   ├── migrations/
│   │   ├── 00000000000000_initial_schema.sql
│   │   └── 00000000000001_rls_policies.sql
│   └── functions/
│       ├── ai-proxy/
│       │   └── index.ts                   # Edge Function: proxy AI API calls
│       ├── sync-handler/
│       │   └── index.ts                   # Edge Function: handle batch sync
│       └── push-notification/
│           └── index.ts                   # Edge Function: send targeted push
│
├── scripts/
│   ├── setup.sh                           # New app setup wizard
│   ├── rename_package.sh                  # Rename Flutter package + bundle IDs
│   └── reset_supabase.sh                  # Drop and re-seed local Supabase
│
├── .env.example                           # Template for environment variables
├── .env.local                             # Local dev (git-ignored)
├── .env.staging                           # Staging (git-ignored)
├── .env.production                        # Production (git-ignored)
├── analysis_options.yaml                  # Dart lint rules
├── pubspec.yaml                           # Dependencies
├── Makefile                               # Common commands (run, build, test, etc.)
└── README.md                              # Setup instructions
```

---

## 5. Feature Modules

Each feature module is fully self-contained and deletable. If your app doesn't
need AI chat, delete `lib/features/chat/` and remove its route from
`router.dart`. Nothing else breaks.

### Module inventory

| Module       | Description                                                                         | Delete if your app...              |
| ------------ | ----------------------------------------------------------------------------------- | ---------------------------------- |
| `auth`       | Email/password + Apple + Google sign-in, auth state, protected routes               | Never — every app needs auth       |
| `onboarding` | 3-step configurable onboarding flow with progress indicator                         | Never — every app needs onboarding |
| `paywall`    | RevenueCat integration, free vs premium comparison, entitlement checks              | Is completely free                 |
| `settings`   | Notification prefs, subscription management, about screen, sign out, delete account | Never — every app needs settings   |
| `chat`       | AI streaming chat with message bubbles, typing indicator, persistence               | Doesn't use AI chat                |
| `home`       | Placeholder home screen with tab bar                                                | Override, don't delete             |

---

## 6. Local Supabase Development

### Overview

All development happens against a local Supabase instance running via Docker.
This gives you a full Postgres database, Auth server, Edge Functions runtime,
Storage, and Supabase Studio — all on your machine. No cloud account needed
until you're ready to deploy.

### Prerequisites

- Docker Desktop installed and running
- Supabase CLI installed (`brew install supabase/tap/supabase`)

### Commands

```bash
# Start local Supabase (Postgres, Auth, Edge Functions, Studio, Storage)
supabase start

# After first start, you'll see output like:
#   API URL:   http://127.0.0.1:54321
#   Studio:    http://127.0.0.1:54323
#   anon key:  eyJhbG...
#   service_role key: eyJhbG...

# Apply migrations
supabase db reset        # Drops everything, re-runs migrations + seed.sql

# Create a new migration
supabase migration new my_migration_name

# Serve Edge Functions locally (hot reload)
supabase functions serve

# Run a specific Edge Function locally
supabase functions serve ai-proxy --env-file .env.local

# Stop local Supabase
supabase stop

# View local Supabase Studio (GUI for database, auth, etc.)
# Open http://127.0.0.1:54323 in browser
```

### Local → Cloud migration path

| Stage          | Supabase URL                               | Anon Key                     | How to switch              |
| -------------- | ------------------------------------------ | ---------------------------- | -------------------------- |
| **Local dev**  | `http://127.0.0.1:54321`                   | From `supabase start` output | Default — no config needed |
| **Staging**    | `https://your-staging-project.supabase.co` | From Supabase dashboard      | Set in `.env.staging`      |
| **Production** | `https://your-prod-project.supabase.co`    | From Supabase dashboard      | Set in `.env.production`   |

When you're ready to go to production:

```bash
# 1. Create a Supabase cloud project at https://supabase.com/dashboard

# 2. Link your local project to cloud
supabase link --project-ref your-project-ref

# 3. Push migrations to cloud
supabase db push

# 4. Deploy Edge Functions to cloud
supabase functions deploy ai-proxy
supabase functions deploy sync-handler
supabase functions deploy push-notification

# 5. Set secrets on cloud
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...

# 6. Update .env.production with cloud URL + anon key

# 7. Build production app pointing to cloud
flutter build ios --dart-define-from-file=.env.production
```

### Local Supabase configuration (config.toml)

```toml
[api]
enabled = true
port = 54321
schemas = ["public", "graphql_public"]
extra_search_path = ["public", "extensions"]
max_rows = 1000

[db]
port = 54322
major_version = 15

[studio]
enabled = true
port = 54323

[auth]
enabled = true
site_url = "http://localhost:3000"
additional_redirect_urls = ["io.supabase.starter://login-callback"]
jwt_expiry = 3600
enable_signup = true

[auth.email]
enable_signup = true
double_confirm_changes = true
enable_confirmations = false  # Disable email confirmations for local dev

[auth.external.apple]
enabled = true
client_id = ""
secret = ""

[auth.external.google]
enabled = true
client_id = ""
secret = ""

[edge_runtime]
enabled = true
policy = "per_worker"

[analytics]
enabled = false  # Disable for local dev
```

---

## 7. Environment Configuration

### .env.example

```bash
# ─── Supabase ───────────────────────────────────────
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=your-local-anon-key

# ─── AI ─────────────────────────────────────────────
# Set these in Supabase Edge Function secrets, not in the client app.
# Listed here for reference only.
# OPENAI_API_KEY=sk-...
# ANTHROPIC_API_KEY=sk-ant-...

# ─── RevenueCat ─────────────────────────────────────
REVENUECAT_API_KEY_APPLE=appl_...
REVENUECAT_API_KEY_GOOGLE=goog_...

# ─── PostHog ────────────────────────────────────────
POSTHOG_API_KEY=phc_...
POSTHOG_HOST=https://app.posthog.com

# ─── Sentry ────────────────────────────────────────
SENTRY_DSN=https://...@sentry.io/...

# ─── Firebase (for FCM only) ───────────────────────
# Configured via google-services.json / GoogleService-Info.plist
```

### env.dart — Runtime environment resolution

```dart
enum AppEnvironment { local, staging, production }

class EnvConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatApiKey;
  final String posthogApiKey;
  final String posthogHost;
  final String sentryDsn;

  const EnvConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.revenueCatApiKey,
    required this.posthogApiKey,
    required this.posthogHost,
    required this.sentryDsn,
  });

  /// Reads from --dart-define-from-file values at build time
  factory EnvConfig.fromEnvironment() {
    return EnvConfig(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      revenueCatApiKey: const String.fromEnvironment('REVENUECAT_API_KEY_APPLE'),
      posthogApiKey: const String.fromEnvironment('POSTHOG_API_KEY'),
      posthogHost: const String.fromEnvironment(
        'POSTHOG_HOST',
        defaultValue: 'https://app.posthog.com',
      ),
      sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
    );
  }
}
```

### Running with different environments

```bash
# Local development (default)
flutter run --dart-define-from-file=.env.local

# Staging
flutter run --dart-define-from-file=.env.staging

# Production build
flutter build ios --dart-define-from-file=.env.production
flutter build appbundle --dart-define-from-file=.env.production
```

---

## 8. Data Layer Architecture

### Local-first pattern

```
┌─────────────────────────────────────────────┐
│                  Flutter App                 │
│                                              │
│   Feature Provider ──→ DAO ──→ Drift (SQLite)│
│         │                        │           │
│         │ (reads from local DB)  │           │
│         ▼                        ▼           │
│   UI renders immediately    SyncQueue table  │
│                                  │           │
│                                  ▼           │
│                           SyncService        │
│                      (on connectivity change) │
│                                  │           │
│                                  ▼           │
│                         Supabase Postgres    │
│                       (cloud or local Docker) │
└─────────────────────────────────────────────┘
```

### How it works

1. **All writes go to Drift first.** User creates/updates/deletes data → DAO
   writes to SQLite immediately → UI updates instantly.
2. **Writes are queued for sync.** Every local write also inserts a row into the
   `sync_queue` table with the table name, row ID, operation type
   (insert/update/delete), and payload.
3. **SyncService processes the queue.** When connectivity changes from offline →
   online, or on a periodic timer (e.g. every 60 seconds while online),
   SyncService reads the queue and pushes changes to Supabase.
4. **Conflict resolution.** Default strategy is last-write-wins using
   `updated_at` timestamps. Override `ConflictResolver` for app-specific merge
   logic.
5. **Supabase → Local.** On app launch and periodically while online,
   SyncService pulls changes from Supabase that are newer than the last sync
   timestamp.

### Drift database definition

```dart
@DriftDatabase(tables: [UserProfiles, SyncQueue], daos: [UserProfileDao, SyncQueueDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Add migration steps here as schema evolves
    },
  );
}
```

### SyncQueue table

```dart
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName => text()();          // "user_profiles", etc.
  TextColumn get rowId => text()();              // UUID of the row
  TextColumn get operation => text()();          // "insert", "update", "delete"
  TextColumn get payload => text()();            // JSON-encoded row data
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}
```

### SyncService interface

```dart
class SyncService {
  final AppDatabase db;
  final SupabaseClient supabase;
  final ConnectivityService connectivity;

  /// Push all unsynced local changes to Supabase
  Future<void> pushPendingChanges();

  /// Pull remote changes since last sync
  Future<void> pullRemoteChanges();

  /// Full bidirectional sync
  Future<void> sync() async {
    await pushPendingChanges();
    await pullRemoteChanges();
  }

  /// Start listening for connectivity changes
  void startAutoSync();
}
```

---

## 9. Auth System

### Supported auth methods

| Method              | Implementation                                                             | Notes                                                             |
| ------------------- | -------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| Email + password    | `supabase.auth.signUp()` / `signInWithPassword()`                          | Default for all apps                                              |
| Sign in with Apple  | `supabase.auth.signInWithApple()` via `sign_in_with_apple`                 | Required for iOS App Store if any social login present            |
| Sign in with Google | `supabase.auth.signInWithOAuth(OAuthProvider.google)` via `google_sign_in` | Optional                                                          |
| Guest / anonymous   | `supabase.auth.signInAnonymously()`                                        | For apps that allow on-device-first usage before account creation |
| Password reset      | `supabase.auth.resetPasswordForEmail()`                                    | Email link flow                                                   |

### Auth state provider (Riverpod)

```dart
@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((data) => data.session);
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password);
  Future<void> signInWithApple();
  Future<void> signInWithGoogle();
  Future<void> signInAnonymously();
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<void> resetPassword(String email);
  Future<void> upgradeAnonymousAccount(String email, String password);
}
```

### Auth guard (GoRouter redirect)

```dart
redirect: (context, state) {
  final session = ref.read(authStateProvider).valueOrNull;
  final isOnAuthRoute = state.matchedLocation.startsWith('/auth');
  final isOnOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
  final hasCompletedOnboarding = ref.read(onboardingCompleteProvider);

  // Not logged in → send to login
  if (session == null && !isOnAuthRoute) return '/auth/login';

  // Logged in but hasn't onboarded → send to onboarding
  if (session != null && !hasCompletedOnboarding && !isOnOnboardingRoute) {
    return '/onboarding';
  }

  // Logged in + onboarded but on auth route → send to home
  if (session != null && hasCompletedOnboarding && isOnAuthRoute) return '/';

  return null; // No redirect
}
```

---

## 10. Subscription & Paywall

### RevenueCat setup

```dart
Future<void> initRevenueCat() async {
  await Purchases.configure(
    PurchasesConfiguration(env.revenueCatApiKey)
      ..appUserID = supabase.auth.currentUser?.id,
  );
}
```

### Entitlement provider

```dart
@riverpod
Stream<bool> isPremium(IsPremiumRef ref) {
  return Purchases.addCustomerInfoUpdateListener((info) {
    return info.entitlements.active.containsKey('premium');
  });
}
```

### PremiumGate widget

```dart
/// Wraps any widget. Shows the child if user is premium,
/// otherwise shows a "Go Premium" CTA that opens the paywall.
class PremiumGate extends ConsumerWidget {
  final Widget child;
  final Widget? lockedPlaceholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider).valueOrNull ?? false;
    if (isPremium) return child;
    return lockedPlaceholder ?? _defaultLockedState(context);
  }
}
```

### Paywall screen template

The paywall screen shows a side-by-side comparison of Free vs Premium features,
pricing, and a call-to-action. It uses RevenueCat's `Offerings` to dynamically
fetch available packages (monthly, annual, lifetime).

```
┌──────────────────────────────────┐
│         Unlock Premium           │
│                                  │
│  Feature         Free   Premium  │
│  ─────────────── ────   ───────  │
│  Basic feature    ✓       ✓     │
│  Premium feat 1   ✗       ✓     │
│  Premium feat 2   ✗       ✓     │
│  AI features      ✗       ✓     │
│  No ads           ✗       ✓     │
│                                  │
│  ┌──────────────────────────┐   │
│  │  $X.XX / month           │   │
│  │  or $XX.XX / year (save) │   │
│  └──────────────────────────┘   │
│                                  │
│  [ Continue ]                    │
│                                  │
│  Restore Purchases    Terms      │
└──────────────────────────────────┘
```

Feature rows are configured via a simple list — override per app:

```dart
const paywallFeatures = [
  PaywallFeature(name: 'Basic feature', free: true, premium: true),
  PaywallFeature(name: 'Premium feature 1', free: false, premium: true),
  PaywallFeature(name: 'AI features', free: false, premium: true),
];
```

---

## 11. AI Chat Infrastructure

### Architecture

```
Flutter App                          Supabase Edge Function              AI Provider
────────────                         ──────────────────────              ───────────
User types message
       │
       ▼
POST /functions/v1/ai-proxy ──────→ Validates auth token
  { messages, systemPrompt }         Reads API key from secrets
                                     Builds AI API request
                                            │
                                            ▼
                                     POST api.openai.com/v1/chat ──→ Returns stream
                                     (or api.anthropic.com)
                                            │
                                            ▼
                              ◄───── Streams SSE chunks back
       │
       ▼
StreamingProvider receives chunks
Updates UI in real-time
       │
       ▼
Message saved to Drift
Queued for Supabase sync
```

### Edge Function: ai-proxy/index.ts

```typescript
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  // 1. Verify the user's JWT
  const authHeader = req.headers.get("Authorization");
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader! } } },
  );
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();
  if (error || !user) {
    return new Response("Unauthorized", { status: 401 });
  }

  // 2. Parse request
  const { messages, systemPrompt, model } = await req.json();

  // 3. Call AI provider (OpenAI example — swap for Anthropic as needed)
  const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
    },
    body: JSON.stringify({
      model: model ?? "gpt-4o",
      messages: [{ role: "system", content: systemPrompt }, ...messages],
      stream: true,
    }),
  });

  // 4. Stream the response back to client
  return new Response(aiResponse.body, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
    },
  });
});
```

### Flutter streaming provider

```dart
@riverpod
class ChatNotifier extends _$ChatNotifier {
  Future<void> sendMessage(String content, {String? systemPrompt}) async {
    // Add user message to state
    state = [...state, ChatMessage(role: 'user', content: content)];

    // Add placeholder AI message
    state = [...state, ChatMessage(role: 'assistant', content: '', isStreaming: true)];

    // Stream from Edge Function
    final response = await Supabase.instance.client.functions.invoke(
      'ai-proxy',
      body: {
        'messages': state.map((m) => m.toJson()).toList(),
        'systemPrompt': systemPrompt ?? 'You are a helpful assistant.',
      },
    );

    // Process SSE stream, updating the last message as chunks arrive
    await for (final chunk in response.data) {
      final lastMessage = state.last;
      state = [
        ...state.sublist(0, state.length - 1),
        lastMessage.copyWith(content: lastMessage.content + chunk),
      ];
    }

    // Mark streaming complete
    final lastMessage = state.last;
    state = [
      ...state.sublist(0, state.length - 1),
      lastMessage.copyWith(isStreaming: false),
    ];

    // Persist to Drift
    await _saveToDrift(state);
  }
}
```

---

## 12. Theming & Design System

### Color tokens

Every app overrides `colors.dart` with its own palette. The starter provides a
neutral dark theme as the default.

```dart
abstract class AppColors {
  // ─── Background ─────────────────────────────
  static const Color background = Color(0xFF0D0D0F);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252540);

  // ─── Primary ────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);      // Override per app
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color primaryDark = Color(0xFF4A42D4);

  // ─── Secondary ──────────────────────────────
  static const Color secondary = Color(0xFF00D4AA);    // Override per app
  static const Color secondaryLight = Color(0xFF33DDBB);

  // ─── Accent ─────────────────────────────────
  static const Color accent = Color(0xFFFFB74D);       // Override per app

  // ─── Text ───────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textTertiary = Color(0xFF6A6A80);

  // ─── Semantic ───────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // ─── Borders ────────────────────────────────
  static const Color border = Color(0xFF2A2A40);
  static const Color borderLight = Color(0xFF3A3A55);
}
```

### Typography scale

```dart
abstract class AppTypography {
  static const TextStyle h1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textTertiary,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
}
```

### ThemeData

```dart
ThemeData buildDarkTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    error: AppColors.error,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: AppTypography.h3,
  ),
  cardTheme: CardTheme(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border, width: 1),
    ),
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textTertiary,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
);
```

---

## 13. Navigation

### GoRouter configuration

```dart
final router = GoRouter(
  initialLocation: '/',
  redirect: authGuard,       // See Auth System section
  observers: [AnalyticsObserver()],
  routes: [
    // ─── Auth (no bottom nav) ────────────────
    GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/auth/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/auth/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

    // ─── Onboarding (no bottom nav) ──────────
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingShell()),

    // ─── Paywall (modal) ─────────────────────
    GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),

    // ─── Main app (with bottom nav) ──────────
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),  // Scaffold + BottomNavigationBar
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/explore', builder: (_, __) => const Placeholder()),  // Override per app
        GoRoute(path: '/profile', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);
```

### Tab configuration — override per app

```dart
// config/app_config.dart
const appTabs = [
  AppTab(label: 'Home', icon: Icons.home_rounded, path: '/'),
  AppTab(label: 'Explore', icon: Icons.explore_rounded, path: '/explore'),
  AppTab(label: 'Profile', icon: Icons.person_rounded, path: '/profile'),
];
```

---

## 14. Push Notifications

### FCM initialization

```dart
class FCMService {
  Future<void> initialize() async {
    // Request permission (iOS)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // Get token and store in Supabase for targeting
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await Supabase.instance.client
          .from('push_tokens')
          .upsert({'user_id': userId, 'token': token, 'platform': Platform.operatingSystem});
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      // Update in Supabase
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }
}
```

### Local notification scheduling

```dart
class LocalNotificationService {
  /// Schedule a daily reminder at the user's preferred time
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // notification ID
      title,
      body,
      _nextInstanceOfTime(time),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
```

---

## 15. Analytics & Error Tracking

### PostHog initialization

```dart
class AnalyticsService {
  Future<void> initialize() async {
    await Posthog().setup(
      PostHogConfig(env.posthogApiKey)
        ..host = env.posthogHost
        ..captureApplicationLifecycleEvents = true
        ..debug = kDebugMode,
    );
  }

  void identify(String userId, {Map<String, dynamic>? properties}) {
    Posthog().identify(userId: userId, userProperties: properties);
  }

  void track(String event, {Map<String, dynamic>? properties}) {
    Posthog().capture(eventName: event, properties: properties);
  }

  void screen(String screenName) {
    Posthog().screen(screenName: screenName);
  }

  void reset() {
    Posthog().reset();
  }
}
```

### Type-safe event constants

```dart
/// Override and extend per app
abstract class AnalyticsEvents {
  // Auth
  static const signUp = 'sign_up';
  static const signIn = 'sign_in';
  static const signOut = 'sign_out';

  // Onboarding
  static const onboardingStarted = 'onboarding_started';
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingStepCompleted = 'onboarding_step_completed';

  // Paywall
  static const paywallViewed = 'paywall_viewed';
  static const purchaseStarted = 'purchase_started';
  static const purchaseCompleted = 'purchase_completed';
  static const purchaseRestored = 'purchase_restored';

  // Engagement
  static const sessionStarted = 'session_started';
  static const featureUsed = 'feature_used';
  static const streakMaintained = 'streak_maintained';
}
```

### GoRouter analytics observer

```dart
class AnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    if (route.settings.name != null) {
      AnalyticsService().screen(route.settings.name!);
    }
  }
}
```

### Sentry initialization

```dart
Future<void> initSentry() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = env.sentryDsn;
      options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
      options.environment = kDebugMode ? 'development' : 'production';
    },
  );
}
```

---

## 16. Shared UI Components

### AppCard

```dart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: child,
      ),
    );
  }
}
```

### AppButton

```dart
enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  // ... builds styled ElevatedButton / OutlinedButton / TextButton
}
```

### StreakBadge

```dart
class StreakBadge extends StatelessWidget {
  final int streakCount;
  // Displays: 🔥 12 day streak (with animated fire on milestone days)
}
```

### XPCounter

```dart
class XPCounter extends StatelessWidget {
  final int xp;
  final int? xpGain; // if provided, shows animated +xp
  // Displays: ⭐ 1,250 XP with optional count-up animation
}
```

### LoadingState

```dart
class LoadingState<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget Function(Object error)? errorBuilder;
  final Widget? emptyWidget;

  // Handles loading shimmer, error with retry, empty state, and data
}
```

### PremiumGate

```dart
class PremiumGate extends ConsumerWidget {
  final Widget child;
  final Widget? lockedWidget; // Defaults to blurred child + lock icon + "Go Premium" button
  // Shows child if premium, lockedWidget otherwise
}
```

---

## 17. Supabase Schema Templates

### 00000000000000_initial_schema.sql

```sql
-- ─── User profiles ──────────────────────────────────────
create table public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  subscription_tier text not null default 'free' check (subscription_tier in ('free', 'premium')),
  onboarding_completed boolean not null default false,
  preferences jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ─── Push notification tokens ───────────────────────────
create table public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ios', 'android')),
  created_at timestamptz not null default now(),
  unique(user_id, token)
);

-- ─── Sync metadata ─────────────────────────────────────
create table public.sync_metadata (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  table_name text not null,
  last_synced_at timestamptz not null default now(),
  unique(user_id, table_name)
);

-- ─── Auto-update updated_at ────────────────────────────
create or replace function public.update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger user_profiles_updated_at
  before update on public.user_profiles
  for each row execute function public.update_updated_at();

-- ─── Auto-create profile on signup ─────────────────────
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id)
  values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

### 00000000000001_rls_policies.sql

```sql
-- ─── Enable RLS ─────────────────────────────────────────
alter table public.user_profiles enable row level security;
alter table public.push_tokens enable row level security;
alter table public.sync_metadata enable row level security;

-- ─── user_profiles ──────────────────────────────────────
create policy "Users can view own profile"
  on public.user_profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.user_profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ─── push_tokens ────────────────────────────────────────
create policy "Users can manage own push tokens"
  on public.push_tokens for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ─── sync_metadata ──────────────────────────────────────
create policy "Users can manage own sync metadata"
  on public.sync_metadata for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

### seed.sql

```sql
-- Seed data for local development
-- This runs on `supabase db reset`

-- Create a test user (password: "password123")
-- Note: In local dev, you can also create users via Supabase Studio at http://127.0.0.1:54323
```

---

## 18. Edge Function Templates

### ai-proxy/index.ts

See [AI Chat Infrastructure](#11-ai-chat-infrastructure) for the full
implementation.

Supports both OpenAI and Anthropic backends. The client sends a `provider` field
(`"openai"` or `"anthropic"`) and the Edge Function routes accordingly. AI API
keys are stored as Supabase secrets, never exposed to the client.

### sync-handler/index.ts

Accepts a batch of sync operations from the client and applies them to Supabase
Postgres in a transaction.

```typescript
// POST /functions/v1/sync-handler
// Body: { operations: [{ table, id, operation, data }] }
// Returns: { synced: number, conflicts: [] }
```

### push-notification/index.ts

Sends targeted push notifications via FCM. Called by Supabase database webhooks
or cron jobs.

```typescript
// POST /functions/v1/push-notification
// Body: { userId, title, body, data }
// Looks up user's push token, sends via FCM
```

---

## 19. New App Setup Script

### scripts/setup.sh

```bash
#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Flutter + Supabase Starter Kit Setup  "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. App name
read -p "App name (e.g., PocketApologist): " APP_NAME
read -p "Package name (e.g., com.yourcompany.pocketapologist): " PACKAGE_NAME
read -p "Description: " APP_DESCRIPTION

# 2. Rename Flutter package
echo "Renaming package..."
./scripts/rename_package.sh "$APP_NAME" "$PACKAGE_NAME"

# 3. Create .env.local from template
if [ ! -f .env.local ]; then
  cp .env.example .env.local
  echo "Created .env.local — fill in your keys."
fi

# 4. Optional modules
read -p "Include AI chat module? (y/n): " INCLUDE_CHAT
if [ "$INCLUDE_CHAT" != "y" ]; then
  rm -rf lib/features/chat
  echo "Removed chat module."
fi

read -p "Include push notifications? (y/n): " INCLUDE_PUSH
if [ "$INCLUDE_PUSH" != "y" ]; then
  rm -rf lib/core/notifications
  echo "Removed notifications module."
fi

# 5. Install dependencies
echo "Installing Flutter dependencies..."
flutter pub get

# 6. Run code generation (Drift, Riverpod)
echo "Running code generation..."
dart run build_runner build --delete-conflicting-outputs

# 7. Start local Supabase
read -p "Start local Supabase? (y/n): " START_SUPABASE
if [ "$START_SUPABASE" == "y" ]; then
  supabase start
  supabase db reset
  echo ""
  echo "Local Supabase is running."
  echo "Studio: http://127.0.0.1:54323"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup complete! Next steps:          "
echo "  1. Update lib/config/colors.dart     "
echo "  2. Update lib/config/app_config.dart  "
echo "  3. Configure tabs in router.dart      "
echo "  4. Run: flutter run                   "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

### scripts/rename_package.sh

Handles renaming:

- `pubspec.yaml` name field
- iOS bundle identifier (`ios/Runner.xcodeproj`)
- Android applicationId (`android/app/build.gradle`)
- Dart import paths
- App display name in `AndroidManifest.xml` and `Info.plist`

### Makefile

```makefile
.PHONY: run build test clean gen supabase-start supabase-stop supabase-reset

# ─── Development ────────────────────────────
run:
	flutter run --dart-define-from-file=.env.local

run-staging:
	flutter run --dart-define-from-file=.env.staging

# ─── Code Generation ───────────────────────
gen:
	dart run build_runner build --delete-conflicting-outputs

gen-watch:
	dart run build_runner watch --delete-conflicting-outputs

# ─── Build ──────────────────────────────────
build-ios:
	flutter build ios --dart-define-from-file=.env.production

build-android:
	flutter build appbundle --dart-define-from-file=.env.production

# ─── Test ───────────────────────────────────
test:
	flutter test

test-coverage:
	flutter test --coverage

# ─── Supabase ──────────────────────────────
supabase-start:
	supabase start

supabase-stop:
	supabase stop

supabase-reset:
	supabase db reset

supabase-migrate:
	supabase migration new $(name)

supabase-functions:
	supabase functions serve --env-file .env.local

supabase-deploy:
	supabase db push
	supabase functions deploy ai-proxy
	supabase functions deploy sync-handler
	supabase functions deploy push-notification

# ─── Clean ──────────────────────────────────
clean:
	flutter clean
	rm -rf .dart_tool build
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs
```

---

## 20. Testing Strategy

### Test structure

```
test/
├── features/
│   ├── auth/
│   │   ├── providers/
│   │   │   └── auth_notifier_test.dart
│   │   └── screens/
│   │       └── login_screen_test.dart
│   ├── paywall/
│   │   └── providers/
│   │       └── entitlement_provider_test.dart
│   └── chat/
│       └── providers/
│           └── chat_notifier_test.dart
├── core/
│   ├── database/
│   │   └── daos/
│   │       └── sync_queue_dao_test.dart
│   └── sync/
│       └── sync_service_test.dart
└── shared/
    └── widgets/
        └── premium_gate_test.dart
```

### What the starter kit tests

| Layer          | What to test                                           | Tool                        |
| -------------- | ------------------------------------------------------ | --------------------------- |
| Providers      | Auth state transitions, sync logic, entitlement checks | `flutter_test` + `mocktail` |
| DAOs           | CRUD operations against in-memory Drift database       | `drift` test utilities      |
| Widgets        | Key UI states (loading, error, premium gate)           | `flutter_test` widget tests |
| Edge Functions | Request validation, auth checks, response format       | Deno test runner            |

### Running tests

```bash
# All tests
make test

# With coverage
make test-coverage

# Supabase Edge Function tests
cd supabase/functions && deno test
```

---

## 21. CI/CD

### GitHub Actions workflow (starter template)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.22.x"
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.22.x"
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter build appbundle --dart-define-from-file=.env.production

  build-ios:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.22.x"
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run:
          flutter build ios --no-codesign
          --dart-define-from-file=.env.production
```

---

## 22. What Stays OUT

This starter kit intentionally excludes anything app-specific. When you clone it
for a new app, you add these yourself:

| Category                   | Examples                                                        | Why it's excluded              |
| -------------------------- | --------------------------------------------------------------- | ------------------------------ |
| App-specific screens       | Roleplay, grounding exercises, Bible memorization, task planner | Every app is different         |
| App-specific data models   | Objections, exercises, devotionals, tasks, habits               | Schema varies per app          |
| Content / seed data        | Apologetics Q&A, scripture passages, exercise scripts           | Unique to each app             |
| App-specific color palette | PocketApologist gold, GroundMe earth tones, FlowDay blue        | Override `colors.dart`         |
| Custom animations          | Breathing circle, streak fire, confetti                         | Build per app as needed        |
| Platform integrations      | HealthKit, Calendar, Apple Watch, Widgets                       | Only some apps need these      |
| Complex AI prompts         | Roleplay system prompts, feedback rubrics                       | Prompt engineering is per-app  |
| Marketing / ASO            | App Store screenshots, descriptions, keywords                   | Created at launch time         |
| Third-party content APIs   | Bible API, devotional feeds                                     | Only relevant to specific apps |

---

## Summary

Clone → run `setup.sh` → override colors and tabs → start building features.
Everything else — auth, paywall, local DB, Supabase sync, AI proxy, push
notifications, analytics, error tracking, theming — is already wired and
working.
