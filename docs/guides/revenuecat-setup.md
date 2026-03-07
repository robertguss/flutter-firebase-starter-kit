# RevenueCat Setup

This guide explains how to connect the starter kit to RevenueCat and how the
current code expects subscriptions to be modeled.

## What the Starter Kit Assumes

The current implementation assumes:

- RevenueCat is enabled when `AppConfig.enablePaywall` is `true`
- The active entitlement ID is `premium`
- There is a current offering with at least one available package
- Public SDK keys are stored in `lib/config/app_config.dart`

Relevant files:

- `lib/config/app_config.dart`
- `lib/features/paywall/services/purchases_service.dart`
- `lib/features/paywall/providers/purchases_provider.dart`
- `lib/features/paywall/screens/paywall_screen.dart`
- `lib/features/settings/screens/settings_screen.dart`

## 1. Create a RevenueCat Account and Project

Start here:

- [RevenueCat SDK quickstart](https://www.revenuecat.com/docs/getting-started/quickstart)

Inside RevenueCat:

1. Create a project.
2. Add your iOS app.
3. Add your Android app.

## 2. Create the Entitlement

Create an entitlement named:

```text
premium
```

Why this matters:

The starter kit checks the active entitlements map for `premium`. If you use a
different entitlement name, update the code and docs together.

## 3. Create Store Products

RevenueCat does not replace App Store Connect or Google Play product setup.

You still need to create your subscription products in:

- App Store Connect
- Google Play Console

Typical pattern:

- monthly subscription
- yearly subscription

## 4. Attach Products to the Entitlement

After your store products exist:

1. Open the `premium` entitlement in RevenueCat.
2. Attach the iOS and Android products that should unlock premium access.

## 5. Create an Offering

Create at least one current offering in RevenueCat.

That offering should include one or more packages, for example:

- monthly
- annual

The paywall screen currently reads:

- `offerings.current`
- `current.availablePackages.first`

So if you do not have a current offering, the paywall cannot render a purchase
action.

## 6. Copy the Public SDK Keys

Put the RevenueCat public SDK keys into:

- `AppConfig.revenueCatAppleApiKey`
- `AppConfig.revenueCatGoogleApiKey`

These belong in:

- `lib/config/app_config.dart`

These are public SDK keys, not backend secrets. Do not confuse them with
server-side API keys.

## 7. Understand the Current Purchase Flow

The current app:

- configures RevenueCat in `main.dart`
- fetches offerings in a provider
- checks the `premium` entitlement to decide access
- supports restore purchases from both the settings screen and the paywall

What it does not yet do:

- sync premium state automatically after sign-in
- persist premium state outside the provider lifecycle
- handle upgrade and downgrade flows in a product-specific way
- provide a polished paywall design or experiment framework

## 8. Test the Integration

Use RevenueCat's docs for current testing flows:

- [RevenueCat Flutter SDK installation](https://www.revenuecat.com/docs/getting-started/installation/flutter)
- [RevenueCat SDK quickstart](https://www.revenuecat.com/docs/getting-started/quickstart)

When testing, verify:

1. `Purchases.configure` succeeds
2. `getOfferings()` returns a current offering
3. `purchase(...)` returns a `CustomerInfo`
4. The `premium` entitlement becomes active
5. Restore purchases updates state correctly

## 9. Common RevenueCat Issues in This Starter Kit

### No offerings available

Usually caused by one of:

- wrong API key
- no current offering
- products not attached to the offering
- products not attached to the `premium` entitlement
- store products not fully configured yet

### Purchases succeed but premium never unlocks

Check:

- the entitlement ID really is `premium`
- the purchased products are attached to that entitlement
- the active entitlement is present in `CustomerInfo`

### Restore works but the UI does not update as expected

The starter kit updates `isPremiumProvider` directly in the current widget flow.
If you need a more reliable app-wide subscription state, introduce a dedicated
subscription controller and refresh strategy.
