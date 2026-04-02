import 'package:flutter/material.dart';

class UnifiedCtaResolver {
  /// Result of resolving allowed actions based on state and actor
  static ({List<String> allowedActions, String? badgeText, Color? badgeColor})
  resolveActions({
    required String status,
    required String paymentStatus,
    required String actorRole,
    required String entityType,
  }) {
    final List<String> allowedActions = [];
    String? badgeText;
    Color? badgeColor;

    if (actorRole == 'client') {
      if (status == 'pending' && paymentStatus == 'unpaid') {
        // Two-step flow: Award first, then Pay
        allowedActions.add('award');
        badgeText = 'Needs Award';
        badgeColor = const Color(0xFFF3BB19); // AppColors.gold
      } else if (status == 'accepted' && paymentStatus == 'unpaid') {
        // Awarded but not paid yet - show Pay action
        allowedActions.add('pay');
        badgeText = 'Needs Payment';
        badgeColor = const Color(0xFFFF9800); // Orange
      } else if (status == 'delivered' && paymentStatus == 'held') {
        allowedActions.add('release_with_fee');
        badgeText = 'Review Work';
        badgeColor = const Color(0xFF146068); // AppColors.teal
      }
    } else if (actorRole == 'provider' || actorRole == 'system') {
      // Typically providers or systems have refund action
      final bool allowedToRefund = [
        'declined',
        'canceled',
        'expired',
        'dispute_refund',
      ].contains(status);
      if (paymentStatus == 'held' && allowedToRefund) {
        allowedActions.add('refund');
        badgeText = 'Needs Refund';
        badgeColor = const Color(0xFFF49D9D); // AppColors.lightRed
      }
    }

    return (
      allowedActions: allowedActions,
      badgeText: badgeText,
      badgeColor: badgeColor,
    );
  }
}
