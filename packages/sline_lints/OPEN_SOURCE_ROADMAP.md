# Open Source Roadmap

This package may become a standalone open-source `custom_lint` package for
Flutter architecture enforcement. The working product idea is:

> A custom lint package that enforces Flutter MVVM boundaries and keeps
> human-written and AI-generated code architecture-compliant.

## Working Names

Prefer names that are clear, professional, and not tied only to SLine:

- `mvvm_guard`
- `flutter_arch_guard`
- `architecture_guard`
- `clean_mvvm_lints`
- `ai_arch_guard`
- `flutter_boundary_lints`
- `mvvm_enforcer`

Current strongest candidates: `flutter_arch_guard` or `mvvm_guard`.

Avoid `Forced_MVVM` for pub.dev unless we intentionally want a more aggressive
brand. It communicates the idea, but it is narrower and less professional than
the package's real value.

## Core Value

Generic Dart lint packages enforce language style. This package should enforce
project architecture:

- Views do not call APIs, databases, Supabase, Firebase, or raw network clients.
- ViewModels do not import views, use `BuildContext`, navigate, or own UI
  controllers.
- Services and repositories do not import UI or ViewModels.
- Core does not depend on feature UI.
- UI uses design tokens instead of random hardcoded values.
- AI-generated code is forced to follow the same architecture contract as human
  code.

## Open Source Direction

Before publishing, split the current SLine-specific package into a generic
package with configuration:

- Configurable feature, view, ViewModel, service, repository, and core paths.
- Configurable backend packages to block in views (`supabase_flutter`,
  `firebase_*`, `dio`, `http`, etc.).
- Optional rule presets for common patterns:
  - Provider + MVVM
  - Riverpod + MVVM
  - Bloc/Cubit feature boundaries
  - Clean Architecture layers
- Optional design-token rules with configurable token package/class names.
- Clear migration mode: warn first, then enforce as errors.

## First Public Rule Set

Start with rules that are useful across most Flutter apps:

- `no_backend_in_views`
- `no_raw_network_in_views`
- `no_view_imports_in_viewmodels`
- `no_viewmodel_imports_in_services`
- `no_build_context_outside_views`
- `no_navigation_in_viewmodels`
- `no_ui_controllers_in_viewmodels`
- `no_core_imports_feature_ui`
- `no_print_debugprint`
- `no_raw_exception_to_ui`
- `no_offset_pagination`
- optional `no_hardcoded_ui_tokens`

Keep SLine-only rules as examples or a separate preset, not the default package
behavior.

## README Positioning

Use wording like:

> `flutter_arch_guard` is a `custom_lint` package for enforcing Flutter
> architecture boundaries. It helps teams keep MVVM/Clean Architecture projects
> consistent and prevents AI-generated code from bypassing established layers.

Avoid wording like "AI slop" in public docs. Internally that is the problem we
are solving, but public package language should say "architecture drift",
"AI-generated code", and "project-specific guardrails".

## Publishing Checklist

Before publishing to pub.dev:

1. Rename package away from `sline_lints`.
2. Move SLine defaults into examples or a preset.
3. Add `example/` with a tiny Flutter app and intentionally bad snippets.
4. Add rule tests for each lint.
5. Add GitHub Actions for `dart analyze`, tests, formatting, and pana.
6. Add `LICENSE` and public `CHANGELOG.md`.
7. Write README sections for installation, configuration, CI usage, and IDE
   Problems panel setup.
8. Run `dart pub publish --dry-run`.

## SLine Backport Plan

When the generic package is ready:

1. Keep SLine using the local package until the public version supports every
   currently enforced rule.
2. Replace hardcoded SLine paths with config in `analysis_options.yaml`.
3. Point SLine to the published package version.
4. Keep any truly SLine-only rules in a small local companion package if needed.
