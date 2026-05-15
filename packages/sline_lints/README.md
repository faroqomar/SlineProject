# SLine Lints

Project-specific `custom_lint` plugin for the SLine Flutter app.

This package turns SLine architecture, design-token, and safety conventions into
analyzer diagnostics that appear in `dart run custom_lint`, CI, pre-commit, and
supported IDE Problems panels. Generic Dart lint packages cannot know SLine's
MVVM boundaries or theme system, so those rules live here.

## How The App Uses It

The root app enables this plugin in two places:

- `pubspec.yaml` includes `sline_lints` as a local dev dependency.
- `analysis_options.yaml` enables the `custom_lint` analyzer plugin.

Run the full rule set from the app root:

```sh
dart run custom_lint
```

The root `.githooks/pre-commit` hook and GitHub Actions CI also run this command.

## Rule Groups

SLine keeps rules in two rollout states:

- **Enforced now**: registered in `lib/sline_lints.dart`; CI, pre-commit, and
  IDE custom-lint diagnostics must stay clean.
- **Implemented but staged**: rule classes exist in
  `lib/src/rules/forbidden_architecture_rule.dart` for the next cleanup waves,
  but are not registered until existing legacy debt is migrated. Do not register
  one of these rules without first fixing the diagnostics it surfaces.

### MVVM Boundary Rules

Enforced now:

- `sline_no_supabase_in_feature_views` blocks direct Supabase access in
  `lib/features/*/view/**`.
- `sline_no_raw_network_imports_in_feature_views` blocks raw HTTP/socket imports
  in feature views.
- `sline_no_repository_imports_in_feature_views` blocks repository imports from
  feature views.
- `sline_no_view_imports_in_viewmodels` blocks ViewModel imports from view-layer
  files.
- `sline_no_view_imports_in_services_data` blocks feature services/data from
  importing views. Feature deep-link handlers are intentionally excluded because
  they are route adapters.
- `sline_no_viewmodel_imports_in_services_data` blocks services/data from
  depending back on ViewModels.
- `sline_no_feature_ui_imports_in_core` blocks core from importing feature views
  or ViewModels.
- `sline_no_ui_framework_imports_in_viewmodels` blocks Provider/Material/UI
  framework imports from ViewModels.
- `sline_no_navigator_in_viewmodels` blocks navigation orchestration inside
  ViewModels.
- `sline_no_ui_controllers_in_viewmodels` blocks `TextEditingController` and
  `GlobalKey<FormState>` ownership in ViewModels.
- `sline_no_supabase_in_viewmodel_methods` blocks Supabase access from
  ViewModel method/getter bodies. Constructor dependency-injection defaults are
  intentionally tolerated while the app keeps test-friendly injected clients.
- `sline_no_build_context_outside_views` blocks `BuildContext` in ViewModels and
  data/repository layers.
- `sline_no_notify_listeners_in_loops` blocks repeated ViewModel notifications
  inside loops.
- `sline_require_changenotifier_for_viewmodels` requires conventional
  `*_view_model.dart` files to expose a `ChangeNotifier`.
- `sline_no_supabase_in_viewmodels` mirrors the existing CI guard by reporting
  direct `Supabase` access inside ViewModel executable bodies.

Implemented but staged:

- `sline_no_services_in_feature_views`
- `sline_no_core_services_in_feature_views_except_allowed`
- `sline_no_feature_to_feature_view_imports`
- `sline_no_public_mutable_viewmodel_state`
- `sline_no_future_without_mounted_check_in_state`

### Theme And Design-Token Rules

Enforced now:

- `sline_no_hardcoded_feature_view_tokens` blocks hardcoded feature-view UI
  values that should come from the design system:
  - `Color(0x...)`
  - `Colors.*`
  - motion-like `Duration(milliseconds: ...)` or `Duration(microseconds: ...)`
  - `Curves.*`
  - `BoxShadow(...)`
  - `TextStyle(fontSize: ...)`
  - `EdgeInsets(...)`
  - `BorderRadius(...)` / `Radius(...)`
  - numeric `SizedBox(width/height: ...)`
  - numeric `Icon(size: ...)`

Use `AppColors`, `context.colorScheme`, `AppMotion`, `AppTypography`,
`AppDimens`, `AppLayout`, and `AppDecorations` instead.

Implemented but staged:

- Direct `TextStyle(...)` constructor bans beyond `fontSize`.
- Raw `BoxDecoration`, `InputDecoration`, and `ShapeDecoration` constructor
  bans.
- Raw `BorderSide.width` and `Divider.thickness` bans.
- Raw opacity, MediaQuery arithmetic, `AnimationController(duration: ...)`, and
  shared-widget raw-padding bans.

### Error And Logging Rules

Enforced now:

- `sline_no_raw_exception_string_for_ui_errors` blocks assigning raw
  `e.toString()` / `error.toString()` output to ViewModel UI error fields.
  Map exceptions through `ErrorMapper` or a feature-specific friendly mapper.
- `sline_no_print_in_lib` blocks `print()` / `debugPrint()` in `lib/`.
  Use `AppLogger`.

Implemented but staged:

- `sline_require_app_logger_tag`
- `sline_no_empty_catch`
- `sline_no_swallowed_catch`
- `sline_no_stringly_typed_status`
- `sline_no_magic_database_columns_in_views`
- `sline_no_rls_bypass_language_in_client`

### Supabase/Data Safety Rules

Enforced now:

- `sline_no_offset_pagination` blocks `.range(...)` and offset-style pagination
  in `lib/`.
- `sline_no_dynamic_maps_in_models` requires feature model `fromJson` methods
  to use typed maps.
- `sline_no_signed_url_persistence` blocks high-confidence attempts to insert,
  update, or upsert signed URL fields as source-of-truth data.

Implemented but staged:

- `sline_no_supabase_select_star`
- `sline_require_limit_on_collection_queries`
- `sline_require_order_with_limit`

### Testing Rules

Implemented but staged until the legacy test suite is renamed and wrapped in
the shared harness:

- `sline_require_viewmodel_test_for_new_viewmodel`
- `sline_require_widget_test_for_new_screen`
- `sline_no_pumpwidget_without_theme`
- `sline_no_duplicate_test_names`

## Adding A Rule

1. Add the rule class under `lib/src/rules/`.
2. Register it in `lib/sline_lints.dart`.
3. Run `dart analyze` inside `packages/sline_lints`.
4. Run `dart run custom_lint` from the app root.
5. Fix surfaced app diagnostics instead of suppressing them.
6. Update this README and central docs when the rule changes project behavior.

## Design Notes

- Prefer precise rules over broad noisy rules. A rule should point to a concrete
  fix most of the time.
- Keep intentional migration windows explicit. If legacy constructor dependency
  defaults are allowed, document that in the rule description.
- Do not add blanket exceptions silently. If a path must be allowed, document why
  in the rule code and in this README.
