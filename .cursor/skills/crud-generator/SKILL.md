---
name: crud-generator
description: Generate List, Detail, and Create/Edit Flutter screens wired to MVVM ViewModels in the SLine project. Use when bootstrapping or expanding CRUD features while preserving theme, architecture, and state-management conventions.
---

# CRUD Generator

## Generate These Screens
1. `view/<feature>_list_screen.dart`
2. `view/<feature>_details_screen.dart`
3. `view/<feature>_form_screen.dart`

## List Screen Pattern
- Use `RefreshIndicator` + list content.
- Render loading, empty, error, and data states.
- Trigger `vm.loadItems()` from initialization flow.
- Use feature-level filtering/search only through ViewModel methods.

## Details Screen Pattern
- Render read-only sections clearly.
- Show edit/delete actions only when authorized.
- Keep mutation actions in ViewModel (not inline business logic).

## Form Screen Pattern
- Use `Form` + validation before submit.
- Map form actions to `vm.createItem(...)` or `vm.updateItem(...)`.
- Handle success navigation and surfaced errors consistently.

## UI Rules
- Use project theme tokens (`AppDimens`, `context.colorScheme`, shared widgets).
- Avoid raw colors and duplicated spacing literals.
- Keep callbacks thin; delegate logic to ViewModel.

## References
- `.cursor/rules/flutter-mvvm.mdc`
- `.cursor/rules/ui-theme.mdc`
