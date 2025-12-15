---
description: How to add a new feature following strict MVVM and clean architecture
---

# Feature Implementation Workflow

Follow this checklist to implement a new feature with zero errors.

## 1. Plan & Schema
- [ ] Check `Sline_everything/SUPABASE_SETUP.md` for existing tables.
- [ ] Define new table schema if needed (Columns, Types, FKs).
- [ ] Define RLS policies (SELECT, INSERT, UPDATE, DELETE).
- [ ] Create `lib/features/[feature_name]` directory structure.

## 2. Data Layer (Supabase)
- [ ] **Model**: Create `[feature]_model.dart` in `models/`.
    - [ ] Immutable (`final` fields).
    - [ ] `fromJson` / `toJson` methods.
    - [ ] `DateTime` fields handled as UTC.
- [ ] **Service**: Create `[feature]_service.dart` in `services/`.
    - [ ] Implement CRUD methods.
    - [ ] **CRITICAL**: Use JOINs for related data (No N+1 loops).
    - [ ] Map all errors using `_mapError` helper.

## 3. Business Logic (ViewModel)
- [ ] Create `[feature]_view_model.dart` in `viewmodels/`.
    - [ ] Extend `ChangeNotifier`.
    - [ ] Add `bool _isLoading` and `String? _error`.
    - [ ] Inject Service instance in constructor.
    - [ ] Implement methods (e.g., `loadItems`, `createItem`).
    - [ ] Call `notifyListeners()` on state changes.

## 4. UI Layer (View)
- [ ] Create `[feature]_screen.dart` in `view/`.
- [ ] Wrap with `ChangeNotifierProvider` in `main.dart` or locally.
- [ ] Use `Consumer<[Feature]ViewModel>` to build UI.
- [ ] **CRITICAL**: NO `Supabase.instance` calls in widgets.
- [ ] Use `AppTheme` colors and typography.

## 5. Register & Test
- [ ] Add provider to `MultiProvider` in `lib/main.dart` (if global).
- [ ] Run `flutter analyze` to check for lints.
- [ ] Run manual validation.
