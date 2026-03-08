// =============================================================================
// RIVERPOD CODEGEN MIGRATION GUIDE (2025-2026)
// =============================================================================
// Comprehensive best practices for migrating from manual providers to
// @riverpod code generation, covering Riverpod 2.x through 3.0.
//
// Sources:
//   - Official Riverpod docs: https://riverpod.dev/docs/concepts/about_code_generation
//   - What's new in 3.0: https://riverpod.dev/docs/whats_new
//   - Migration guide: https://riverpod.dev/docs/migration/from_state_notifier
//   - Andrea Bizzotto: https://codewithandrea.com/articles/flutter-riverpod-generator/
//   - Context7 / rrousselgit/riverpod v3.0.2
// =============================================================================

// ignore_for_file: unused_import, unused_element, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_test/flutter_test.dart';

// Every file using codegen MUST include its generated part file:
part 'riverpod-codegen-migration-guide.g.dart';

// =============================================================================
// 1. MIGRATION PATTERN: Manual Providers -> @riverpod Annotations
// =============================================================================

// --- BEFORE (manual) ---
// final helloWorldProvider = Provider<String>((ref) => 'Hello world');

// --- AFTER (codegen) ---
// Function-based provider: function name becomes provider name with "Provider" suffix.
// `helloWorld` generates `helloWorldProvider`.
@riverpod
String helloWorld(Ref ref) {
  return 'Hello world';
}

// --- BEFORE (manual StateNotifierProvider) ---
// class CounterNotifier extends StateNotifier<int> {
//   CounterNotifier() : super(0);
//   void increment() => state++;
// }
// final counterProvider = StateNotifierProvider<CounterNotifier, int>(
//   (ref) => CounterNotifier(),
// );

// --- AFTER (codegen class-based Notifier) ---
// Class name generates provider: `Counter` -> `counterProvider`
// Extends generated `_$Counter`. The `build()` method replaces the constructor.
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0; // Initial state (replaces super(0))

  void increment() => state++;
  void decrement() => state--;
}

// --- ASYNC NOTIFIER (codegen) ---
// Return type determines provider type automatically:
//   - Returns T        -> Provider<T>
//   - Returns Future<T> -> FutureProvider<T> / AsyncNotifierProvider
//   - Returns Stream<T> -> StreamProvider<T>
@riverpod
class TodoList extends _$TodoList {
  @override
  Future<List<String>> build() async {
    // Fetch from API, database, etc.
    return ['Todo 1', 'Todo 2'];
  }

  Future<void> addTodo(String todo) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final current = await future;
      return [...current, todo];
    });
  }
}


// =============================================================================
// 2. keepAlive vs autoDispose DECISIONS
// =============================================================================

// DEFAULT: All codegen providers are autoDispose.
// They dispose when no widget/provider is listening.

// autoDispose (default) - use for:
//   - Screen-specific state
//   - Search results, form state
//   - Anything that should reset when user navigates away
@riverpod
String screenSpecificData(Ref ref) => 'disposed when not watched';

// keepAlive: true - use for:
//   - Auth state (must persist across navigation)
//   - App configuration / API keys
//   - Cached data that's expensive to refetch
//   - Anything that should survive the whole app lifecycle
@Riverpod(keepAlive: true)
String apiKey(Ref ref) => 'your-api-key-here';

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  Stream<bool> build() {
    // Auth state should persist - never auto-dispose
    return Stream.value(true);
  }
}

// HYBRID: autoDispose + manual keepAlive via ref.keepAlive()
// Use when disposal depends on runtime conditions.
@riverpod
int cachedDiceRoll(Ref ref) {
  final coin = 5;
  if (coin > 3) {
    // Keep alive only if condition met
    ref.keepAlive();
  }
  return coin;
}


// =============================================================================
// 3. MIGRATING StateProvider (Deprecated in Riverpod 2.x+)
// =============================================================================

// StateProvider is deprecated. Replace with class-based Notifier.

// --- BEFORE (deprecated) ---
// final filterProvider = StateProvider<String>((ref) => 'all');

// --- AFTER (codegen Notifier) ---
@riverpod
class Filter extends _$Filter {
  @override
  String build() => 'all'; // Initial value

  void setFilter(String newFilter) => state = newFilter;
}
// Usage: ref.watch(filterProvider) for value
// Usage: ref.read(filterProvider.notifier).setFilter('active')

// --- BEFORE (deprecated) ---
// final isDarkModeProvider = StateProvider<bool>((ref) => false);

