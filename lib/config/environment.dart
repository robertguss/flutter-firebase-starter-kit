enum Environment {
  dev,
  staging,
  prod;

  bool get enableCrashlytics => this == prod;
  bool get showDebugBanner => this == dev;
  bool get verboseLogging => this != prod;
}

class EnvironmentConfig {
  static Environment current = Environment.dev;

  /// Initialize the environment.
  ///
  /// When called with an explicit [env] (from flavor entry points like
  /// main_dev.dart), uses that directly. When called without arguments
  /// (from main.dart), falls back to --dart-define=ENV=dev.
  static void init([Environment? env]) {
    if (env != null) {
      current = env;
      return;
    }
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    current = Environment.values.firstWhere(
      (environment) => environment.name == envString,
      orElse: () => Environment.dev,
    );
  }
}
