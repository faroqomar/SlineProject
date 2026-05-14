/// Provides Amber Dusk motion aliases backed by existing SLine motion tokens.
///
/// Phase 0 does not add screen choreography; it names the motion roles future
/// Amber Dusk screens can use while preserving the existing `AppMotion` source.
library;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:sline_app/core/theme/app_motion.dart';

/// Namespace for Amber Dusk motion roles.
///
/// The namespace maps Amber Dusk interaction intent to the established SLine
/// motion scale instead of introducing a separate animation system.
abstract final class AmberDuskMotion {
  /// Token registry exposed by `AmberDuskTokens` for instance-style access.
  static const AmberDuskMotionTokens tokens = AmberDuskMotionTokens();

  /// Fast for quick feedback on chips and active nav capsules.
  static const Duration activeState = AppMotion.fast;

  /// Standard timing keeps card and sheet motion calm during layout changes.
  static const Duration surfaceTransition = AppMotion.standard;

  /// Emphasis timing gives hero cards and wallet values enough visual weight.
  static const Duration heroTransition = AppMotion.emphasis;

  /// Deceleration makes entering content settle without feeling abrupt.
  static const Curve enterCurve = AppMotion.curveDecel;

  /// Standard curve keeps compact state changes predictable and unobtrusive.
  static const Curve stateCurve = AppMotion.curveStandard;

  /// Shared press scale keeps button feedback aligned with the active app theme.
  static const double pressScale = AppMotion.pressScale;
}

/// Instance-facing motion registry used by `AmberDuskTokens.motion`.
///
/// The registry makes motion roles available from the staged token entry point
/// without requiring direct `AppMotion` imports in future feature screens.
@immutable
final class AmberDuskMotionTokens {
  /// Creates an immutable motion token registry.
  const AmberDuskMotionTokens();

  /// Fast state change duration for chips and active nav capsules.
  Duration get activeState => AmberDuskMotion.activeState;

  /// Standard card and sheet transition duration.
  Duration get surfaceTransition => AmberDuskMotion.surfaceTransition;

  /// Emphasis duration for hero-card or wallet value entrances.
  Duration get heroTransition => AmberDuskMotion.heroTransition;

  /// Default curve for entering elements.
  Curve get enterCurve => AmberDuskMotion.enterCurve;

  /// Default curve for compact state changes.
  Curve get stateCurve => AmberDuskMotion.stateCurve;

  /// Default press feedback scale.
  double get pressScale => AmberDuskMotion.pressScale;
}
