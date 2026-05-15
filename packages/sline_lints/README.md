# SLine Lints

Local `custom_lint` plugin for SLine-specific architecture and UI-token rules.

The app enables this package through `analysis_options.yaml` and
`pubspec.yaml`. Run it with:

```sh
dart run custom_lint
```

Rules intentionally encode SLine conventions that generic Dart lints cannot
know, including MVVM boundaries and feature-view UI-token usage.

