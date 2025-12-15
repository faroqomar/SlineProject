---
description: How to run tests and ensure code stability
---

# Testing Workflow

## 1. Pre-Check
- [ ] Run `flutter analyze`. Fix all warnings.
- [ ] Run `flutter format .`.

## 2. Unit Tests
Run tests for ViewModels, Models, and Utils.

```bash
flutter test test/features/
flutter test test/core/
```

## 3. Widget Tests
Run UI tests.

```bash
flutter test test/widget_test.dart
```

## 4. Coverage Report (Optional)
Generate coverage to see untested areas.

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 5. Agent Verification
- [ ] Ask `@Sentinel` to review specific complex logic if tests fail.
