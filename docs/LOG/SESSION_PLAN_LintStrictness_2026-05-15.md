# Session Log - Lint Strictness Hardening

**Date:** 2026-05-15
**Scope:** Analyzer configuration, strict typing fallout, docs sync
**Branch:** `codex/verified-finding-fixes`

## Summary

The app now enforces the next group of code-quality gates in `analysis_options.yaml`:

- `strict-raw-types: true`
- `strict-casts: true`
- `strict-inference: true`
- `cascade_invocations: true`
- `avoid_redundant_argument_values: true`
- `avoid_annotating_with_dynamic: true`
- `prefer_for_elements_to_map_fromiterable: true`

The fixes were applied across production code and tests without adding suppressions. Most changes were mechanical cleanup from `dart fix --apply`, explicit typing at Supabase/JSON/test-double boundaries, and test expectation updates where the hardened `ErrorMapper` now intentionally hides raw technical exception text.

The follow-up pass also recorded the remaining explicitly disabled lint rules in `analysis_options.yaml` so future reviews can distinguish deliberate formatter/style/noise decisions from forgotten defaults. Deprecated lints are intentionally omitted rather than configured as `false`, because current analyzer versions warn when deprecated lint names appear in the config.

The tooling follow-up added `dependency_validator` and `custom_lint` as dev dependencies. `dependency_validator` now runs in CI and the pre-commit hook, with intentional plugin/font/tooling exceptions documented in `dart_dependency_validator.yaml`. The local `packages/sline_lints` plugin adds SLine-specific MVVM, feature-view design-token, error-sanitization, data-safety, and logging rules that generic Dart lint packages cannot express. The enforced set now covers direct Supabase/raw-network access in feature views, forbidden repository imports in feature views, view imports in ViewModels, view/ViewModel imports in services/data, feature UI imports in core, UI framework imports in ViewModels, navigation/controller ownership in ViewModels, Supabase in ViewModel executable bodies, `BuildContext` in ViewModels/data/repositories, ViewModel notification loops, raw exception strings assigned to UI error fields, `print`/`debugPrint` in `lib/`, offset pagination, dynamic model `fromJson` maps, signed URL persistence, and hardcoded feature-view color, motion, typography, spacing, radius, shadow, curve, `SizedBox`, and `Icon` literals. The package also contains staged stricter MVVM, service-import, feature-view-import, public mutable state, catch/logging, status-string, Supabase-query, theme-constructor, and test-harness rules that should only be registered after their legacy diagnostics are migrated. Mason scaffolding was removed because no active app or CI gate depends on generated bricks.

## Documentation Updates

- `Sline_everything/DEVELOPER_GUIDE.md`: updated lint-rule guidance to show the newly active strict rules and the remaining disabled-rule rationale.
- `Sline_everything/MVP_ROADMAP.md`: replaced the stale "34 rules" row with the current `very_good_analysis` plus strict-mode status.
- `Sline_everything/STRUCTURE.md`: updated the `analysis_options.yaml` description, custom lint hook description, token ranges, and last-updated marker.
- `packages/sline_lints/README.md`: documented the local custom lint plugin.

## Verification

- `flutter analyze --no-fatal-infos` -- passed with no issues.
- `flutter test` -- passed.
- `git diff --check` -- passed.
- `dart analyze` in `packages/sline_lints` -- passed.
- `dart run custom_lint` -- passed.

## Follow-Up Rule

After future lint rules are turned on and fallout is fixed, run this same docs-sync check before closing the work. At minimum, verify `DEVELOPER_GUIDE.md`, `MVP_ROADMAP.md`, `STRUCTURE.md`, and the session log need no updates.
