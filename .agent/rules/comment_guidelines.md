---
description: Guidelines for adding meaningful comments ("Why" & "How") only when necessary.
globs: ["**/*.dart"]
alwaysApply: true
---

# Commenting Guidelines (Smart Documentation)

**Goal**: Code should be self-documenting. Comments are for *context*, *intent*, and *complexity*.

## The "Only If Needed" Rule

**DO NOT** comment on obvious code.
**DO** comment on *why* a decision was made or *how* a complex block works.

### ❌ Bad Comments (What)
Avoid stating the obvious.
```dart
// ❌ Initialize list
List<String> items = [];

// ❌ Check if empty
if (items.isEmpty) return;
```

### ✅ Good Comments (Why & How)
Explain the business rule or technical constraint.
```dart
// ✅ We iterate backwards to safely remove items without index shifting issues
for (var i = items.length - 1; i >= 0; i--) { ... }

// ✅ RLS requires an active session, so we guard here strictly
if (auth.currentUser == null) throw AuthException('Session missing');
```

## When to Comment

1.  **Workarounds**: If you are working around a bug or library limitation.
    ```dart
    // Temporary fix until issue #123 is resolved in package:xyz
    ```
2.  **Complex Logic**: Algorithms or multi-step logic that isn't instantly readable.
    ```dart
    // Calculate weighted score based on recency (50%) and popularity (50%)
    ```
3.  **Business Rules**: Why are we filtering this? 
    ```dart
    // Only 'pro' users can see archived projects (Req-104)
    ```
4.  **Public APIs**: Triple-slash `///` for public classes/methods is always good practice but generally optional for internal logic unless complex.

## Format
- Use `//` for inline explanations.
- Use `///` for documentation comments (classes, public methods).
- Keep it concise.
