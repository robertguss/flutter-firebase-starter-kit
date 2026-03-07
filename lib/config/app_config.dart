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

  // Legal
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';

  // Feature Flags
  static const bool enablePaywall = true;
  static const bool enableNotifications = true;

  // Navigation
  static const int bottomNavTabCount = 2;
}
