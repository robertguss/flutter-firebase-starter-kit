class AppConfig {
  static const String appName = 'Starter Kit';
  static const String bundleId = 'com.example.starterkit';

  // RevenueCat (set via --dart-define)
  static const String revenueCatAppleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: '',
  );
  static const String revenueCatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: '',
  );

  // Legal — TODO: Replace with your app's legal URLs before publishing
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';

  /// Call in debug mode to warn about placeholder URLs.
  static void debugCheckPlaceholders() {
    assert(
      !privacyPolicyUrl.contains('example.com'),
      'Replace placeholder privacy policy URL before publishing',
    );
    assert(
      !termsOfServiceUrl.contains('example.com'),
      'Replace placeholder terms of service URL before publishing',
    );
  }

  // Feature Flags
  static const bool enablePaywall = true;
  static const bool enableNotifications = true;
  static const bool enableCrashlytics = true;
  static const bool enableAnalytics = true;

  // Navigation
  static const int bottomNavTabCount = 2;
}
