/// Provides solid Amber Dusk surface recipes for future screen phases.
///
/// These recipes preserve the Open Design material intent with opaque fills,
/// gradients, borders, and shadows while respecting SLine's no-glass policy.
library;

import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_colors.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_spacing.dart';

/// Stable names for Amber Dusk surface recipes.
///
/// Component recipes refer to these names instead of raw strings so typos are
/// caught at compile time when future phases map recipes to renderers.
abstract final class AmberDuskSurfaceNames {
  const AmberDuskSurfaceNames._();

  /// Quiet base card surface name.
  static const String base = 'base';

  /// Raised card surface name.
  static const String raised = 'raised';

  /// Hero booking surface name.
  static const String hero = 'hero';

  /// Bottom navigation surface name.
  static const String nav = 'nav';

  /// Bottom sheet surface name.
  static const String sheet = 'sheet';

  /// High-emphasis CTA surface name.
  static const String cta = 'cta';
}

/// Namespace for Amber Dusk solid surface recipes.
///
/// The namespace exists so later widgets can select named surface roles instead
/// of copying CSS export values into feature screens.
abstract final class AmberDuskSurfaces {
  const AmberDuskSurfaces._();

  /// Token registry exposed by `AmberDuskTokens` for instance-style access.
  static const AmberDuskSurfaceTokens tokens = AmberDuskSurfaceTokens();

  /// Quiet base card surface used for dense list and form modules.
  static const AmberDuskSurfaceRecipe base = AmberDuskSurfaceRecipe(
    name: AmberDuskSurfaceNames.base,
    fill: AmberDuskColors.surface,
    border: AmberDuskColors.transparent,
    radius: AmberDuskSpacing.moduleRadius,
    elevationLevel: 1,
    shadowTokenName: 'shadow-surface',
  );

  /// Raised work-card surface used for task and booking summaries.
  static const AmberDuskSurfaceRecipe raised = AmberDuskSurfaceRecipe(
    name: AmberDuskSurfaceNames.raised,
    fill: AmberDuskColors.surface,
    border: AmberDuskColors.transparent,
    radius: AmberDuskSpacing.taskCardRadius,
    elevationLevel: 2,
    shadowTokenName: 'shadow-raised',
  );

  /// Hero booking material using the authored rust gradient.
  static const AmberDuskSurfaceRecipe hero = AmberDuskSurfaceRecipe(
    name: AmberDuskSurfaceNames.hero,
    fill: AmberDuskColors.hero,
    border: AmberDuskColors.transparent,
    radius: AmberDuskSpacing.heroCardRadius,
    elevationLevel: 3,
    shadowTokenName: 'shadow-hero',
    gradientAngleDegrees: 172,
    highlightColor: AmberDuskColors.heroHighlight,
    rimColor: AmberDuskColors.heroRim,
    gradientStops: <Color>[
      AmberDuskColors.heroTop,
      AmberDuskColors.hero,
      AmberDuskColors.heroDeep,
    ],
  );

  /// Bottom navigation material using a solid high-opacity dark surface.
  static const AmberDuskSurfaceRecipe nav = AmberDuskSurfaceRecipe(
    name: AmberDuskSurfaceNames.nav,
    fill: AmberDuskColors.surface,
    border: AmberDuskColors.transparent,
    radius: AmberDuskSpacing.navRadius,
    elevationLevel: 3,
    shadowTokenName: 'shadow-nav',
  );

  /// Bottom sheet material using a solid raised panel.
  static const AmberDuskSurfaceRecipe sheet = AmberDuskSurfaceRecipe(
    name: AmberDuskSurfaceNames.sheet,
    fill: AmberDuskColors.background,
    border: AmberDuskColors.transparent,
    radius: AmberDuskSpacing.sheetRadius,
    elevationLevel: 3,
    shadowTokenName: 'shadow-raised',
  );

