import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/core/utils/unified_cta_resolver.dart';

class OfferCard extends StatelessWidget {
  final TaskRequest offer;
  final bool
  isClientView; // True if viewing offers received, False if viewing submitted
  final VoidCallback onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onWithdraw;
  final VoidCallback? onRelease;
  final VoidCallback? onRefund;

  const OfferCard({
    super.key,
    required this.offer,
    required this.isClientView,
    required this.onAccept,
    this.onReject,
    this.onWithdraw,
    this.onRelease,
    this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final statusColor = _getStatusColor();
    final isPending = offer.status == OfferStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p16,
              vertical: AppDimens.p12,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.r16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'OFFER',
                        style: AppTypography.captionBold.copyWith(
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          offer.taskTitle ?? 'Unknown Task',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.textSecondary,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: offer.status, color: statusColor),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(AppDimens.p16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar (Show Bidder if Client view, else maybe Task Owner or empty?)
                // For layout simplicity, let's show Bidder Avatar always for now
                if (offer.bidderAvatar != null)
                  Padding(
                    padding: const EdgeInsets.only(right: AppDimens.p12),
                    child: SignedAvatar(
                      storagePathOrUrl: offer.bidderAvatar,
                      radius: 20,
                    ),
                  ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isClientView
                            ? (offer.bidderName ?? 'Freelancer')
                            : 'My Offer', // Or show who we sent it to? (Logic separate)
                        style: AppTypography.h4,
                      ),
                      const SizedBox(height: AppDimens.p4),
                      Text(
                        formatUtcToLocal(offer.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.p12),

                      // Offer Details Row
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.attach_money,
                            label: '\$${offer.price}',
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(width: AppDimens.p8),
                          _InfoChip(
                            icon: Icons.access_time,
                            label: '${offer.days} Days',
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),

                      if (offer.note != null && offer.note!.isNotEmpty) ...[
                        const SizedBox(height: AppDimens.p12),
                        Text(
                          '"${offer.note}"',
                          style: AppTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions Footer
          Builder(
            builder: (ctx) {
              final ctaMeta = UnifiedCtaResolver.resolveActions(
                status: offer.status.name,
                paymentStatus: offer.paymentStatus.name,
                actorRole: isClientView ? 'client' : 'provider',
                entityType: 'task_request',
              );

              final bool showAward = ctaMeta.allowedActions.contains('award');
              final bool showPay = ctaMeta.allowedActions.contains('pay');
              final bool showEscrow = ctaMeta.allowedActions.contains(
                'escrow_hold',
              );
              final bool showRelease = ctaMeta.allowedActions.contains(
                'release_with_fee',
              );
              final bool showRefund = ctaMeta.allowedActions.contains('refund');

              // If no specific payment actions are resolved but it's still pending, we fallback to our generic logic for non-payment MVP states
              // Actually, since we wired escrow_hold, let's just use it combined with legacy.

              if (!isPending && !showRelease && !showRefund && !showPay) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.p16,
                  0,
                  AppDimens.p16,
                  AppDimens.p16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isClientView) ...[
                      if (onReject != null && isPending)
                        TextButton(
                          onPressed: () {
                            AppLogger.i(
                              'Offer card reject tapped for offer=${offer.id}',
                              tag: 'OfferCard',
                            );
                            onReject?.call();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.lightRed,
                          ),
                          child: const Text('Reject'),
                        ),
                      const SizedBox(width: AppDimens.p8),
                      // New two-step flow: Award button
                      if (showAward)
                        FilledButton(
                          onPressed: () {
                            AppLogger.i(
                              'Offer card award tapped for offer=${offer.id}',
                              tag: 'OfferCard',
                            );
                            onAccept();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                          ),
                          child: const Text('Award'),
                        ),
                      // Pay button for awarded but unpaid offers
                      if (showPay)
                        FilledButton(
                          onPressed: () {
                            AppLogger.i(
                              'Offer card pay tapped for offer=${offer.id}',
                              tag: 'OfferCard',
                            );
                            onAccept();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Pay Now'),
                        ),
                      if (showEscrow)
                        FilledButton(
                          onPressed: () {
                            AppLogger.i(
                              'Offer card escrow tapped for offer=${offer.id}',
                              tag: 'OfferCard',
                            );
                            onAccept();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                          ),
                          child: const Text(
                            'Escrow Funds',
                          ), // Replaced 'Accept' with Escrow
                        ),
                      if (!showEscrow && !showAward && !showPay && isPending)
                        FilledButton(
                          onPressed: () {
                            AppLogger.i(
                              'Offer card accept tapped for offer=${offer.id}',
                              tag: 'OfferCard',
                            );
                            onAccept();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                          ),
                          child: const Text('Accept'),
                        ),
                      if (onRelease != null && showRelease)
                        FilledButton(
                          onPressed: () {
                            AppLogger.i(
                              'Offer card release tapped for offer=${offer.id}',
                              tag: 'OfferCard',
                            );
                            onRelease?.call();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                          ),
                          child: const Text('Release Funds'),
                        ),
                      if (onRefund != null && showRefund)
                        TextButton(
                          onPressed: () {
                            AppLogger.i(
                              'Offer card refund tapped for offer=${offer.id}',
                              tag: 'OfferCard',
                            );
                            onRefund?.call();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.lightRed,
                          ),
                          child: const Text('Refund'),
                        ),
                    ] else ...[
                      // Freelancer View
                      if (onWithdraw != null && isPending)
                        OutlinedButton.icon(
                          onPressed: () {
                            AppLogger.i(
                              'Offer card withdraw tapped for offer=${offer.id}',
                              tag: 'OfferCard',
                            );
                            onWithdraw?.call();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.lightRed,
                            side: BorderSide(
                              color: AppColors.lightRed.withValues(alpha: 0.5),
                            ),
                          ),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Withdraw'),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (offer.status) {
      case OfferStatus.pending:
        return AppColors.gold;
      case OfferStatus.accepted:
        return AppColors.teal;
      case OfferStatus.rejected:
      case OfferStatus.withdrawn:
      case OfferStatus.unknown:
        return AppColors.lightRed;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final OfferStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    String label;
    switch (status) {
      case OfferStatus.pending:
        label = 'Pending';
        break;
      case OfferStatus.accepted:
        label = 'Accepted';
        break;
      case OfferStatus.rejected:
        label = 'Rejected';
        break;
      case OfferStatus.withdrawn:
        label = 'Withdrawn';
        break;
      case OfferStatus.unknown:
        label = 'Unavailable';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.captionBold.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColorScheme colorScheme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.captionBold.copyWith(color: colorScheme.text),
          ),
        ],
      ),
    );
  }
}
