# List available commands
default:
    @just --list

# Initial project setup
setup:
    @echo "Checking Flutter version..."
    @flutter --version
    @echo ""
    @echo "Installing dependencies..."
    @flutter pub get
    @echo ""
    @echo "Running analysis..."
    @flutter analyze
    @echo ""
    @echo "Setup complete! Next steps:"
    @echo "  1. Run 'flutterfire configure' to generate firebase_options.dart"
    @echo "  2. Edit lib/config/app_config.dart (app name, API keys)"
    @echo "  3. Edit lib/config/theme.dart (colors, fonts)"
    @echo "  4. Run 'flutter run' to launch the app"

# Install dependencies
get:
    flutter pub get

# Run static analysis
analyze:
    flutter analyze

# Run all tests
test:
    flutter test

# Run code generation
build-runner:
    dart run build_runner build --delete-conflicting-outputs

# Watch for changes and regenerate
watch:
    dart run build_runner watch --delete-conflicting-outputs

# Run app with dev flavor
run-dev:
    flutter run --flavor dev -t lib/main_dev.dart

# Run app with staging flavor
run-staging:
    flutter run --flavor staging -t lib/main_staging.dart

# Run app with prod flavor
run-prod:
    flutter run --flavor prod -t lib/main_prod.dart

# Clean build artifacts
clean:
    flutter clean
    flutter pub get