// --- AFTER (codegen Notifier) ---
@riverpod
class IsDarkMode extends _$IsDarkMode {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

// --- BEFORE (deprecated counter) ---
// final counterProvider = StateProvider<int>((ref) => 0);

// --- AFTER ---
// See the Counter class above in section 1.
// ref.read(counterProvider.notifier).increment() replaces
// ref.read(counterProvider.notifier).state++


// =============================================================================
// 4. PROVIDER OVERRIDES IN TESTS WITH CODEGEN
// =============================================================================

// Codegen providers support the same override methods as manual providers.
// In Riverpod 3.0, overrideWithValue is restored for Future/StreamProvider.

void testExamples() {
  // --- Override a simple function provider ---
  // test('override simple provider', () {
  //   final container = ProviderContainer(
  //     overrides: [
  //       helloWorldProvider.overrideWithValue('Mocked hello'),
  //     ],
  //   );
  //   expect(container.read(helloWorldProvider), 'Mocked hello');
  //   container.dispose();
  // });

  // --- Override a Notifier provider's build method (Riverpod 3.0) ---
  // NotifierProvider.overrideWithBuild: mocks only build(), keeps methods.
  // test('override notifier build', () {
  //   final container = ProviderContainer(
  //     overrides: [
  //       counterProvider.overrideWithBuild((ref) => 42),
  //     ],
  //   );
  //   expect(container.read(counterProvider), 42);
  //   // Methods still work:
  //   container.read(counterProvider.notifier).increment();
  //   expect(container.read(counterProvider), 43);
  //   container.dispose();
  // });

  // --- Widget test with ProviderScope overrides ---
  // testWidgets('widget test with overrides', (tester) async {
  //   await tester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         helloWorldProvider.overrideWithValue('Test value'),
  //       ],
  //       child: const MaterialApp(home: MyWidget()),
  //     ),
  //   );
  //   expect(find.text('Test value'), findsOneWidget);
  // });

  // --- Override with function (for providers with parameters) ---
  // Riverpod 3.0: ref now contains provider parameters, enabling:
  // test('override family provider', () {
  //   final container = ProviderContainer(
  //     overrides: [
  //       greetingProvider.overrideWith((ref) => 'Mocked'),
  //     ],
  //   );
  // });

  // --- Riverpod 3.0: tester.container extension ---
  // testWidgets('access container in widget tests', (tester) async {
  //   await tester.pumpWidget(
  //     ProviderScope(child: const MaterialApp(home: MyWidget())),
  //   );
  //   // New in 3.0: direct access to ProviderContainer
  //   final container = tester.container;
  //   expect(container.read(counterProvider), 0);
  // });
}


// =============================================================================
// 5. MIGRATING PROVIDERS THAT RETURN FUNCTION TYPES (Action Providers)
// =============================================================================

// Common pattern: Provider that returns a callback/function.
// Cannot use function-based codegen directly for this.
// Use a class-based Notifier instead.

// --- BEFORE (manual) ---
// final submitFormProvider = Provider<Future<void> Function(String)>((ref) {
//   return (String data) async {
//     final api = ref.read(apiProvider);
//     await api.submit(data);
//   };
// });

// --- AFTER (codegen class-based) ---
// Option A: Notifier with action methods (RECOMMENDED)
@riverpod
class FormSubmitter extends _$FormSubmitter {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> submit(String data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // await ref.read(apiProvider).submit(data);
    });
  }
}
// Usage: ref.read(formSubmitterProvider.notifier).submit('data')
// UI reacts to loading/error/success via ref.watch(formSubmitterProvider)

// Option B: Riverpod 3.0 @mutation (Experimental, codegen only)
// @riverpod
// class FormSubmitterV2 extends _$FormSubmitterV2 {
//   @override
//   String build() => '';
//
//   @mutation
//   Future<String> submit(String data) async {
//     // The @mutation annotation auto-tracks loading/error for this method
//     await Future.delayed(Duration(seconds: 1));
//     return 'submitted: $data';
//   }
// }
// UI: final mutation = ref.watch(formSubmitterV2Provider.notifier).submit;
// mutation.state gives you AsyncValue tracking for free.


// =============================================================================
// 6. PROJECT STRUCTURE FOR .g.dart FILES
// =============================================================================

