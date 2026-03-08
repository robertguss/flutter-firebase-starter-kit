# Adding a New Locale

This project uses Flutter's built-in localization (l10n) with ARB files.

## Steps

1. **Create a new ARB file** in `lib/l10n/` named `app_XX.arb`, where `XX` is
   the language code (e.g., `app_es.arb` for Spanish, `app_fr.arb` for French).

   Copy `app_en.arb` as a starting point and translate each value:

   ```json
   {
     "@@locale": "es",
     "appTitle": "Kit de Inicio",
     "signInPrompt": "Inicia sesión para continuar",
     "signInWithGoogle": "Iniciar sesión con Google",
     "signInWithApple": "Iniciar sesión con Apple"
   }
   ```

2. **Add the locale** to `supportedLocales` in `lib/app.dart`:

   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('es'), // Add your new locale
   ],
   ```

3. **Regenerate** localization files:

   ```bash
   flutter gen-l10n
   ```

   Or use the Makefile:

   ```bash
   make build-runner
   ```

4. **Verify** the new locale compiles:

   ```bash
   flutter analyze
   ```

## Configuration

The l10n configuration lives in `l10n.yaml` at the project root:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

## Tips

- The English file (`app_en.arb`) is the template. All keys defined there must
  exist in every other locale file.
- Use ICU message syntax for plurals and selects. See the
  [Flutter l10n guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
  for details.
- Interpolation uses `{variableName}` syntax (e.g., `"Hello, {name}"`).
- Error messages from Firebase SDKs should not be localized — they come from the
  SDK and are developer-facing.
