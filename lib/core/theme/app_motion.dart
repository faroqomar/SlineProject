import 'package:flutter/material.dart';

/// Centralized motion tokens for the SLine app.
///
/// All animation durations, curves, scale amounts, and stagger delays
/// MUST reference this class. Never use raw [Duration()] or [Curves.*]
/// in feature code.
///
/// Duration rule: 100 / 200 / 300 / 500 / 800 progression.
/// Curve rule: ease-out family for entering, ease-in for exiting.
///
/// ## Banned Curves (NEVER USE)
/// - [Curves.bounceIn], [Curves.bounceOut], [Curves.bounceInOut]
/// - [Curves.elasticIn], [Curves.elasticOut], [Curves.elasticInOut]
/// - [Curves.linear] for visible animations (only for repeating loops)
///
/// See: `.cursor/skills/frontend-design/reference/motion-design.md`
class AppMotion {
  AppMotion._();

  // ── Durations ──────────────────────────────────────────────

  /// Ripples, toggles, icon swaps, badge flashes.
  static const Duration micro = Duration(milliseconds: 100);

  /// Chips, small state changes, badge entrance.
  static const Duration fast = Duration(milliseconds: 200);

  /// Cards, sheets, tab switches — the default for most interactions.
  static const Duration standard = Duration(milliseconds: 300);

  /// Entrance animations, expanding containers.
  static const Duration slow = Duration(milliseconds: 400);

  /// Page transitions, hero animations, status progress.
  static const Duration emphasis = Duration(milliseconds: 500);

  /// Count-up numbers, progress bars, balance animations.
  static const Duration dramatic = Duration(milliseconds: 800);

  // ── Repeating / Looping ─────────────────────────────────

  /// Typing indicator dot animation cycle (repeating sine pulse).
  static const Duration typingCycle = Duration(milliseconds: 600);

  /// Skeleton shimmer loaders (repeating).
  static const Duration shimmer = Duration(milliseconds: 1500);

  // ── Curves ─────────────────────────────────────────────────

  /// Default for most interactions. Smooth deceleration.
  static const Curve curveStandard = Curves.easeOutCubic;

  /// Elements entering the screen. Stronger deceleration.
  static const Curve curveDecel = Curves.easeOutQuart;

  /// Snappy UI responses — FAB entrance, badge pop-in.
  static const Curve curveSharp = Curves.easeOutExpo;

  /// Elements leaving the screen. Accelerating exit.
  static const Curve curveAccel = Curves.easeInCubic;

  /// Expand/collapse, size changes, symmetric transitions.
  static const Curve curveSymmetric = Curves.easeInOutCubic;

  /// Subtle overshoot for delight — button feedback, badge bounce.
  /// Equivalent to cubic-bezier(0.175, 0.885, 0.32, 1.075).
  ///
  /// **Design decision (Phase 0):** Reduced from legacy 1.275 (27.5% overshoot)
  /// to 1.075 (7.5% overshoot). The old value felt too bouncy for a professional
  /// marketplace — the new value gives a subtle spring that signals "alive" without
  /// being cartoonish. Consistent with .impeccable.md: "Friendly, Approachable, Smart".
  static const Curve curveSpring = Cubic(0.175, 0.885, 0.32, 1.075);

  /// Slide-up modals and sheets.
  /// Equivalent to cubic-bezier(0.2, 0.8, 0.2, 1).
  static const Curve curveSlideUp = Cubic(0.2, 0.8, 0.2, 1);

  // ── Scale Amounts ──────────────────────────────────────────

  /// Button/card press-down feedback.
  ///
  /// **Design decision (Phase 0):** Changed from legacy 0.95 to 0.96.
  /// The 4% reduction (vs old 5%) is subtler and more appropriate for a
  /// professional marketplace. Aligns with curveSpring refinement.
  static const double pressScale = 0.96;

  /// Hover state (desktop/web).
  static const double hoverScale = 1.02;

  /// Notification badge pop-in entrance.
  static const double badgeEntrance = 1.15;

  /// Brief attention draw (e.g., "needs review" pulse).
  static const double emphasize = 1.05;

  // ── Stagger Delays ────────────────────────────────────────

  /// List items in a scrolling list.
  static const Duration staggerSmall = Duration(milliseconds: 30);

  /// Cards in a grid layout.
  static const Duration staggerMedium = Duration(milliseconds: 50);

  /// Major sections on a screen.
  static const Duration staggerLarge = Duration(milliseconds: 100);

  // ── Helpers ────────────────────────────────────────────────

  /// Returns [Duration.zero] if the user prefers reduced motion.
  ///
  /// Use this to wrap any animation duration:
  /// ```dart
  /// AnimationController(
  ///   duration: AppMotion.respectMotion(context, AppMotion.standard),
  ///   vsync: this,
  /// );
  /// ```
  static Duration respectMotion(BuildContext context, Duration duration) {
    return MediaQuery.of(context).disableAnimations ? Duration.zero : duration;
  }
}