// RECOMMENDED: Co-locate .g.dart files next to their source files.
// Do NOT create separate directories for generated files.
//
// lib/
// +-- features/
// |   +-- auth/
// |   |   +-- providers/
// |   |   |   +-- auth_provider.dart        <-- source
// |   |   |   +-- auth_provider.g.dart      <-- generated (same directory)
// |   |   +-- services/
// |   |   +-- screens/
// |   +-- home/
// |   |   +-- providers/
// |   |   |   +-- home_provider.dart
// |   |   |   +-- home_provider.g.dart
//
// .gitignore considerations:
//   - COMMIT .g.dart files to source control (recommended by Riverpod team)
//   - This avoids requiring build_runner in CI just to compile
//   - Alternative: add *.g.dart to .gitignore and run build_runner in CI
//
// build.yaml (optional, place at project root):
// targets:
//   $default:
//     builders:
//       riverpod_generator:
//         generate_for:
//           - lib/features/**/providers/*.dart
//           - lib/shared/**/*.dart


// =============================================================================
// 7. COMMON PITFALLS DURING MIGRATION
// =============================================================================

// PITFALL 1: Forgetting `part` directive
// Every file using @riverpod MUST have: part '<filename>.g.dart';
// Without it, the generator silently produces nothing.

// PITFALL 2: Wrong class name / extends
// Class must extend _$ClassName (generated). If you rename the class,
// you must re-run build_runner before the new base class exists.

// PITFALL 3: Mixing manual and codegen for the same provider
// Don't partially migrate. Either a provider is fully codegen or fully manual.
// They CAN coexist in the same app, just not the same provider.

// PITFALL 4: Forgetting build() return type matters
// - `int build()` -> synchronous Provider
// - `Future<int> build()` -> AsyncNotifierProvider
// - `Stream<int> build()` -> StreamNotifierProvider
// Changing return type changes the provider type entirely.

// PITFALL 5: Riverpod 3.0 - Notifiers are recreated on every rebuild
// In 3.0, Notifier/AsyncNotifier instances are recreated when dependencies
// change. Do NOT store timers, controllers, or streams as instance fields.
// Instead, use separate providers and bind lifecycle with ref.onDispose.

// PITFALL 6: Using `ref` after disposal
// Riverpod 3.0 throws if you use ref after provider disposal.
// Always check ref.mounted before async operations:
@riverpod
class SafeAsync extends _$SafeAsync {
  @override
  Future<String> build() async => 'initial';

  Future<void> fetchData() async {
    state = const AsyncValue.loading();
    final result = await Future.delayed(
      const Duration(seconds: 1),
      () => 'fetched',
    );
    // CRITICAL in 3.0: check mounted before setting state
    if (!ref.mounted) return;
    state = AsyncValue.data(result);
  }
}

// PITFALL 7: .valueOrNull removed in 3.0
// Replace asyncValue.valueOrNull with asyncValue.value (now nullable).

// PITFALL 8: AutoDispose interfaces removed in 3.0
// AutoDisposeRef, AutoDisposeNotifier, etc. are gone.
// Just use Ref and Notifier. keepAlive is annotation-level only.

// PITFALL 9: Family providers changed in 3.0
// "FamilyNotifier" and "Notifier" are fused into one class.
// Family arguments come through build() parameters directly.
@riverpod
class UserProfile extends _$UserProfile {
  @override
  Future<String> build(int userId) async {
    // userId is the family parameter - passed through build()
    return 'User $userId';
  }
}
// Usage: ref.watch(userProfileProvider(42))


// =============================================================================
// 8. @riverpod (lowercase) vs @Riverpod() (constructor)
// =============================================================================

// @riverpod (lowercase, no parentheses)
//   - Uses all defaults: autoDispose = true, no special config
//   - Simplest syntax for most providers
//   - RECOMMENDED for the majority of providers
@riverpod
String simpleProvider(Ref ref) => 'default config';

@riverpod
class SimpleNotifier extends _$SimpleNotifier {
  @override
  int build() => 0;
}

// @Riverpod() (constructor, with parentheses)
//   - Required when you need to configure the provider
//   - Currently the main option is keepAlive
//   - Use when you need keepAlive: true
@Riverpod(keepAlive: true)
String persistentProvider(Ref ref) => 'persists forever';

@Riverpod(keepAlive: true)
class PersistentNotifier extends _$PersistentNotifier {
  @override
  int build() => 0;
}

// RULE OF THUMB:
//   - Default autoDispose behavior? -> @riverpod
//   - Need keepAlive or other config? -> @Riverpod(keepAlive: true)
//   - @Riverpod() with no args is equivalent to @riverpod


