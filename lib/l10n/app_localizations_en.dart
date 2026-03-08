// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get signInPrompt => 'Sign in to get started';

  @override
  String get authenticationError => 'Authentication error. Please try again.';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get onboardingWelcomeTitle => 'Welcome to AppName';

  @override
  String get onboardingWelcomeDescription =>
      'Your all-in-one solution for staying organized and productive. We help you focus on what matters most.';

  @override
  String get onboardingTrackTitle => 'Stay on Track';

  @override
  String get onboardingTrackDescription =>
      'Set goals, track your progress, and celebrate your wins. Smart reminders keep you moving forward every day.';

  @override
  String get onboardingGetStartedTitle => 'Get Started';

  @override
  String get onboardingGetStartedDescription =>
      'You\'re all set! Dive in and explore everything the app has to offer. Your journey starts now.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get subscription => 'Subscription';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get premium => 'Premium';

  @override
  String get free => 'Free';

  @override
  String get viewPlans => 'View plans';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get about => 'About';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get opensInBrowser => 'Opens in browser';

  @override
  String get account => 'Account';

  @override
  String get signOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmation =>
      'This will permanently delete your account and all data. This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get requiresRecentLogin => 'Please sign in again to continue.';

  @override
  String versionInfo(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get unlockPremium => 'Unlock Premium';

  @override
  String get getAccessToAllFeatures => 'Get access to all features';

  @override
  String get feature => 'Feature';

  @override
  String get basicAccess => 'Basic Access';

  @override
  String get premiumFeature1 => 'Premium Feature 1';

  @override
  String get premiumFeature2 => 'Premium Feature 2';

  @override
  String get noOfferingsAvailable => 'No offerings available';

  @override
  String get noPackagesAvailable => 'No packages available';

  @override
  String subscribePrice(String price) {
    return 'Subscribe - $price';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get unableToLoadOfferings =>
      'Unable to load offerings. Please try again.';

  @override
  String get purchasesRestored => 'Purchases restored!';

  @override
  String get close => 'Close';

  @override
  String get homeScreenPlaceholder =>
      'Home Screen - replace with your app content';

  @override
  String get homeNavLabel => 'Home';

  @override
  String get profileNavLabel => 'Profile';

  @override
  String get retry => 'Retry';

  @override
  String get errorSemanticLabel => 'Error';

  @override
  String get premiumFeature => 'Premium Feature';

  @override
  String get premiumFeatureLocked => 'Premium feature locked';
}
