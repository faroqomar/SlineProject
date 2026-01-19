---
description: Type-safe asset management to replace raw strings.
---

# Asset Manager Skill

**Goal**: Eliminate "asset not found" runtime errors.

## Capabilities

1.  **Scan Assets**:
    -   Recursively walk `assets/images/`, `assets/icons/`, etc.

2.  **Generate Constants**:
    -   File: `lib/core/constants/app_assets.dart`.
    -   Class: `class AppAssets { ... }`.
    -   Format: `static const String logo = 'assets/images/logo.png';`.

3.  **Update Pubspec**:
    -   Ensure all subdirectories in `assets/` are declared in `pubspec.yaml` if not using directory-level inclusion (which Flutter supports now but explicit is safer).

## Usage
**WRONG**: `Image.asset('assets/images/logo.png')`
**RIGHT**: `Image.asset(AppAssets.logo)`
