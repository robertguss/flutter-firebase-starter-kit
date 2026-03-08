import 'package:flutter_starter_kit/config/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Environment enum', () {
    test('dev enables verbose logging', () {
      expect(Environment.dev.verboseLogging, true);
    });

    test('dev shows debug banner', () {
      expect(Environment.dev.showDebugBanner, true);
    });

    test('dev disables crashlytics', () {
      expect(Environment.dev.enableCrashlytics, false);
    });

    test('staging enables verbose logging', () {
      expect(Environment.staging.verboseLogging, true);
    });

    test('staging hides debug banner', () {
      expect(Environment.staging.showDebugBanner, false);
    });

    test('staging disables crashlytics', () {
      expect(Environment.staging.enableCrashlytics, false);
    });

    test('prod disables verbose logging', () {
      expect(Environment.prod.verboseLogging, false);
    });

    test('prod hides debug banner', () {
      expect(Environment.prod.showDebugBanner, false);
    });

    test('prod enables crashlytics', () {
      expect(Environment.prod.enableCrashlytics, true);
    });
  });

  group('EnvironmentConfig', () {
    tearDown(() {
      // Reset to default after each test
      EnvironmentConfig.current = Environment.dev;
    });

    test('init with explicit environment uses it directly', () {
      EnvironmentConfig.init(Environment.staging);
      expect(EnvironmentConfig.current, Environment.staging);
    });

    test('init with prod sets prod', () {
      EnvironmentConfig.init(Environment.prod);
      expect(EnvironmentConfig.current, Environment.prod);
    });

    test('defaults to dev', () {
      // Without --dart-define, fromEnvironment returns 'dev'
      EnvironmentConfig.init();
      expect(EnvironmentConfig.current, Environment.dev);
    });
  });
}