// =============================================================================
// 9. HOW Ref WORKS IN CODEGEN (Changed in Riverpod 3.0)
// =============================================================================

// RIVERPOD 2.x: Multiple Ref types existed
//   - Ref (base)
//   - AutoDisposeRef
//   - WidgetRef (for widgets)
//   - Various typed refs per provider type

// RIVERPOD 3.0: "One Ref to rule them all"
//   - All provider functions take plain `Ref ref` as first parameter
//   - AutoDisposeRef is removed - just use Ref
//   - WidgetRef still exists for ConsumerWidget/ConsumerStatefulWidget
//   - Ref now contains provider parameters (for family providers)

// Function-based: Ref is the first parameter
@riverpod
String refExample(Ref ref) {
  // ref.watch, ref.read, ref.listen all available
  // ref.onDispose for cleanup
  // ref.keepAlive() for conditional persistence
  // ref.mounted for async safety (3.0)
  ref.onDispose(() {
    print('Provider disposed');
  });
  return 'example';
}

// Class-based: ref is available as this.ref (inherited from _$ClassName)
@riverpod
class RefInClass extends _$RefInClass {
  @override
  String build() {
    // `ref` is available directly (no parameter needed)
    ref.onDispose(() => print('disposed'));
    // ref.watch(otherProvider) to create dependencies
    return 'class example';
  }

  void doSomething() {
    // ref is also available in methods
    // ref.read(otherProvider) for one-time reads
    state = 'updated';
  }
}


// =============================================================================
// 10. build_runner CONFIGURATION BEST PRACTICES
// =============================================================================

// --- COMMANDS ---
// One-time generation:
//   dart run build_runner build --delete-conflicting-outputs
//
// Watch mode (auto-regenerate on save):
//   dart run build_runner watch --delete-conflicting-outputs
//
// Clean and rebuild (when things get stuck):
//   dart run build_runner clean
//   dart run build_runner build --delete-conflicting-outputs

// --- ALWAYS use --delete-conflicting-outputs ---
// Without it, build_runner may fail if generated files conflict.
// This flag safely removes stale .g.dart files before regenerating.

// --- build.yaml (place at project root) ---
// Recommended configuration:
//
// targets:
//   $default:
//     builders:
//       riverpod_generator:
//         enabled: true
//         generate_for:
//           include:
//             - lib/features/**/providers/**
//             - lib/shared/**
//       json_serializable:
//         options:
//           explicit_to_json: true
//
// global_options:
//   riverpod_generator:riverpod_generator:
//     runs_before:
//       - json_serializable

// --- PERFORMANCE TIPS ---
// 1. Use generate_for to limit scope - don't scan entire lib/
// 2. In watch mode, save one file at a time to avoid cascading rebuilds
// 3. For CI/CD, use `build` not `watch`
// 4. Add to pubspec.yaml dev_dependencies:
//      build_runner: ^2.4.0
//      riverpod_generator: ^2.6.0  (or ^3.0.0 for Riverpod 3.x)
//      riverpod_annotation: ^2.6.0 (or ^3.0.0 for Riverpod 3.x)

// --- SCRIPT SHORTCUT (add to Makefile or justfile) ---
// gen:
//   dart run build_runner build --delete-conflicting-outputs
// watch:
//   dart run build_runner watch --delete-conflicting-outputs
// gen-clean:
//   dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs


// =============================================================================
// MIGRATION CHECKLIST
// =============================================================================
//
// [ ] Add dependencies: riverpod_annotation, riverpod_generator, build_runner
// [ ] Add `part '<filename>.g.dart';` to each file with @riverpod
// [ ] Migrate simple Provider -> @riverpod function
// [ ] Migrate StateProvider -> @riverpod class with setter methods
// [ ] Migrate StateNotifierProvider -> @riverpod class extending _$ClassName
// [ ] Migrate FutureProvider -> @riverpod async function
// [ ] Migrate StreamProvider -> @riverpod Stream function
// [ ] Replace action/callback providers with class-based Notifiers
// [ ] Decide keepAlive for each provider (default autoDispose is usually right)
// [ ] Run `dart run build_runner build --delete-conflicting-outputs`
// [ ] Update tests: override methods work the same way
// [ ] Remove old StateNotifier imports
// [ ] Run `flutter analyze` to catch any issues
// [ ] Run `flutter test` to verify everything still works
//
// INCREMENTAL APPROACH: Migrate one feature folder at a time.
// Manual and codegen providers coexist peacefully.
// =============================================================================
