/// Tests the Amber Dusk CTA resolver while preserving existing action labels.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/unified_cta_resolver.dart';

void main() {
  const colors = AmberDuskTokens.colors;

  group('UnifiedCtaResolver.resolveActions', () {
    test('keeps client award flow labels and maps badge to warning', () {
      final result = UnifiedCtaResolver.resolveActions(
        status: 'pending',
        paymentStatus: 'unpaid',
        actorRole: 'client',
        entityType: 'task',
      );

      expect(result.allowedActions, ['award']);
      expect(result.badgeText, 'Needs Award');
      expect(result.badgeColor, colors.warning);
    });

    test('keeps client payment flow labels and maps badge to warning', () {
      final result = UnifiedCtaResolver.resolveActions(
        status: 'accepted',
        paymentStatus: 'unpaid',
        actorRole: 'client',
        entityType: 'booking',
      );

      expect(result.allowedActions, ['pay']);
      expect(result.badgeText, 'Needs Payment');
      expect(result.badgeColor, colors.warning);
    });

    test('keeps delivered work review action and maps badge to warning', () {
      final result = UnifiedCtaResolver.resolveActions(
        status: 'delivered',
        paymentStatus: 'held',
        actorRole: 'client',
        entityType: 'booking',
      );

      expect(result.allowedActions, ['release_with_fee']);
      expect(result.badgeText, 'Review Work');
      expect(result.badgeColor, colors.warning);
    });

    test(
      'keeps refund states server-authoritative and maps badge to danger',
      () {
        for (final status in [
          'declined',
          'canceled',
          'expired',
          'dispute_refund',
        ]) {
          final result = UnifiedCtaResolver.resolveActions(
            status: status,
            paymentStatus: 'held',
            actorRole: 'provider',
            entityType: 'booking',
          );

          expect(result.allowedActions, ['refund'], reason: status);
          expect(result.badgeText, 'Needs Refund', reason: status);
          expect(result.badgeColor, colors.danger, reason: status);
        }
      },
    );

    test('returns no CTA metadata when state does not allow an action', () {
      final result = UnifiedCtaResolver.resolveActions(
        status: 'active',
        paymentStatus: 'held',
        actorRole: 'provider',
        entityType: 'booking',
      );

      expect(result.allowedActions, isEmpty);
      expect(result.badgeText, isNull);
      expect(result.badgeColor, isNull);
    });
  });
}
