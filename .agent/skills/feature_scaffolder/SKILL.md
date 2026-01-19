---
description: Generates boilerplate code and folder structure for new features following strict MVVM.
---

# Feature Scaffold Generator

**Goal**: Instantaneously setup a pristine, compliant MVVM feature structure.

## Usage
`@FeatureScaffolder "Create feature X"`

## Scaffolding Steps

1.  **Directory Structure Creation**:
    ```text
    lib/features/[name]/
    ├── models/
    ├── services/
    ├── viewmodels/
    └── view/
        └── widgets/
    ```

2.  **File Generation**:

    **A. Model** (`models/[name]_model.dart`):
    - Immutable class with `final` fields.
    - `fromJson` / `toJson`.
    - `copyWith`.
    - UTC DateTime handling.

    **B. Service** (`services/[name]_service.dart`):
    - `SupabaseClient` private instance.
    - Methods: `fetch`, `create`, `update`, `delete`.
    - Error mapping (`_mapError`).
    - **CRITICAL**: Use `.select('*, related(*)')` for fetching.

    **C. ViewModel** (`viewmodels/[name]_view_model.dart`):
    - Extends `ChangeNotifier`.
    - Depend on `[Name]Service`.
    - State: `isLoading`, `error`, `dataList`.
    - Methods: `loadData()`, `addData()`.

    **D. View** (`view/[name]_screen.dart`):
    - `StatelessWidget` (usually).
    - `Consumer<[Name]ViewModel>`.
    - `Scaffold` with SLine Appbar.
    - Handling loading/error states.

3.  **Registration**:
    - Output the snippet to add to `MultiProvider` in `lib/main.dart`.

## Standards
- Use `AppLogger` for logging.
- Use `AppTheme` for UI.
- No `print()` statements.
