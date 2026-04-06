import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';

class UnifiedCtaResolver {
  /// Result of resolving allowed actions based on state and actor
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

    if (actorRole == 'client') {
      if (status == 'pending' && paymentStatus == 'unpaid') {
        // Two-step flow: Award first, then Pay
        allowedActions.add('award');
        badgeText = 'Needs Award';
        badgeColor = AppColors.gold;
      } else if (status == 'accepted' && paymentStatus == 'unpaid') {
        // Awarded but not paid yet - show Pay action
        allowedActions.add('pay');
        badgeText = 'Needs Payment';
        badgeColor = Colors.orange;
      } else if (status == 'delivered' && paymentStatus == 'held') {
        allowedActions.add('release_with_fee');
        badgeText = 'Review Work';
        badgeColor = AppColors.teal;
      }
    } else if (actorRole == 'provider' || actorRole == 'system') {
      // Typically providers or systems have refund action
      final allowedToRefund = [
        'declined',
        'canceled',
        'expired',
        'dispute_refund',
      ].contains(status);
      if (paymentStatus == 'held' && allowedToRefund) {
        allowedActions.add('refund');
        badgeText = 'Needs Refund';
        badgeColor = AppColors.lightRed;
      }
    }

    return (
      allowedActions: allowedActions,
      badgeText: badgeText,
      badgeColor: badgeColor,
    );
  }
}
