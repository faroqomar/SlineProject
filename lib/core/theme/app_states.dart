import 'package:flutter/services.dart';

import 'package:sline_app/core/theme/app_motion.dart';

/// Interaction state definitions for all interactive elements in SLine.
///
/// Every button, text field, card, toggle, and tappable element supports
/// up to 8 states. This class provides the constant values that drive
/// the visual treatment of each state.
///
/// ## The 8-State Model
///
/// 1. **DEFAULT** — Base appearance. No overlay. Scale 1.0.
/// 2. **HOVER** — (desktop/web only) Subtle overlay + slight scale-up.
/// 3. **FOCUS** — (keyboard/switch access) Visible outline ring. No fill change.
/// 4. **ACTIVE/PRESSED** — Scale-down + overlay + haptic feedback.
/// 5. **DISABLED** — Reduced opacity, no pointer events.
/// 6. **LOADING** — Replace content with spinner, keep size stable.
/// 7. **SUCCESS** — Brief green flash + check icon + haptic.
/// 8. **ERROR** — Brief red flash + shake animation + haptic.
///
/// ## Usage
///
/// Widget implementations reference these constants for consistent behavior:
/// ```dart
/// // In a button widget:
/// Opacity(
///   opacity: isDisabled ? AppInteractionStates.disabledOpacity : 1.0,
///   child: ...
/// )
/// ```
///
/// See also: [AppMotion] for animation durations and curves.
class AppInteractionStates {
  AppInteractionStates._();

  // ── Opacity Values ─────────────────────────────────────────

  /// Disabled elements: 38% opacity (Material standard).
  static const double disabledOpacity = 0.38;

  /// Hover overlay on interactive elements (desktop/web).
  static const double hoverOverlayOpacity = 0.04;

  /// Pressed/active overlay on interactive elements.
  static const double pressedOverlayOpacity = 0.08;

  /// Success/error flash overlay intensity.
  static const double flashOverlayOpacity = 0.15;

  // ── Focus Ring ─────────────────────────────────────────────

  /// Width of the focus indicator outline.
  /// Must be visible on ALL backgrounds (light + dark mode).
  static const double focusRingWidth = 2.0;

  /// Offset of the focus ring outside the element boundary.
  static const double focusRingOffset = 2.0;

  // ── Loading Indicator ──────────────────────────────────────

  /// Size of the loading spinner that replaces button content.
  /// Small enough to fit inside buttons without layout shift.
  static const double loadingSize = 18.0;

  /// Stroke width of the loading spinner.
  static const double loadingStrokeWidth = 2.0;

  // ── Error Shake Animation ──────────────────────────────────

  /// Horizontal displacement per shake cycle (pixels).
  static const double shakeAmplitude = 4.0;

  /// Number of back-and-forth shake cycles.
  static const int shakeCycles = 3;

  /// Total duration of the shake animation.
  static const Duration shakeDuration = AppMotion.standard;

  // ── Success/Error Flash ────────────────────────────────────

  /// Duration of the success/error color flash.
  static const Duration flashDuration = AppMotion.standard;

  /// Delay before auto-reverting from success/error state to default.
  static const Duration revertDelay = Duration(milliseconds: 1500);

  // ── Haptic Feedback Mapping ────────────────────────────────
  //
  // These are not constants but documented patterns for widgets to follow:
  //
  // | Action Type       | Haptic Call                         |
  // |-------------------|-------------------------------------|
  // | Button tap        | HapticFeedback.lightImpact()        |
  // | Toggle/switch     | HapticFeedback.selectionClick()     |
  // | Tab change        | HapticFeedback.selectionClick()     |
  // | Successful action | HapticFeedback.mediumImpact()       |
  // | Destructive action| HapticFeedback.heavyImpact()        |
  // | Error/failure     | HapticFeedback.heavyImpact()        |
  // | Nav bar tap       | HapticFeedback.selectionClick()     |
  // | Bookmark toggle   | HapticFeedback.lightImpact()        |

  /// Convenience method: fire the appropriate haptic for a button tap.
  static void hapticTap() => HapticFeedback.lightImpact();

  /// Convenience method: fire the appropriate haptic for a toggle/selection.
  static void hapticSelection() => HapticFeedback.selectionClick();

  /// Convenience method: fire the appropriate haptic for a successful action.
  static void hapticSuccess() => HapticFeedback.mediumImpact();

  /// Convenience method: fire the appropriate haptic for a destructive/error action.
  static void hapticHeavy() => HapticFeedback.heavyImpact();
}