  /// Cream CTA material for high-emphasis actions on dark hero cards.
  static const AmberDuskSurfaceRecipe cta = AmberDuskSurfaceRecipe(
    name: AmberDuskSurfaceNames.cta,
    fill: AmberDuskColors.text,
    border: AmberDuskColors.transparent,
    radius: AmberDuskSpacing.pillRadius,
    elevationLevel: 2,
    shadowTokenName: 'shadow-cta',
  );

  /// Public surface names used by guardrail tests and handoff docs.
  static const List<String> recipeNames = <String>[
    'base',
    'raised',
    'hero',
    'nav',
    'sheet',
    'cta',
  ];
}

/// Instance-facing registry used by `AmberDuskTokens.surfaces`.
///
/// The registry exposes concrete recipes from the public token entry point
/// without requiring feature screens to import implementation files directly.
@immutable
final class AmberDuskSurfaceTokens {
  /// Creates an immutable surface token registry.
  const AmberDuskSurfaceTokens();

  /// Quiet base card recipe.
  AmberDuskSurfaceRecipe get base => AmberDuskSurfaces.base;

  /// Raised work-card recipe.
  AmberDuskSurfaceRecipe get raised => AmberDuskSurfaces.raised;

  /// Hero booking-card recipe.
  AmberDuskSurfaceRecipe get hero => AmberDuskSurfaces.hero;

  /// Bottom navigation recipe.
  AmberDuskSurfaceRecipe get nav => AmberDuskSurfaces.nav;

  /// Bottom sheet recipe.
  AmberDuskSurfaceRecipe get sheet => AmberDuskSurfaces.sheet;

  /// High-emphasis CTA recipe.
  AmberDuskSurfaceRecipe get cta => AmberDuskSurfaces.cta;

  /// Public recipe names for guardrails and documentation.
  List<String> get recipeNames => AmberDuskSurfaces.recipeNames;
}

/// Describes one reusable Amber Dusk solid surface material.
///
/// Feature screens can translate this into Flutter decorations in later phases
/// while Phase 0 keeps the token foundation passive and unactivated.
@immutable
final class AmberDuskSurfaceRecipe {
  /// Creates a named surface recipe from solid token values.
  const AmberDuskSurfaceRecipe({
    required this.name,
    required this.fill,
    required this.border,
    required this.radius,
    required this.elevationLevel,
    required this.shadowTokenName,
    this.gradientAngleDegrees,
    this.highlightColor = AmberDuskColors.transparent,
    this.rimColor = AmberDuskColors.transparent,
    this.gradientStops = const <Color>[],
  });

  /// Stable recipe name for documentation and tests.
  final String name;

  /// Opaque single-color fallback for the surface.
  ///
  /// Renderers should use `fill` when `gradientStops` is empty. When
  /// `gradientStops` contains colors, renderers should prefer that gradient and
  /// respect `gradientAngleDegrees`; `fill` remains the seed/default color for
  /// implementations that need a base material color while building gradients.
  final Color fill;

  /// Border color for the surface; transparent means borderless by design.
  final Color border;

  /// Radius in logical pixels.
  final double radius;

  /// Existing `AppDecorations.elevation` level to use when rendered.
  final int elevationLevel;

  /// Open Design shadow token name that this recipe represents.
  final String shadowTokenName;

  /// Gradient angle in degrees for recipes with authored gradient direction.
  final double? gradientAngleDegrees;

  /// Top material sheen color used without blur.
  final Color highlightColor;

  /// Subtle rim color used to preserve bevel intent without generic borders.
  final Color rimColor;

  /// Optional gradient stops used only by hero materials.
  final List<Color> gradientStops;

  /// Whether this recipe uses a gradient rather than a flat fill.
  bool get hasGradient => gradientStops.isNotEmpty;

  /// Whether this recipe includes an authored non-blur material highlight.
  bool get hasHighlight => highlightColor != AmberDuskColors.transparent;

  /// Whether this recipe includes a subtle material rim.
  bool get hasRim => rimColor != AmberDuskColors.transparent;
}
