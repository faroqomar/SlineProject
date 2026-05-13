import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// Resolves dashboard/detail CTA availability from existing work-item state.
///
/// This helper intentionally stays data-free: it maps already-loaded state into
/// view metadata and leaves payment, refund, and award authority in services.
class UnifiedCtaResolver {
  UnifiedCtaResolver._();

  /// Result of resolving allowed actions based on state and actor.
  static ({List<String> allowedActions, String? badgeText, Color? badgeColor})
  resolveActions({
    required String status,
    required String paymentStatus,
    required String actorRole,
    required String entityType,
  }) {
    final allowedActions = <String>[];
    String? badgeText;
    Color? badgeColor;
    const colors = AmberDuskTokens.colors;

    if (actorRole == 'client') {
      if (status == 'pending' && paymentStatus == 'unpaid') {
        // Two-step flow: Award first, then Pay; no payment call is made here.
        allowedActions.add('award');
        badgeText = 'Needs Award';
        badgeColor = colors.warning;
      } else if (status == 'accepted' && paymentStatus == 'unpaid') {
        // Awarded but not paid yet: surface the Pay action without mutating escrow.
        allowedActions.add('pay');
        badgeText = 'Needs Payment';
        badgeColor = colors.warning;
      } else if (status == 'delivered' && paymentStatus == 'held') {
        allowedActions.add('release_with_fee');
        badgeText = 'Review Work';
        badgeColor = colors.warning;
      }
    } else if (actorRole == 'provider' || actorRole == 'system') {
      // Refund availability mirrors existing backend states; this helper only
      // exposes the CTA so refund authority stays server-side.
      final allowedToRefund = [
        'declined',
        'canceled',
        'expired',
        'dispute_refund',
      ].contains(status);
      if (paymentStatus == 'held' && allowedToRefund) {
        allowedActions.add('refund');
        badgeText = 'Needs Refund';
        badgeColor = colors.danger;
      }
    }

    return (
      allowedActions: allowedActions,
      badgeText: badgeText,
      badgeColor: badgeColor,
    );
  }
}
