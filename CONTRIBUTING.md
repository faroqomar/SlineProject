# Contributing to SLine

## Getting Started

1. Install Flutter SDK 3.8.1+
2. Clone the repository
3. Run `flutter pub get`
4. Enable pre-commit hooks: `git config core.hooksPath .githooks`

## Architecture

SLine uses **strict MVVM** with Provider state management:

```
View -> ViewModel -> Service/Repository -> Supabase
```

See [CLAUDE.md](CLAUDE.md) for full architecture rules and conventions.

## PR Process

1. Create a feature branch from `main`
2. Make your changes
3. Run `flutter test` (all tests must pass)
4. Run `flutter analyze` (must be clean, no warnings)
5. Run `dart format .` (must pass)
6. Push and open a PR (template is auto-applied)
7. Wait for CI checks to pass and code review

## Testing

- Run `flutter test` before every PR
- Maintain the **40% coverage floor** (CI enforces this)
- Use `AppLogger.i/d/w/e()` for logging, never `print()` or `debugPrint()`
- Follow existing test patterns in `test/` directory

## Code Style

- Linting: `very_good_analysis` with additional SLine-specific rules
- See `analysis_options.yaml` for the full ruleset
- Colors: Use `AppColors.*` or `context.colorScheme.*`, never hardcode `Color(0xFF...)`
- Timestamps: Store UTC in DB, convert to local in UI via `formatUtcToLocal()`

## Database Migrations

All migration PRs must follow [MIGRATION_REVIEW_CHECKLIST.md](MIGRATION_REVIEW_CHECKLIST.md).

## Dependency Security

- **Pub (Dart/Flutter) dependencies**: Monitored via GitHub Dependabot alerts (Settings > Code Security)
- **GitHub Actions dependencies**: Scanned by the `Dependency Vulnerability Check` CI workflow
- **Secrets**: Pre-commit hook scans for leaked credentials. Never commit `.env` files.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting. Never commit `.env`, `secrets.json`, or `credentials.json` files.
