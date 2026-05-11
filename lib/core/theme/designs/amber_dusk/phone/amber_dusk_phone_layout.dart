/// Provides Amber Dusk phone artboard and navigation layout tokens.
///
/// The file isolates phone-specific measurements so reusable spacing and theme
/// tokens are not polluted by fixed 402px artboard dimensions.
library;

import 'package:flutter/foundation.dart';

import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_spacing.dart';

/// Namespace for Amber Dusk phone shell layout constants.
///
/// These constants stage the Open Design 402x874 phone foundation without
/// activating a global Flutter theme or creating screen implementations.
abstract final class AmberDuskPhoneLayout {
  const AmberDuskPhoneLayout._();

  /// Token registry exposed by `AmberDuskTokens` for instance-style access.
  static const AmberDuskPhoneLayoutTokens tokens = AmberDuskPhoneLayoutTokens();

  /// Phone frame width from Open Design evidence.
  static const double frameWidth = 402;

  /// Phone frame height from Open Design evidence.
  static const double frameHeight = 874;

  /// Phone frame radius from Open Design evidence.
  static const double frameRadius = AmberDuskSpacing.frameRadius;

  /// Horizontal content padding inside the phone artboard.
  static const double contentHorizontalPadding =
      AmberDuskSpacing.contentHorizontalPadding;

  /// Top content padding that accounts for the phone status area.
  static const double contentTopPadding = 64;

  /// Bottom content padding from the source phone artboard.
  static const double contentBottomPadding = 120;

  /// Bottom padding reserved so scroll content clears the nav and FAB.
  static const double bottomScrollPadding = 138;

  /// Safe bottom padding reserved above the home indicator.
  static const double safeBottomPadding = 22;

  /// Horizontal inset for the bottom navigation shell.
  static const double bottomNavInset = 16;

  /// Distance from the frame bottom to the bottom navigation shell.
  static const double bottomNavBottom = 24;

  /// Bottom navigation shell height.
  static const double bottomNavHeight = 68;

  /// Bottom navigation shell radius.
  static const double bottomNavRadius = AmberDuskSpacing.navRadius;

  /// Floating action button visual size.
  static const double fabSize = 56;

  /// Floating action button radius.
  static const double fabRadius = AmberDuskSpacing.fabRadius;

  /// Dynamic island width observed in the source artboard.
  static const double dynamicIslandWidth = 126;

  /// Dynamic island height observed in the source artboard.
  static const double dynamicIslandHeight = 37;
}

/// Instance-facing phone layout registry used by `AmberDuskTokens.phoneLayout`.
///
/// The registry exists so future screens can depend on one public entry point
/// while keeping fixed artboard measurements separate from global spacing.
@immutable
final class AmberDuskPhoneLayoutTokens {
  /// Creates an immutable phone layout token set for Amber Dusk.
  const AmberDuskPhoneLayoutTokens({
    this.frameWidth = AmberDuskPhoneLayout.frameWidth,
    this.frameHeight = AmberDuskPhoneLayout.frameHeight,
    this.frameRadius = AmberDuskPhoneLayout.frameRadius,
    this.contentHorizontalPadding =
        AmberDuskPhoneLayout.contentHorizontalPadding,
    this.contentTopPadding = AmberDuskPhoneLayout.contentTopPadding,
    this.contentBottomPadding = AmberDuskPhoneLayout.contentBottomPadding,
    this.bottomScrollPadding = AmberDuskPhoneLayout.bottomScrollPadding,
    this.safeBottomPadding = AmberDuskPhoneLayout.safeBottomPadding,
    this.bottomNavInset = AmberDuskPhoneLayout.bottomNavInset,
    this.bottomNavBottom = AmberDuskPhoneLayout.bottomNavBottom,
    this.bottomNavHeight = AmberDuskPhoneLayout.bottomNavHeight,
    this.bottomNavRadius = AmberDuskPhoneLayout.bottomNavRadius,
    this.fabSize = AmberDuskPhoneLayout.fabSize,
    this.fabRadius = AmberDuskPhoneLayout.fabRadius,
    this.dynamicIslandWidth = AmberDuskPhoneLayout.dynamicIslandWidth,
    this.dynamicIslandHeight = AmberDuskPhoneLayout.dynamicIslandHeight,
  });

  /// Phone frame width from Open Design evidence.
  final double frameWidth;

  /// Phone frame height from Open Design evidence.
  final double frameHeight;

  /// Phone frame radius from Open Design evidence.
  final double frameRadius;

  /// Horizontal content padding inside the phone artboard.
  final double contentHorizontalPadding;

  /// Short alias for tests and consumers that do not need the content prefix.
  double get horizontalPadding => contentHorizontalPadding;

  /// Top content padding that accounts for the phone status area.
  final double contentTopPadding;

  /// Short alias for tests and consumers that do not need the content prefix.
  double get topPadding => contentTopPadding;

  /// Bottom content padding from the source phone artboard.
  final double contentBottomPadding;

  /// Bottom padding reserved so scroll content clears the nav and FAB.
  final double bottomScrollPadding;

  /// Safe bottom padding reserved above the home indicator.
  final double safeBottomPadding;

  /// Horizontal inset for the bottom navigation shell.
  final double bottomNavInset;

  /// Distance from the frame bottom to the bottom navigation shell.
  final double bottomNavBottom;

  /// Bottom navigation shell height.
  final double bottomNavHeight;

  /// Bottom navigation shell radius.
  final double bottomNavRadius;

  /// Floating action button visual size.
  final double fabSize;

  /// Floating action button radius.
  final double fabRadius;

  /// Dynamic island width observed in the source artboard.
  final double dynamicIslandWidth;

  /// Dynamic island height observed in the source artboard.
  final double dynamicIslandHeight;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AmberDuskPhoneLayoutTokens &&
            other.frameWidth == frameWidth &&
            other.frameHeight == frameHeight &&
            other.frameRadius == frameRadius &&
            other.contentHorizontalPadding == contentHorizontalPadding &&
            other.contentTopPadding == contentTopPadding &&
            other.contentBottomPadding == contentBottomPadding &&
            other.bottomScrollPadding == bottomScrollPadding &&
            other.safeBottomPadding == safeBottomPadding &&
            other.bottomNavInset == bottomNavInset &&
            other.bottomNavBottom == bottomNavBottom &&
            other.bottomNavHeight == bottomNavHeight &&
            other.bottomNavRadius == bottomNavRadius &&
            other.fabSize == fabSize &&
            other.fabRadius == fabRadius &&
            other.dynamicIslandWidth == dynamicIslandWidth &&
            other.dynamicIslandHeight == dynamicIslandHeight;
  }

  @override
  int get hashCode {
    return Object.hash(
      frameWidth,
      frameHeight,
      frameRadius,
      contentHorizontalPadding,
      contentTopPadding,
      contentBottomPadding,
      bottomScrollPadding,
      safeBottomPadding,
      bottomNavInset,
      bottomNavBottom,
      bottomNavHeight,
      bottomNavRadius,
      fabSize,
      fabRadius,
      dynamicIslandWidth,
      dynamicIslandHeight,
    );
  }
}
