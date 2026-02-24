---
name: asset-manager
description: Manage Flutter assets safely with generated constants and synchronized pubspec declarations. Use when adding, moving, or refactoring assets to avoid runtime missing-asset errors and eliminate raw path strings.
---

# Asset Manager

## Execute
1. Scan `assets/` recursively and list files by category (`images`, `icons`, etc.).
2. Generate or update `lib/core/constants/app_assets.dart` with typed constants.
3. Ensure `pubspec.yaml` includes required `assets:` entries.
4. Replace raw `Image.asset('...')` and similar string paths with `AppAssets.*` constants.
5. Remove stale constants that point to deleted files.

## Naming Rules
- Use lower_snake_case constant names.
- Keep folder context in ambiguous names (example: `iconsHomeFilled` vs `home`).
- Keep values as project-relative asset paths.

## Verification
1. Run `flutter analyze`.
2. Run at least one screen that uses updated assets.
3. Confirm no `"Unable to load asset"` runtime log remains.

## Usage Example
- Wrong: `Image.asset('assets/images/logo.png')`
- Right: `Image.asset(AppAssets.logo)`
