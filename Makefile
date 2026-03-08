.PHONY: setup get analyze test build-runner watch clean run-dev run-staging run-prod

setup: ## Initial project setup
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

get: ## Install dependencies
	flutter pub get

analyze: ## Run static analysis
	flutter analyze

test: ## Run all tests
	flutter test

build-runner: ## Run code generation
	dart run build_runner build --delete-conflicting-outputs

watch: ## Watch for changes and regenerate
	dart run build_runner watch --delete-conflicting-outputs

run-dev: ## Run app with dev flavor
	flutter run --flavor dev -t lib/main_dev.dart

run-staging: ## Run app with staging flavor
	flutter run --flavor staging -t lib/main_staging.dart

run-prod: ## Run app with prod flavor
	flutter run --flavor prod -t lib/main_prod.dart

clean: ## Clean build artifacts
	flutter clean
	flutter pub get

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
