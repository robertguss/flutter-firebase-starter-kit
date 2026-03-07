# Architecture Overview

This starter kit is organized around feature folders and a thin shared layer.

The goal is simple:

- make it easy to understand where code belongs
- make features easy to remove or replace
- keep app startup predictable

## High-Level Architecture

```text
main.dart
  -> initialize environment
  -> initialize Firebase
  -> initialize RevenueCat (optional)
  -> initialize FCM (optional)
  -> ProviderScope
  -> App
      -> theme provider
      -> router provider
      -> feature screens
```

## Repository Structure

```text
lib/
  app.dart
  main.dart
  config/
  features/
    auth/
    home/
    notifications/
    onboarding/
    paywall/
    settings/
  routing/
  shared/
test/
docs/
```

## Layer Responsibilities

## `config/`

Holds app-wide configuration and theme concerns.

Use this layer for:

- app naming
- feature flags
- environment selection
- theming

## `features/`

Each feature owns its own screens, providers, services, and widgets.

Current features:

- `auth`
- `home`
- `notifications`
- `onboarding`
- `paywall`
- `settings`

This is the most important organizational rule in the starter kit. If a piece of
code exists for one feature only, prefer to keep it inside that feature.

## `routing/`

Defines route constants and the GoRouter configuration.

Current route set:

- `/auth`
- `/onboarding`
- `/home`
- `/settings`
- `/paywall`

## `shared/`

Contains code used across multiple features.

Current shared areas:

- Firebase startup service
- generic loading widget
- premium-gate widget

## State Management

This starter kit uses Riverpod.

Patterns currently in use:

- `Provider` for lightweight service wiring
- `StreamProvider` for auth state
- `NotifierProvider` for mutable local app state such as onboarding and theme
  mode
- `StateProvider` for simple in-memory values such as premium state

Why this is a good starter choice:

- dependency injection is explicit
- tests stay straightforward
- feature state is easy to locate

## Navigation

Navigation uses GoRouter.

Current behavior:

- unauthenticated users are redirected to `/auth`
- authenticated users visiting `/auth` are redirected to `/home`
- onboarding route exists

Current limitation:

The router does not yet enforce onboarding completion based on Firestore profile
state. That work is called out in the router as a TODO.

## Data Flow

### Authentication

`AuthService` wraps Firebase Auth and social sign-in providers.

`authStateProvider` exposes Firebase auth state as a stream for the router and
other consumers.

### User profiles

`UserProfileService` reads and writes Firestore documents in `users/{uid}`.

### Subscriptions

`PurchasesService` wraps RevenueCat SDK calls.

The UI currently checks whether the `premium` entitlement is active.

### Theme mode

`ThemeModeNotifier` persists light/dark mode through `SharedPreferences`.

## Test Strategy

The repository includes focused tests around:

- auth service behavior
- auth provider behavior
- theme provider behavior
- onboarding provider behavior
- paywall provider behavior
- route constants
- smoke-test level app/provider wiring

This is a solid starter baseline, but not yet a full product-grade test suite.

## What Is Production-Ready vs Placeholder

### Strong starter foundations

- feature-folder layout
- Riverpod provider wiring
- GoRouter auth guard
- Firestore profile service
- RevenueCat service abstraction
- settings, onboarding, and paywall starter flows

### Placeholder or intentionally incomplete areas

- copy and branding
- onboarding completion enforcement in routing
- home screen content
- FCM presentation and deep-link handling
- production Firestore security rules
- environment-specific secret and config management

## Recommended Next Steps for a Real Product

If you adopt this starter kit, these are usually the first architectural
follow-ups:

1. Introduce generated Firebase options
2. Add an onboarding/profile state provider used by the router
3. Persist subscription state more robustly
4. Add analytics and crash reporting
5. Add stricter security rules and backend validation
6. Replace placeholder screens and strings with real product UX
