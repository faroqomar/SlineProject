/// Provides Amber Dusk spacing and radius tokens.
///
/// The file keeps reusable spacing primitives near the staged design layer so
/// later screens avoid one-off measurements from the Open Design export.
library;

import 'package:flutter/foundation.dart';

/// Namespace for Amber Dusk spacing and radius constants.
///
/// Values are intentionally phone-first but not screen-specific; artboard-only
/// measurements live in `phone/amber_dusk_phone_layout.dart`.
abstract final class AmberDuskSpacing {
  const AmberDuskSpacing._();

  /// Token registry exposed by `AmberDuskTokens` for instance-style access.
  static const AmberDuskSpacingTokens tokens = AmberDuskSpacingTokens();

  /// Base grid unit used to keep Amber Dusk spacing aligned to SLine rhythm.
  static const double grid = 4;

  /// Extra-tight spacing for icon and label pairs.
  static const double xxs = 2;

  /// Tight spacing for dense metadata.
  static const double xs = 4;

  /// Small spacing for chips and compact rows.
  static const double sm = 8;

  /// Medium spacing for related controls.
  static const double md = 12;

  /// Standard spacing between component groups.
  static const double lg = 16;

  /// Screen content horizontal padding from the phone artboard.
  static const double contentHorizontalPadding = 20;

  /// Large vertical gap for major phone sections.
  static const double xl = 24;

  /// Extra-large gap for spacious stacked modules.
  static const double xxl = 32;

  /// Compact control radius observed in Amber Dusk controls.
  static const double compactControlRadius = 15;

  /// Module radius for contained panels.
  static const double moduleRadius = 18;

  /// Task card radius from Open Design evidence.
  static const double taskCardRadius = 22;

  /// Hero booking card radius from Open Design evidence.
  static const double heroCardRadius = 24;

  /// Bottom navigation radius from Open Design evidence.
  static const double navRadius = 26;

  /// Sheet radius for high-emphasis overlays.
  static const double sheetRadius = 30;

  /// Phone frame radius from the 402px artboard.
  static const double frameRadius = 48;

  /// Floating action button radius from Open Design evidence.
  static const double fabRadius = 22;

  /// `pillRadius` intentionally exceeds expected control dimensions so
  /// `BorderRadius` clamps it to a full pill for chips and capsule CTAs.
  static const double pillRadius = 999;

  /// Active state glow blur from the Amber Dusk system rules.
  static const double activeGlowBlur = 8;

  /// Standard surface border width; zero preserves the OD borderless rim.
  static const double borderWidth = 0;

  /// Strong border width remains borderless because active states use glow.
  static const double borderWidthStrong = 0;
}

/// Namespace for Amber Dusk corner radius constants.
///
/// Radius aliases keep shape intent separate from spacing while preserving the
/// values authored during the phone redesign.
abstract final class AmberDuskRadius {
  const AmberDuskRadius._();

  /// Token registry exposed by `AmberDuskTokens.radius`.
  static const AmberDuskRadiusTokens tokens = AmberDuskRadiusTokens();

  /// Task card radius from Open Design evidence.
  static const double taskCard = AmberDuskSpacing.taskCardRadius;

  /// Fully rounded radius for chips and capsule controls.
  static const double pill = AmberDuskSpacing.pillRadius;
}

/// Instance-facing spacing registry used by `AmberDuskTokens.spacing`.
///
/// The registry mirrors namespace constants so consumers can enter through the
/// public token object and still get compile-time constant values.
@immutable
final class AmberDuskSpacingTokens {
  /// Creates an immutable spacing token set for Amber Dusk.
  const AmberDuskSpacingTokens({
    this.grid = AmberDuskSpacing.grid,
    this.xxs = AmberDuskSpacing.xxs,
    this.xs = AmberDuskSpacing.xs,
    this.sm = AmberDuskSpacing.sm,
    this.md = AmberDuskSpacing.md,
    this.lg = AmberDuskSpacing.lg,
    this.contentHorizontalPadding = AmberDuskSpacing.contentHorizontalPadding,
    this.xl = AmberDuskSpacing.xl,
    this.xxl = AmberDuskSpacing.xxl,
    this.compactControlRadius = AmberDuskSpacing.compactControlRadius,
    this.moduleRadius = AmberDuskSpacing.moduleRadius,
    this.taskCardRadius = AmberDuskSpacing.taskCardRadius,
    this.heroCardRadius = AmberDuskSpacing.heroCardRadius,
    this.navRadius = AmberDuskSpacing.navRadius,
    this.sheetRadius = AmberDuskSpacing.sheetRadius,
    this.frameRadius = AmberDuskSpacing.frameRadius,
    this.fabRadius = AmberDuskSpacing.fabRadius,
    this.pillRadius = AmberDuskSpacing.pillRadius,
    this.activeGlowBlur = AmberDuskSpacing.activeGlowBlur,
    this.borderWidth = AmberDuskSpacing.borderWidth,
    this.borderWidthStrong = AmberDuskSpacing.borderWidthStrong,
  });

  /// Base grid unit used for Amber Dusk spacing.
  final double grid;

  /// Extra-tight spacing for icon and label pairs.
  final double xxs;

  /// Tight spacing for dense metadata.
  final double xs;

  /// Small spacing for chips and compact rows.
  final double sm;

  /// Medium spacing for related controls.
  final double md;

  /// Standard spacing between component groups.
  final double lg;

  /// Screen content horizontal padding from the phone artboard.
  final double contentHorizontalPadding;

  /// Large vertical gap for major phone sections.
  final double xl;

  /// Extra-large gap for spacious stacked modules.
  final double xxl;

  /// Compact control radius observed in Amber Dusk controls.
  final double compactControlRadius;

  /// Module radius for contained panels.
  final double moduleRadius;

  /// Task card radius from Open Design evidence.
  final double taskCardRadius;

  /// Hero booking card radius from Open Design evidence.
  final double heroCardRadius;

  /// Bottom navigation radius from Open Design evidence.
  final double navRadius;

  /// Sheet radius for high-emphasis overlays.
  final double sheetRadius;

  /// Phone frame radius from the 402px artboard.
  final double frameRadius;

  /// Floating action button radius from Open Design evidence.
  final double fabRadius;

  /// Fully rounded pill radius used for chips and capsule CTA controls.
  final double pillRadius;

  /// Active state glow blur from the Amber Dusk system rules.
  final double activeGlowBlur;

  /// Standard surface border width.
  final double borderWidth;

  /// Strong surface border width.
  final double borderWidthStrong;
}

/// Instance-facing radius registry used by `AmberDuskTokens.radius`.
@immutable
final class AmberDuskRadiusTokens {
  /// Creates an immutable radius token set for Amber Dusk shapes.
  const AmberDuskRadiusTokens({
    this.taskCard = AmberDuskRadius.taskCard,
    this.pill = AmberDuskRadius.pill,
  });

  /// Task card radius from Open Design evidence.
  final double taskCard;

  /// Fully rounded radius for chips and capsule controls.
  final double pill;
}
