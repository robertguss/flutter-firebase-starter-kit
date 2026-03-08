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

  static void init() {
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    current = Environment.values.firstWhere(
      (environment) => environment.name == envString,
      orElse: () => Environment.dev,
    );
  }
}
