/// Public entry point for the staged Amber Dusk design foundation.
///
/// Later phone and web phases import this file instead of reaching into deep
/// token files, keeping Phase 0 as the single named design-system contract.
library;

import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_colors.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_components.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_motion.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_spacing.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_surfaces.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_widget_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/phone/amber_dusk_phone_layout.dart';

export 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_colors.dart';
export 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_components.dart';
export 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_motion.dart';
export 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_spacing.dart';
export 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_surfaces.dart';
export 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_typography.dart';
export 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_widget_theme.dart';
export 'package:sline_app/core/theme/designs/amber_dusk/phone/amber_dusk_phone_layout.dart';

/// Root token namespace for Amber Dusk.
///
/// This class intentionally does not activate the app theme. It exposes staged
/// tokens for later screens while the current SLine theme remains unchanged.
abstract final class AmberDuskTokens {
  const AmberDuskTokens._();

  /// Color registry with authored dark and derived light semantic mappings.
  static const AmberDuskColorTokens colors = AmberDuskColors.tokens;

  /// Typography registry for DM Sans and Fraunces role intent.
  static const AmberDuskTypographyTokens typography =
      AmberDuskTypography.tokens;

  /// Reusable spacing and radius registry.
  static const AmberDuskSpacingTokens spacing = AmberDuskSpacing.tokens;

  /// Reusable corner radius registry.
  static const AmberDuskRadiusTokens radius = AmberDuskRadius.tokens;

  /// Solid surface recipe registry.
  static const AmberDuskSurfaceTokens surfaces = AmberDuskSurfaces.tokens;

  /// Motion role registry backed by existing SLine motion tokens.
  static const AmberDuskMotionTokens motion = AmberDuskMotion.tokens;

  /// Component recipe registry for later UI phases.
  static const AmberDuskComponentTokens components = AmberDuskComponents.tokens;

  /// Shared-widget adapter for the Phase 1 phone runtime activation.
  static const AmberDuskWidgetThemeTokens widgetTheme =
      AmberDuskWidgetTheme.tokens;

  /// Phone-specific 402x874 layout registry.
  static const AmberDuskPhoneLayoutTokens phoneLayout =
      AmberDuskPhoneLayout.tokens;
}

/// Resolves the staged Amber Dusk colors from the active Flutter brightness.
///
/// Amber Dusk is still a staged design layer, so this helper centralizes the
/// dark/light selection without activating a global app theme switch.
extension AmberDuskContextTokens on BuildContext {
  /// Mode-aware Amber Dusk semantic colors for the current build context.
  AmberDuskColorScheme get amberColors =>
      Theme.of(this).brightness == Brightness.dark
      ? AmberDuskTokens.colors.dark
      : AmberDuskTokens.colors.light;
}
