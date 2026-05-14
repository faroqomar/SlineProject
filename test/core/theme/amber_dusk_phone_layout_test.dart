/// Tests for the staged Amber Dusk phone layout token contract.
///
/// These pure token checks pin the 402 x 874 phone foundation before feature
/// screens consume the layout values in later implementation phases.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

void main() {
  group('AmberDuskPhoneLayout - Frame', () {
    test('matches the Open Design phone artboard dimensions', () {
      const layout = AmberDuskTokens.phoneLayout;

      expect(layout.frameWidth, closeTo(402.0, 0.001));
      expect(layout.frameHeight, closeTo(874.0, 0.001));
      expect(layout.frameRadius, closeTo(48.0, 0.001));
    });
  });

  group('AmberDuskPhoneLayout - Content Padding', () {
    test('matches the phone scroll container padding contract', () {
      const layout = AmberDuskTokens.phoneLayout;

      expect(layout.horizontalPadding, closeTo(20.0, 0.001));
      expect(layout.topPadding, closeTo(64.0, 0.001));
      expect(layout.contentBottomPadding, closeTo(120.0, 0.001));
      expect(layout.bottomScrollPadding, closeTo(138.0, 0.001));
      expect(layout.safeBottomPadding, closeTo(22.0, 0.001));
    });
  });

  group('AmberDuskPhoneLayout - Bottom Navigation', () {
    test('matches the floating bottom navigation measurements', () {
      const layout = AmberDuskTokens.phoneLayout;

      expect(layout.bottomNavInset, closeTo(16.0, 0.001));
      expect(layout.bottomNavBottom, closeTo(24.0, 0.001));
      expect(layout.bottomNavHeight, closeTo(68.0, 0.001));
      expect(layout.bottomNavRadius, closeTo(26.0, 0.001));
    });
  });

  group('AmberDuskPhoneLayout - Floating Action Button', () {
    test('matches the Open Design FAB size and radius', () {
      const layout = AmberDuskTokens.phoneLayout;

      expect(layout.fabSize, closeTo(56.0, 0.001));
      expect(layout.fabRadius, closeTo(22.0, 0.001));
    });
  });

  group('AmberDuskPhoneLayout - Dynamic Island', () {
    test('matches the source artboard dynamic island measurements', () {
      const layout = AmberDuskTokens.phoneLayout;

      expect(layout.dynamicIslandWidth, closeTo(126.0, 0.001));
      expect(layout.dynamicIslandHeight, closeTo(37.0, 0.001));
    });
  });

  group('AmberDuskPhoneLayout - Dimension Relationships', () {
    test('keeps fixed phone measurements internally consistent', () {
      const layout = AmberDuskTokens.phoneLayout;

      expect(layout.horizontalPadding * 2, lessThan(layout.frameWidth));
      expect(
        layout.topPadding + layout.contentBottomPadding,
        lessThan(layout.frameHeight),
      );
      expect(
        layout.bottomNavInset + layout.bottomNavHeight + layout.bottomNavBottom,
        lessThan(layout.frameHeight),
      );
      expect(layout.fabSize, lessThan(layout.frameWidth));
    });

    test('compares identical token instances by value', () {
      const layout = AmberDuskTokens.phoneLayout;
      const copy = AmberDuskPhoneLayoutTokens();

      expect(layout, equals(copy));
      expect(layout.hashCode, equals(copy.hashCode));
    });
  });
}
