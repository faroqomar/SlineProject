/// Tests for the Amber Dusk shared-widget adapter.
///
/// These tests lock the Phase 1 adapter contract and prove AppTheme TabBar
/// colors use the Amber Dusk adapter without changing the whole AppColorScheme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

void main() {
  group('AmberDuskWidgetTheme - Export', () {
    test('is available from the Amber Dusk root token entry point', () {
      const widgetTheme = AmberDuskTokens.widgetTheme;

      expect(widgetTheme, isA<AmberDuskWidgetThemeTokens>());
      expect(widgetTheme.buttons.primary.background, AmberDuskColors.primary);
      expect(widgetTheme.tabs.activeLabelColor, AmberDuskColors.primary);
    });
  });

  group('AmberDuskWidgetTheme - Buttons And Fields', () {
    test('pins shared button recipes from Open Design evidence', () {
      final buttons = AmberDuskTokens.widgetTheme.buttons;

      expect(buttons.primary.background, AmberDuskColors.primary);
      expect(buttons.primary.foreground, AmberDuskColors.text);
      expect(buttons.ghost.background, AmberDuskWidgetTheme.quietActionSurface);
      expect(buttons.ghost.foreground, AmberDuskColors.text);
      expect(
        buttons.danger.background,
        AmberDuskWidgetTheme.quietActionSurface,
      );
      expect(buttons.danger.foreground, AmberDuskColors.text);
      expect(buttons.radius, closeTo(15, 0.001));
      expect(buttons.minHeight, closeTo(46, 0.001));
      expect(buttons.horizontalPadding, closeTo(18, 0.001));
      expect(buttons.padding.horizontal, closeTo(36, 0.001));
      expect(buttons.borderWidth, closeTo(0, 0.001));
      expect(buttons.textStyle.fontSize, closeTo(13, 0.001));
      expect(buttons.textStyle.fontWeight, FontWeight.w800);
      expect(buttons.successFlash, AmberDuskColors.forest);
      expect(buttons.errorFlash, AmberDuskColors.rust);
      expect(buttons.hoverOverlay, AmberDuskWidgetTheme.buttonHoverOverlay);
      expect(buttons.focusOverlay, AmberDuskWidgetTheme.buttonFocusOverlay);
    });

    test('pins shared field tokens from Open Design evidence', () {
      final fields = AmberDuskTokens.widgetTheme.fields;

      expect(fields.labelUppercase, isTrue);
      expect(fields.background, AmberDuskWidgetTheme.fieldSurface);
      expect(fields.radius, closeTo(16, 0.001));
      expect(fields.padding.horizontal, closeTo(26, 0.001));
      expect(fields.padding.vertical, closeTo(24, 0.001));
      expect(fields.borderWidth, closeTo(0, 0.001));
      expect(fields.labelStyle.fontSize, closeTo(11.5, 0.001));
      expect(fields.labelStyle.fontWeight, FontWeight.w800);
      expect(fields.textStyle.fontSize, closeTo(14, 0.001));
    });
  });

  group('AmberDuskWidgetTheme - Pills, Nav, Cards, Media, Skeleton', () {
    test('pins icon-button recipe from Open Design evidence', () {
      final iconButtons = AmberDuskTokens.widgetTheme.iconButtons;

      expect(iconButtons.size, closeTo(42, 0.001));
      expect(iconButtons.iconSize, closeTo(20, 0.001));
      expect(iconButtons.background, AmberDuskColors.surface);
      expect(iconButtons.foreground, AmberDuskColors.text);
      expect(iconButtons.border, Colors.transparent);
      expect(iconButtons.borderWidth, closeTo(0, 0.001));
    });

    test('pins status pill recipes from Open Design evidence', () {
      final statusPills = AmberDuskTokens.widgetTheme.statusPills;

      expect(statusPills.labelUppercase, isTrue);
      expect(
        statusPills.primary.background,
        AmberDuskWidgetTheme.primaryStatusOverlay,
      );
      expect(statusPills.primary.foreground, AmberDuskColors.primary);
      expect(
        statusPills.urgent.background,
        AmberDuskWidgetTheme.urgentStatusOverlay,
      );
      expect(statusPills.urgent.foreground, AmberDuskColors.rust);
      expect(statusPills.radius, closeTo(999, 0.001));
      expect(statusPills.padding.horizontal, closeTo(20, 0.001));
      expect(statusPills.padding.vertical, closeTo(10, 0.001));
      expect(statusPills.textStyle.fontSize, closeTo(11, 0.001));
      expect(statusPills.textStyle.fontWeight, FontWeight.w800);
      expect(statusPills.smallPadding.horizontal, lessThan(20));
      expect(statusPills.smallPadding.vertical, lessThan(10));
      expect(statusPills.smallTextStyle.fontSize, lessThan(11));
      expect(statusPills.iconSize, closeTo(14, 0.001));
      expect(statusPills.smallIconSize, closeTo(10, 0.001));
    });

    test('pins bottom navigation geometry and colors', () {
      final bottomNav = AmberDuskTokens.widgetTheme.bottomNav;

      expect(bottomNav.destinationCount, 4);
      expect(bottomNav.surface, AmberDuskColors.surface);
      expect(
        bottomNav.activeIconBackground,
        AmberDuskWidgetTheme.navActiveOverlay,
      );
      expect(bottomNav.activeForeground, AmberDuskColors.primary);
      expect(bottomNav.inactiveForeground, AmberDuskColors.muted);
      expect(bottomNav.radius, closeTo(26, 0.001));
      expect(bottomNav.activeIconSize, const Size(38, 30));
      expect(bottomNav.activeIconRadius, closeTo(11, 0.001));
      expect(bottomNav.labelStyle.fontSize, closeTo(9.5, 0.001));
      expect(bottomNav.labelStyle.fontWeight, FontWeight.w500);
    });

    test('pins borderless card recipes and material depth levels', () {
      final cards = AmberDuskTokens.widgetTheme.cards;

      expect(cards.task.background, AmberDuskColors.surface);
      expect(cards.task.radius, closeTo(22, 0.001));
      expect(cards.task.elevationLevel, 2);
      expect(cards.panel.background, AmberDuskColors.surface);
      expect(cards.panel.radius, closeTo(18, 0.001));
      expect(cards.panel.elevationLevel, 1);
      expect(cards.message.background, AmberDuskColors.surface);
      expect(cards.message.radius, closeTo(18, 0.001));
      expect(cards.message.elevationLevel, 1);
      expect(cards.border, Colors.transparent);
      expect(cards.borderWidth, closeTo(0, 0.001));
    });

    test('pins media fallback and derived skeleton colors', () {
      final media = AmberDuskTokens.widgetTheme.media;
      final skeleton = AmberDuskTokens.widgetTheme.skeleton;

      expect(media.avatarFallback, AmberDuskWidgetTheme.avatarFallbackWarm);
      expect(
        media.profilePhotoFallback,
        AmberDuskWidgetTheme.profilePhotoFallbackCool,
      );
      expect(media.onlineDot, AmberDuskColors.forest);
      expect(media.foreground, AmberDuskColors.text);
      expect(media.initialsTextStyle(48).fontSize, closeTo(16.8, 0.001));
      expect(media.fallbackLabelStyle.color, AmberDuskColors.text);
      expect(skeleton.base, AmberDuskColors.surface);
      expect(skeleton.raised, AmberDuskColors.surfaceRaised);
      expect(skeleton.highlight, AmberDuskColors.surfaceHighest);
    });
  });

  group('AppTheme - Amber Dusk TabBar Adapter', () {
    test('uses Amber Dusk active tab colors in light ThemeData', () {
      final tabBarTheme = AppTheme.light().tabBarTheme;
      final indicator = tabBarTheme.indicator;
      if (indicator is! UnderlineTabIndicator) {
        throw TestFailure('Expected an UnderlineTabIndicator in light theme.');
      }
      final tabTheme = AmberDuskTokens.widgetTheme.tabs;

      expect(tabBarTheme.labelColor, tabTheme.activeLabelColor);
      expect(indicator.borderSide.color, tabTheme.indicatorColor);
    });

    test('uses Amber Dusk active tab colors in dark ThemeData', () {
      final tabBarTheme = AppTheme.dark().tabBarTheme;
      final indicator = tabBarTheme.indicator;
      if (indicator is! UnderlineTabIndicator) {
        throw TestFailure('Expected an UnderlineTabIndicator in dark theme.');
      }
      final tabTheme = AmberDuskTokens.widgetTheme.tabs;

      expect(tabBarTheme.labelColor, tabTheme.activeLabelColor);
      expect(indicator.borderSide.color, tabTheme.indicatorColor);
    });

    test('seeds app skeleton extension from Amber Dusk tokens', () {
      final skeletonTheme = AmberDuskTokens.widgetTheme.skeleton;
      final extension = AppTheme.light().extension<SkeletonColors>();

      expect(extension, isNotNull);
      expect(extension?.base, skeletonTheme.base);
      expect(extension?.highlight, skeletonTheme.highlight);
    });
  });
}
