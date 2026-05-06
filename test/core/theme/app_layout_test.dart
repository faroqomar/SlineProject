// Tests for AppLayout — centralized layout tokens.
//
// Verifies that every token has the correct value matching the codebase,
// that the three-layer architecture rules are respected (no overlap with
// AppDimens icon sizes), and that all tokens are properly categorized.
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';

void main() {
  group('AppLayout — Card Dimensions', () {
    test('cardPadding matches standard 16px card padding', () {
      expect(AppLayout.cardPadding, equals(16.0));
    });

    test('cardPaddingCompact matches dense list padding', () {
      expect(AppLayout.cardPaddingCompact, equals(12.0));
    });

    test('cardSectionSpacing matches inner card gap', () {
      expect(AppLayout.cardSectionSpacing, equals(8.0));
    });

    test('cardHeaderHeight matches gradient/image header', () {
      expect(AppLayout.cardHeaderHeight, equals(60.0));
    });

    test('cardBorderWidth matches solid surface border', () {
      expect(AppLayout.cardBorderWidth, equals(1.0));
    });
  });

  group('AppLayout — Avatar Sizes', () {
    test('avatarTiny is 24px diameter', () {
      expect(AppLayout.avatarTiny, equals(24.0));
    });

    test('avatarSmall is 36px diameter', () {
      expect(AppLayout.avatarSmall, equals(36.0));
    });

    test('avatarDefault is 40px (matches SignedAvatar default radius=20)', () {
      expect(AppLayout.avatarDefault, equals(40.0));
    });

    test('avatarMedium is 44px diameter', () {
      expect(AppLayout.avatarMedium, equals(44.0));
    });

    test('avatarLarge is 64px diameter', () {
      expect(AppLayout.avatarLarge, equals(64.0));
    });

    test('avatarHero is 80px diameter', () {
      expect(AppLayout.avatarHero, equals(80.0));
    });

    test('avatar sizes are strictly ascending', () {
      expect(AppLayout.avatarTiny, lessThan(AppLayout.avatarSmall));
      expect(AppLayout.avatarSmall, lessThan(AppLayout.avatarDefault));
      expect(AppLayout.avatarDefault, lessThan(AppLayout.avatarMedium));
      expect(AppLayout.avatarMedium, lessThan(AppLayout.avatarLarge));
      expect(AppLayout.avatarLarge, lessThan(AppLayout.avatarHero));
    });
  });

  group('AppLayout — Button Heights', () {
    test('buttonHeight is 54px (AppButton default via AppDimens.p54)', () {
      expect(AppLayout.buttonHeight, equals(54.0));
    });

    test('buttonHeightCompact is 48px (AppStyledButton default)', () {
      expect(AppLayout.buttonHeightCompact, equals(48.0));
    });

    test('buttonHeightSmall is 36px', () {
      expect(AppLayout.buttonHeightSmall, equals(36.0));
    });

    test(
      'circleButtonVisualSize is 40px (visual circle, not touch target)',
      () {
        expect(AppLayout.circleButtonVisualSize, equals(40.0));
      },
    );

    test('minTouchTarget is 48px (WCAG minimum)', () {
      expect(AppLayout.minTouchTarget, equals(48.0));
    });

    test('minTouchTarget >= circleButtonVisualSize (WCAG compliance)', () {
      expect(
        AppLayout.minTouchTarget,
        greaterThanOrEqualTo(AppLayout.circleButtonVisualSize),
      );
    });

    test('fabSize is 56px', () {
      expect(AppLayout.fabSize, equals(56.0));
    });
  });

  group('AppLayout — Spacing Rhythm', () {
    test('spacingTight is 4px', () {
      expect(AppLayout.spacingTight, equals(4.0));
    });

    test('spacingStandard is 8px', () {
      expect(AppLayout.spacingStandard, equals(8.0));
    });

    test('spacingSection is 16px', () {
      expect(AppLayout.spacingSection, equals(16.0));
    });

    test('spacingScreen is 24px', () {
      expect(AppLayout.spacingScreen, equals(24.0));
    });

    test('spacingLarge is 32px', () {
      expect(AppLayout.spacingLarge, equals(32.0));
    });

    test('screenHorizontalMargin is 24px (from .impeccable.md)', () {
      expect(AppLayout.screenHorizontalMargin, equals(24.0));
    });

    test('spacing values are strictly ascending', () {
      expect(AppLayout.spacingTight, lessThan(AppLayout.spacingStandard));
      expect(AppLayout.spacingStandard, lessThan(AppLayout.spacingSection));
      expect(AppLayout.spacingSection, lessThan(AppLayout.spacingScreen));
      expect(AppLayout.spacingScreen, lessThan(AppLayout.spacingLarge));
    });

    test('spacing values follow 4px grid system', () {
      // All spacing tokens should be multiples of 4
      expect(AppLayout.spacingTight % 4, equals(0));
      expect(AppLayout.spacingStandard % 4, equals(0));
      expect(AppLayout.spacingSection % 4, equals(0));
      expect(AppLayout.spacingScreen % 4, equals(0));
      expect(AppLayout.spacingLarge % 4, equals(0));
      expect(AppLayout.screenHorizontalMargin % 4, equals(0));
    });
  });

  group('AppLayout — Content Widths', () {
    test('formMaxWidth is 400px', () {
      expect(AppLayout.formMaxWidth, equals(400.0));
    });

    test('cardMaxWidth is 600px', () {
      expect(AppLayout.cardMaxWidth, equals(600.0));
    });
  });

  group('AppLayout — Icon Sizes (no overlap with AppDimens)', () {
    test('iconTiny is 12px', () {
      expect(AppLayout.iconTiny, equals(12.0));
    });

    test('iconStandard is 20px', () {
      expect(AppLayout.iconStandard, equals(20.0));
    });

    test('iconFeature is 48px', () {
      expect(AppLayout.iconFeature, equals(48.0));
    });

    test('iconTiny does NOT overlap AppDimens.iconSizeSmall (16)', () {
      expect(AppLayout.iconTiny, isNot(equals(AppDimens.iconSizeSmall)));
    });

    test('iconStandard does NOT overlap AppDimens.iconSizeMedium (24)', () {
      expect(AppLayout.iconStandard, isNot(equals(AppDimens.iconSizeMedium)));
    });

    test('iconFeature does NOT overlap AppDimens.iconSizeLarge (32)', () {
      expect(AppLayout.iconFeature, isNot(equals(AppDimens.iconSizeLarge)));
    });
  });

  group('AppLayout — Thumbnail Sizes', () {
    test('thumbnailSmall is 60px', () {
      expect(AppLayout.thumbnailSmall, equals(60.0));
    });

    test('thumbnailMedium is 80px', () {
      expect(AppLayout.thumbnailMedium, equals(80.0));
    });
  });

  group('AppLayout — Navigation', () {
    test('bottomNavHeight is 70px (actual, not Master Plan 64)', () {
      expect(AppLayout.bottomNavHeight, equals(70.0));
    });

    test('fabBottomOffset is 100px', () {
      expect(AppLayout.fabBottomOffset, equals(100.0));
    });

    test('statusIndicatorHeight is 40px', () {
      expect(AppLayout.statusIndicatorHeight, equals(40.0));
    });
  });

  group('AppLayout — Stagger Intervals', () {
    test('authStaggerCount is 5', () {
      expect(AppLayout.authStaggerCount, equals(5));
    });

    test('signupStaggerCount is 6', () {
      expect(AppLayout.signupStaggerCount, equals(6));
    });

    test('signup has more stagger elements than auth', () {
      expect(
        AppLayout.signupStaggerCount,
        greaterThan(AppLayout.authStaggerCount),
      );
    });
  });

  group('AppLayout — List / Tile', () {
    test('listItemMinHeight is 56px', () {
      expect(AppLayout.listItemMinHeight, equals(56.0));
    });

    test('listItemPadding is 16px', () {
      expect(AppLayout.listItemPadding, equals(16.0));
    });

    test('dividerIndent is 16px', () {
      expect(AppLayout.dividerIndent, equals(16.0));
    });
  });

  group('AppLayout — Border Widths', () {
    test('borderStandard is 1px', () {
      expect(AppLayout.borderStandard, equals(1.0));
    });

    test('borderThick is 1.5px', () {
      expect(AppLayout.borderThick, equals(1.5));
    });

    test('borderAvatar is 2px', () {
      expect(AppLayout.borderAvatar, equals(2.0));
    });

    test('border widths are strictly ascending', () {
      expect(AppLayout.borderStandard, lessThan(AppLayout.borderThick));
      expect(AppLayout.borderThick, lessThan(AppLayout.borderAvatar));
    });
  });

  group('AppLayout — Architecture Invariants', () {
    test('all spacing tokens are positive', () {
      expect(AppLayout.spacingTight, greaterThan(0));
      expect(AppLayout.spacingStandard, greaterThan(0));
      expect(AppLayout.spacingSection, greaterThan(0));
      expect(AppLayout.spacingScreen, greaterThan(0));
      expect(AppLayout.spacingLarge, greaterThan(0));
    });

    test('all size tokens are positive', () {
      expect(AppLayout.cardPadding, greaterThan(0));
      expect(AppLayout.avatarTiny, greaterThan(0));
      expect(AppLayout.buttonHeight, greaterThan(0));
      expect(AppLayout.iconTiny, greaterThan(0));
      expect(AppLayout.bottomNavHeight, greaterThan(0));
    });

    test('all border widths are positive and <= 3', () {
      expect(AppLayout.borderStandard, greaterThan(0));
      expect(AppLayout.borderStandard, lessThanOrEqualTo(3));
      expect(AppLayout.borderThick, greaterThan(0));
      expect(AppLayout.borderThick, lessThanOrEqualTo(3));
      expect(AppLayout.borderAvatar, greaterThan(0));
      expect(AppLayout.borderAvatar, lessThanOrEqualTo(3));
    });
  });
}
