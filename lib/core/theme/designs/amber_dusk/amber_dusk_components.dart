/// Provides Amber Dusk component-level recipe names for later UI phases.
///
/// This file does not build widgets. It records reusable component material,
/// radius, and typography intent so feature screens avoid one-off styling.
library;

import 'package:flutter/foundation.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_spacing.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_surfaces.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_typography.dart';

/// Namespace for Amber Dusk component recipes.
///
/// Component recipes bridge global tokens and future screen implementations
/// without introducing business logic or feature-owned design values.
abstract final class AmberDuskComponents {
  const AmberDuskComponents._();

  // Static recipes support global-style reads; tokens support DI and overrides.
  /// Token registry exposed by `AmberDuskTokens` for instance-style access.
  static const AmberDuskComponentTokens tokens = AmberDuskComponentTokens();

  /// Hero booking-card recipe used for premium package cards.
  static const AmberDuskComponentRecipe bookingCard = AmberDuskComponentRecipe(
    name: 'bookingCard',
    surfaceName: AmberDuskSurfaceNames.hero,
    radius: AmberDuskSpacing.heroCardRadius,
    typographyRole: AmberDuskTypographyRoles.bookingName,
  );

  /// Quiet task-card recipe used for compact work/tender cards.
  static const AmberDuskComponentRecipe taskCard = AmberDuskComponentRecipe(
    name: 'taskCard',
    surfaceName: AmberDuskSurfaceNames.raised,
    radius: AmberDuskSpacing.taskCardRadius,
    typographyRole: AmberDuskTypographyRoles.sectionTitle,
  );

  /// Solid bottom navigation recipe for four primary destinations.
  static const AmberDuskComponentRecipe bottomNav = AmberDuskComponentRecipe(
    name: 'bottomNav',
    surfaceName: AmberDuskSurfaceNames.nav,
    radius: AmberDuskSpacing.navRadius,
    typographyRole: AmberDuskTypographyRoles.navLabel,
  );

  /// Amber floating action button recipe for Home creation entry.
  static const AmberDuskComponentRecipe floatingActionButton =
      AmberDuskComponentRecipe(
        name: 'floatingActionButton',
        surfaceName: AmberDuskSurfaceNames.cta,
        radius: AmberDuskSpacing.fabRadius,
        typographyRole: AmberDuskTypographyRoles.control,
      );

  /// Solid bottom sheet recipe for scoped creation and edit forms.
  static const AmberDuskComponentRecipe bottomSheet = AmberDuskComponentRecipe(
    name: 'bottomSheet',
    surfaceName: AmberDuskSurfaceNames.sheet,
    radius: AmberDuskSpacing.sheetRadius,
    typographyRole: AmberDuskTypographyRoles.body,
  );

  /// Compact chip recipe for ratings, location, and status metadata.
  static const AmberDuskComponentRecipe chip = AmberDuskComponentRecipe(
    name: 'chip',
    surfaceName: AmberDuskSurfaceNames.base,
    radius: AmberDuskSpacing.pillRadius,
    typographyRole: AmberDuskTypographyRoles.chip,
  );

  /// Semantic status badge recipe for broad success/warning/info/danger tones.
  static const AmberDuskComponentRecipe statusBadge = AmberDuskComponentRecipe(
    name: 'statusBadge',
    surfaceName: AmberDuskSurfaceNames.base,
    radius: AmberDuskSpacing.pillRadius,
    typographyRole: AmberDuskTypographyRoles.chip,
  );

  /// Canonical component recipes used by guardrail tests and handoff docs.
  static const List<AmberDuskComponentRecipe> recipes =
      <AmberDuskComponentRecipe>[
        bookingCard,
        taskCard,
        bottomNav,
        floatingActionButton,
        bottomSheet,
        chip,
        statusBadge,
      ];

  /// Public component names derived from the canonical recipe collection.
  static List<String> get recipeNames => <String>[
    for (final recipe in recipes) recipe.name,
  ];
}

/// Instance-facing component registry used by `AmberDuskTokens.components`.
///
/// The registry keeps future screen code on one public token entry point while
/// maintaining a clear boundary between recipes and widget implementation.
@immutable
final class AmberDuskComponentTokens {
  /// Creates an immutable component recipe registry.
  const AmberDuskComponentTokens();

  /// Hero booking-card component recipe.
  AmberDuskComponentRecipe get bookingCard => AmberDuskComponents.bookingCard;

  /// Quiet task-card component recipe.
  AmberDuskComponentRecipe get taskCard => AmberDuskComponents.taskCard;

  /// Four-destination bottom navigation recipe.
  AmberDuskComponentRecipe get bottomNav => AmberDuskComponents.bottomNav;

  /// Home creation floating action button recipe.
  AmberDuskComponentRecipe get floatingActionButton =>
      AmberDuskComponents.floatingActionButton;

  /// Scoped bottom sheet recipe.
  AmberDuskComponentRecipe get bottomSheet => AmberDuskComponents.bottomSheet;

  /// Compact metadata chip recipe.
  AmberDuskComponentRecipe get chip => AmberDuskComponents.chip;

  /// Broad semantic status badge recipe.
  AmberDuskComponentRecipe get statusBadge => AmberDuskComponents.statusBadge;

  /// Public recipe names for guardrails and documentation.
  List<String> get recipeNames => AmberDuskComponents.recipeNames;
}

/// Describes a reusable component styling recipe without building a widget.
///
/// Later feature phases can translate these recipe names into actual widgets
/// while Phase 0 keeps the foundation testable and passive.
@immutable
final class AmberDuskComponentRecipe {
  /// Creates a named component recipe.
  const AmberDuskComponentRecipe({
    required this.name,
    required this.surfaceName,
    required this.radius,
    required this.typographyRole,
  });

  /// Stable component recipe name.
  final String name;

  /// Surface recipe this component should render on.
  final String surfaceName;

  /// Radius in logical pixels.
  final double radius;

  /// Typography role name consumed by the component.
  final String typographyRole;
}
