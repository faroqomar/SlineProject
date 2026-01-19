---
description: Generates UI for List, Details, and Edit screens wired to the ViewModel.
---

# CRUD Screen Builder

**Goal**: Rapidly build interacting UI screens without thinking about boilerplate.

## 1. List Screen Pattern
- **Path**: `view/[feature]_list_screen.dart`
- **Components**:
  - `RefreshIndicator` wrapping a `ListView`.
  - `GlassContainer` items.
  - Floating Action Button for "Add" (if applicable).
  - Search/Filter bar (Glassmorphism style).
- **Logic**:
  - `initState`: `context.read<VM>().loadItems()`.
  - `Consumer`: Check `isLoading` ? `Loader()` : `ListView`.

## 2. Details Screen Pattern
- **Path**: `view/[feature]_details_screen.dart`
- **Components**:
  - `SliverAppBar` with image (if available).
  - Sections for fields using `AppTypography`.
  - Action buttons (Edit/Delete) based on ownership.

## 3. Add/Edit Form Pattern
- **Path**: `view/[feature]_form_screen.dart`
- **Components**:
  - `Form` widget with `GlobalKey`.
  - `AppTextField` widgets for inputs.
  - Validation logic (client-side first).
  - "Save" button with `isLoading` state.
- **Logic**:
  - `onSubmit`: Call `vm.createItem(data)` or `vm.updateItem(data)`.
  - On success: `Navigator.pop(context)`.
  - On error: Show `SnackBar`.

## Design Rules
- Use `AppPadding` and `AppDimens`.
- Use `context.colorScheme`.
- No direct logical operations in `onPressed`.
