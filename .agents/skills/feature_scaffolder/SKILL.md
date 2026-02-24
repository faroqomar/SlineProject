---
name: feature-scaffolder
description: Scaffold a new SLine feature with MVVM-compliant folders and starter files for model, service, viewmodel, and view. Use when creating a new feature module quickly while preserving project architecture and conventions.
---

# Feature Scaffolder

## Create Structure
```text
lib/features/<feature_name>/
├── models/
├── services/
├── viewmodels/
└── view/
    └── widgets/
```

## Generate Starter Files
1. Model with immutable fields, `fromJson`, `toJson`, `copyWith`, UTC-safe timestamps.
2. Service with Supabase access, CRUD methods, and error mapping.
3. ViewModel extending `ChangeNotifier` with loading/error/data state and async actions.
4. View screen wired to ViewModel via `Consumer` and explicit loading/error/empty/data UI states.

## Integrate
1. Provide dependency registration snippet for `lib/main.dart` provider setup.
2. Keep routing hooks minimal and explicit.

## Standards
- Use `AppLogger`; do not use `print()`.
- Keep business logic out of views.
- Use app theme tokens and shared widgets.
