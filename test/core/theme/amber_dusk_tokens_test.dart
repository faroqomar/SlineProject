/// Tests for the staged Amber Dusk token entry point.
///
/// These tests lock the public foundation contract so later phone and web
/// phases can consume stable token names without importing implementation files.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

void main() {
  group('AmberDuskTokens - Public Entry Point', () {
    test('exposes every Phase 0 token category from the root import', () {
      expect(AmberDuskTokens.colors, isNotNull);
      expect(AmberDuskTokens.typography, isNotNull);
      expect(AmberDuskTokens.spacing, isNotNull);
      expect(AmberDuskTokens.surfaces, isNotNull);
      expect(AmberDuskTokens.motion, isNotNull);
      expect(AmberDuskTokens.components, isNotNull);
      expect(AmberDuskTokens.phoneLayout, isNotNull);
    });
  });

  group('AmberDuskTokens - Dark Colors', () {
    test('matches the Open Design core dark palette values', () {
      final dark = AmberDuskTokens.colors.dark;

      expect(dark.isDark, isTrue);
      expect(dark.primary, equals(const Color(0xFFD4906A)));
      expect(dark.primaryDeep, equals(const Color(0xFFA36A48)));
      expect(dark.amber, equals(const Color(0xFFE6B87A)));
      expect(dark.page, equals(const Color(0xFF0E0B08)));
      expect(dark.background, equals(const Color(0xFF1A1612)));
      expect(dark.surface, equals(const Color(0xFF241F1A)));
      expect(
        dark.surfaceRaised,
        equals(const Color.fromRGBO(36, 31, 26, 0.90)),
      );
      expect(AmberDuskTokens.colors.surface2, equals(const Color(0xFF2F2822)));
      expect(dark.surfaceHighest, equals(const Color(0xFF3A312A)));
      expect(dark.text, equals(const Color(0xFFF2E8D5)));
      expect(dark.textSubtle, equals(const Color(0xFFE6D7BE)));
      expect(dark.muted, equals(const Color(0xFF8F8478)));
      expect(dark.mutedStrong, equals(const Color(0xFF7A6F63)));
      expect(dark.border, equals(Colors.transparent));
      expect(dark.divider, equals(Colors.transparent));
      expect(
        AmberDuskTokens.colors.rowSeparator,
        equals(const Color.fromRGBO(242, 232, 213, 0.058)),
      );
      expect(
        AmberDuskTokens.colors.activeWashStart,
        equals(const Color.fromRGBO(212, 144, 106, 0.105)),
      );
      expect(
        AmberDuskTokens.colors.activeWashMiddle,
        equals(const Color.fromRGBO(212, 144, 106, 0.018)),
      );
      expect(
        AmberDuskTokens.colors.bottomNavFadeTop,
        equals(const Color.fromRGBO(26, 22, 18, 0)),
      );
      expect(
        AmberDuskTokens.colors.bottomNavFadeMiddle,
        equals(const Color.fromRGBO(26, 22, 18, 0.92)),
      );
      expect(
        AmberDuskTokens.colors.atmosphericAmber,
        equals(const Color.fromRGBO(212, 144, 106, 0.13)),
      );
      expect(
        AmberDuskTokens.colors.atmosphericForest,
        equals(const Color.fromRGBO(127, 168, 114, 0.08)),
      );
    });

    test('keeps hero substates aligned with the Open Design app artifact', () {
      final dark = AmberDuskTokens.colors.dark;

      expect(dark.heroTop, equals(const Color(0xFF4A2D1F)));
      expect(dark.hero, equals(const Color(0xFF3E2418)));
      expect(dark.heroDeep, equals(const Color(0xFF2E1810)));
      expect(dark.heroText, equals(const Color(0xFFF5E8D0)));
      expect(dark.heroMuted, equals(const Color(0x8CF5E8D0)));
      expect(dark.heroChip, equals(const Color(0x0DFFFFFF)));
      expect(dark.heroChipBorder, equals(AmberDuskColors.transparent));
      expect(dark.heroDivider, equals(const Color(0x1AF5E8D0)));
      expect(dark.heroHighlight, equals(const Color(0x0AFFFFFF)));
      expect(dark.heroRim, equals(const Color(0x0FFFFFFF)));
    });

    test('keeps semantic status colors and washes pinned', () {
      final dark = AmberDuskTokens.colors.dark;

      expect(dark.success, equals(const Color(0xFF7FA872)));
      expect(dark.forest, equals(dark.success));
      expect(dark.successMuted, equals(const Color(0xFF25331F)));
      expect(dark.warning, equals(const Color(0xFFE8B856)));
      expect(dark.star, equals(dark.warning));
      expect(dark.warningMuted, equals(const Color(0xFF3B2F14)));
      expect(dark.info, equals(const Color(0xFFD4906A)));
      expect(dark.infoMuted, equals(const Color(0xFF3A281D)));
      expect(dark.danger, equals(const Color(0xFFC9695C)));
      expect(dark.rust, equals(dark.danger));
      expect(dark.dangerMuted, equals(const Color(0xFF3B1F1A)));
      expect(dark.activeGlow, equals(const Color(0x33D4906A)));
      expect(dark.overlay, equals(const Color(0x1FD4906A)));
      expect(dark.scrim, equals(const Color(0x990E0B08)));
    });
  });

  group('AmberDuskTokens - Derived Light Colors', () {
    test(
      'pins derived light parity without claiming Open Design authorship',
      () {
        final light = AmberDuskTokens.colors.light;

        expect(light.isDark, isFalse);
        expect(light.primary, equals(const Color(0xFFD4906A)));
        expect(light.page, equals(const Color(0xFFFFF8EF)));
        expect(light.background, equals(const Color(0xFFF8ECDC)));
        expect(light.surface, equals(const Color(0xFFF2E8D5)));
        expect(light.surfaceRaised, equals(const Color(0xFFFFFCF7)));
        expect(light.surfaceHighest, equals(const Color(0xFFE2CFB3)));
        expect(light.text, equals(const Color(0xFF1F1813)));
        expect(light.textSubtle, equals(const Color(0xFF4A3A2E)));
        expect(light.heroChipBorder, equals(AmberDuskColors.transparent));
        expect(light.border, equals(Colors.transparent));
        expect(light.divider, equals(Colors.transparent));
        expect(light.successMuted, equals(const Color(0xFFE4EEDC)));
        expect(light.warningMuted, equals(const Color(0xFFFFF2D4)));
        expect(light.infoMuted, equals(const Color(0xFFF5E1D1)));
        expect(light.dangerMuted, equals(const Color(0xFFF7DDD8)));
        expect(light.activeGlow, equals(const Color(0x1FA36A48)));
        expect(light.overlay, equals(const Color(0x1FA36A48)));
        expect(light.scrim, equals(const Color(0x660E0B08)));
      },
    );
  });

  group('AmberDuskTokens - Typography', () {
    test('exposes DM Sans roles for interface copy and controls', () {
      const typography = AmberDuskTokens.typography;

      expect(typography.interfaceFamily, equals('DM Sans'));
      expect(typography.controlFamily, equals('DM Sans'));
      expect(typography.labelFamily, equals('DM Sans'));
      expect(typography.chipFamily, equals('DM Sans'));
      expect(typography.paragraphFamily, equals('DM Sans'));
      expect(
        typography.interfaceFallbacks,
        equals(const <String>[
          'Noto Sans',
          'Noto Sans Arabic',
          'Roboto',
          'Arial',
          'sans-serif',
        ]),
      );
    });

    test('exposes Fraunces roles and display fallbacks for authored type', () {
      const typography = AmberDuskTokens.typography;

      expect(typography.displayFamily, equals('Fraunces'));
      expect(typography.titleFamily, equals('Fraunces'));
      expect(typography.nameFamily, equals('Fraunces'));
      expect(typography.moneyFamily, equals('Fraunces'));
      expect(typography.walletAmountFamily, equals('DM Sans'));
      expect(
        typography.displayFallbacks,
        equals(const <String>[
          'DM Serif Display',
          'Georgia',
          'DM Sans',
          'Noto Sans',
          'Noto Sans Arabic',
          'serif',
        ]),
      );
    });

    test('pins role style sizes, weights, and family ownership', () {
      const typography = AmberDuskTokens.typography;

      expect(typography.screenTitle.fontFamily, equals('Fraunces'));
      expect(typography.screenTitle.fontSize, equals(30));
      expect(typography.screenTitle.fontWeight, equals(FontWeight.w700));
      expect(typography.screenTitle.letterSpacing, equals(0));
      expect(typography.notificationTitle.fontFamily, equals('DM Sans'));
      expect(typography.notificationTitle.fontSize, equals(18));
      expect(typography.notificationTitle.fontWeight, isNull);
      expect(typography.bookingName.fontFamily, equals('Fraunces'));
      expect(typography.bookingName.fontSize, equals(22));
      expect(typography.bookingName.fontWeight, equals(FontWeight.w700));
      expect(typography.moneyLarge.fontSize, equals(44));
      expect(typography.moneyLarge.fontWeight, equals(FontWeight.w800));
      expect(typography.moneyMedium.fontSize, equals(36));
      expect(typography.moneyMedium.fontWeight, equals(FontWeight.w800));
      expect(typography.walletAmount.fontFamily, equals('DM Sans'));
      expect(typography.walletAmount.fontSize, equals(38));
      expect(typography.walletAmount.fontWeight, equals(FontWeight.w900));
      expect(typography.walletAmountCompact.fontFamily, equals('DM Sans'));
      expect(typography.walletAmountCompact.fontSize, equals(30));
      expect(
        typography.walletAmountCompact.fontWeight,
        equals(FontWeight.w900),
      );
      expect(typography.body.fontFamily, equals('DM Sans'));
      expect(typography.body.fontSize, equals(14));
      expect(typography.control.fontWeight, equals(FontWeight.w700));
      expect(typography.navLabel.fontSize, equals(11));
    });

    test('keeps font fallbacks as family names rather than asset paths', () {
      const typography = AmberDuskTokens.typography;
      final fontNames = <String>[
        typography.interfaceFamily,
        typography.displayFamily,
        ...List<String>.from(typography.interfaceFallbacks),
        ...List<String>.from(typography.displayFallbacks),
      ];

      for (final fontName in fontNames) {
        expect(fontName, isNot(contains('/')));
        expect(fontName.toLowerCase(), isNot(contains('assets')));
        expect(fontName.toLowerCase(), isNot(contains('.woff')));
        expect(fontName.toLowerCase(), isNot(contains('.ttf')));
      }
    });
  });

  group('AmberDuskTokens - Spacing And State Measurements', () {
    test('pins the reusable spacing scale and radii', () {
      const spacing = AmberDuskTokens.spacing;

      expect(spacing.grid, equals(4));
      expect(spacing.xxs, equals(2));
      expect(spacing.xs, equals(4));
      expect(spacing.sm, equals(8));
      expect(spacing.md, equals(12));
      expect(spacing.lg, equals(16));
      expect(spacing.contentHorizontalPadding, equals(20));
      expect(spacing.xl, equals(24));
      expect(spacing.xxl, equals(32));
      expect(spacing.compactControlRadius, equals(15));
      expect(spacing.moduleRadius, equals(18));
      expect(spacing.taskCardRadius, equals(22));
      expect(spacing.heroCardRadius, equals(24));
      expect(spacing.navRadius, equals(26));
      expect(spacing.sheetRadius, equals(30));
      expect(spacing.frameRadius, equals(48));
      expect(spacing.fabRadius, equals(22));
      expect(spacing.pillRadius, equals(999));
      expect(spacing.activeGlowBlur, equals(8));
      expect(spacing.borderWidth, equals(0));
      expect(spacing.borderWidthStrong, equals(0));
    });
  });

  group('AmberDuskTokens - Surfaces', () {
    test('pins public surface recipe names and borderless OD rims', () {
      const surfaces = AmberDuskTokens.surfaces;
      final recipes = <AmberDuskSurfaceRecipe>[
        surfaces.base,
        surfaces.raised,
        surfaces.hero,
        surfaces.nav,
        surfaces.sheet,
        surfaces.cta,
      ];

      expect(
        surfaces.recipeNames,
        equals(const <String>['base', 'raised', 'hero', 'nav', 'sheet', 'cta']),
      );

      for (final recipe in recipes) {
        expect(recipe.border, equals(Colors.transparent), reason: recipe.name);
        expect(recipe.elevationLevel, greaterThanOrEqualTo(1));
      }
    });

    test(
      'preserves shadow token names and restores V2 hero card gradients',
      () {
        const surfaces = AmberDuskTokens.surfaces;

        expect(surfaces.base.shadowTokenName, equals('shadow-surface'));
        expect(surfaces.raised.shadowTokenName, equals('shadow-raised'));
        expect(surfaces.nav.shadowTokenName, equals('shadow-nav'));
        expect(surfaces.sheet.shadowTokenName, equals('shadow-raised'));
        expect(surfaces.cta.shadowTokenName, equals('shadow-cta'));
        expect(surfaces.cta.radius, equals(999));

        final hero = surfaces.hero;
        expect(hero.shadowTokenName, equals('shadow-hero'));
        expect(hero.radius, equals(24));
        expect(hero.fill, equals(AmberDuskColors.hero));
        expect(hero.gradientAngleDegrees, equals(172));
        expect(hero.hasGradient, isTrue);
        expect(
          hero.gradientStops,
          equals(const <Color>[
            Color(0xFF4A2D1F),
            Color(0xFF3E2418),
            Color(0xFF2E1810),
          ]),
        );
        expect(hero.hasHighlight, isTrue);
        expect(hero.highlightColor, equals(const Color(0x0AFFFFFF)));
        expect(hero.hasRim, isTrue);
        expect(hero.rimColor, equals(const Color(0x0FFFFFFF)));
      },
    );
  });

  group('AmberDuskTokens - Motion', () {
    test(
      'aliases existing AppMotion values instead of creating choreography',
      () {
        const motion = AmberDuskTokens.motion;

        expect(motion.activeState, equals(AppMotion.fast));
        expect(motion.surfaceTransition, equals(AppMotion.standard));
        expect(motion.heroTransition, equals(AppMotion.emphasis));
        expect(motion.enterCurve, equals(AppMotion.curveDecel));
        expect(motion.stateCurve, equals(AppMotion.curveStandard));
        expect(motion.pressScale, equals(AppMotion.pressScale));
      },
    );
  });

  group('AmberDuskTokens - Components', () {
    test('pins component recipe names and token references', () {
      const components = AmberDuskTokens.components;

      expect(
        components.recipeNames,
        equals(const <String>[
          'bookingCard',
          'taskCard',
          'bottomNav',
          'floatingActionButton',
          'bottomSheet',
          'chip',
          'statusBadge',
        ]),
      );
      expect(components.bookingCard.surfaceName, equals('hero'));
      expect(components.bookingCard.radius, equals(24));
      expect(components.bookingCard.typographyRole, equals('bookingName'));
      expect(components.taskCard.surfaceName, equals('raised'));
      expect(components.taskCard.radius, equals(22));
      expect(components.bottomNav.surfaceName, equals('nav'));
      expect(components.bottomNav.radius, equals(26));
      expect(components.floatingActionButton.surfaceName, equals('cta'));
      expect(components.floatingActionButton.radius, equals(22));
      expect(components.bottomSheet.surfaceName, equals('sheet'));
      expect(components.bottomSheet.radius, equals(30));
      expect(components.chip.radius, equals(999));
      expect(components.statusBadge.radius, equals(999));
      expect(components.statusBadge.typographyRole, equals('chip'));
    });
  });

  group('AmberDuskTokens - No Glass Guardrails', () {
    test(
      'does not add forbidden glass or blur constructs to source files',
      () async {
        const directoryPath = 'lib/core/theme/designs/amber_dusk';
        final sourceDirectory = Directory(directoryPath);

        if (!sourceDirectory.existsSync()) {
          fail(
            "Directory('lib/core/theme/designs/amber_dusk') is missing; "
            'sourceFiles cannot be scanned.',
          );
        }

        late final List<File> sourceFiles;
        try {
          sourceFiles = await sourceDirectory
              .list(recursive: true)
              .where((entity) {
                return entity is File && entity.path.endsWith('.dart');
              })
              .cast<File>()
              .toList();
        } on FileSystemException catch (error) {
          fail(
            "Directory('lib/core/theme/designs/amber_dusk') listing failed "
            'for sourceFiles: $error',
          );
        } on Exception catch (error) {
          fail(
            "Directory('lib/core/theme/designs/amber_dusk') listing failed "
            'for sourceFiles: $error',
          );
        }

        expect(sourceFiles, isNotEmpty);

        for (final sourceFile in sourceFiles) {
          late final String source;
          try {
            source = await sourceFile.readAsString();
          } on FileSystemException catch (error) {
            fail(
              'sourceFile.readAsString failed for ${sourceFile.path}: $error',
            );
          } on Exception catch (error) {
            fail(
              'sourceFile.readAsString failed for ${sourceFile.path}: $error',
            );
          }

          expect(
            source,
            isNot(contains('BackdropFilter')),
            reason: sourceFile.path,
          );
          expect(
            source,
            isNot(contains('ImageFilter.blur')),
            reason: sourceFile.path,
          );
          expect(
            source,
            isNot(contains('GlassContainer')),
            reason: sourceFile.path,
          );
          expect(source, isNot(contains('GlassCard')), reason: sourceFile.path);
          expect(
            source,
            isNot(contains('GlassButton')),
            reason: sourceFile.path,
          );
          expect(
            source.toLowerCase(),
            isNot(contains('backdrop-filter')),
            reason: sourceFile.path,
          );
          expect(
            source.toLowerCase(),
            isNot(contains('filter: blur')),
            reason: sourceFile.path,
          );
        }
      },
    );
  });
}
