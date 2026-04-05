import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/utils/status_presenter.dart';
import 'package:sline_app/core/utils/unified_cta_resolver.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/viewmodels/award_expiration_monitor.dart';

/// Dashboard-style offer card for inbox; lives in tasks feature.
class DashboardOfferCard extends StatelessWidget {
  final TaskRequest offer;
  final bool isClientView;
  final VoidCallback onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onWithdraw;
  final VoidCallback? onRelease;
  final VoidCallback? onRefund;

  const DashboardOfferCard({
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
    final statusColor = StatusPresenter.offerStatusColor(offer.status);
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
                _OfferStatusBadge(status: offer.status, color: statusColor),
              ],
            ),
          ),
          // Payment deadline countdown for accepted unpaid offers
          if (offer.status == OfferStatus.accepted &&
              offer.paymentStatus == PaymentStatus.unpaid &&
              offer.paymentDeadline != null)
            _PaymentDeadlineCountdown(deadline: offer.paymentDeadline!),
          Padding(
            padding: const EdgeInsets.all(AppDimens.p16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            : 'My Offer',
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
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.attach_money,
                            label: PriceFormatter.formatPrice(
                              offer.price.toDouble(),
                            ),
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
          Builder(
            builder: (ctx) {
              final ctaMeta = UnifiedCtaResolver.resolveActions(
                status: offer.status.name,
                paymentStatus: offer.paymentStatus.name,
                actorRole: isClientView ? 'client' : 'provider',
                entityType: 'task_request',
              );
              final showAward = ctaMeta.allowedActions.contains('award');
              final showPay = ctaMeta.allowedActions.contains('pay');
              final showEscrow = ctaMeta.allowedActions.contains(
                'escrow_hold',
              );
              final showRelease = ctaMeta.allowedActions.contains(
                'release_with_fee',
              );
              final showRefund = ctaMeta.allowedActions.contains('refund');

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
                          child: const Text('Escrow Funds'),
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
}

class _OfferStatusBadge extends StatelessWidget {
  final OfferStatus status;
  final Color color;

  const _OfferStatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = StatusPresenter.offerStatusLabel(status);
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

/// Payment deadline countdown widget for accepted unpaid offers.
///
/// Shows a live countdown badge that changes color based on urgency:
/// - Green: > 24 hours remaining
/// - Orange: 6-24 hours remaining
/// - Red + pulse: < 6 hours remaining
class _PaymentDeadlineCountdown extends StatefulWidget {
  final DateTime deadline;

  const _PaymentDeadlineCountdown({required this.deadline});

  @override
  State<_PaymentDeadlineCountdown> createState() =>
      _PaymentDeadlineCountdownState();
}

class _PaymentDeadlineCountdownState extends State<_PaymentDeadlineCountdown>
    with SingleTickerProviderStateMixin {
  late final AwardExpirationMonitor _monitor;
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _monitor = AwardExpirationMonitor();
    _monitor.startMonitoring(widget.deadline);
    _monitor.addListener(_onMonitorUpdate);

    // Set up pulse animation for critical urgency
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _onMonitorUpdate() {
    if (!mounted) return;

    // Start/stop pulse animation based on urgency
    if (_monitor.shouldPulse && !_pulseController!.isAnimating) {
      _pulseController!.repeat(reverse: true);
    } else if (!_monitor.shouldPulse && _pulseController!.isAnimating) {
      _pulseController!.stop();
      _pulseController!.value = 1.0;
    }

    setState(() {});
  }

  Color _getUrgencyColor(AppColorScheme colorScheme) {
    switch (_monitor.urgencyLevel) {
      case UrgencyLevel.relaxed:
        return Colors.green;
      case UrgencyLevel.urgent:
        return Colors.orange;
      case UrgencyLevel.critical:
      case UrgencyLevel.expired:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final urgencyColor = _getUrgencyColor(colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: urgencyColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController!,
            builder: (context, child) {
              return Transform.scale(
                scale: _monitor.shouldPulse
                    ? 1.0 + (_pulseController!.value * 0.1)
                    : 1.0,
                child: Icon(
                  Icons.access_time_filled,
                  size: 16,
                  color: urgencyColor,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _monitor.isExpired
                  ? 'Payment window closed'
                  : 'Payment deadline: ${_monitor.countdownText ?? ''}',
              style: AppTypography.captionBold.copyWith(color: urgencyColor),
            ),
          ),
          if (!_monitor.isExpired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _monitor.urgencyLevel == UrgencyLevel.critical
                    ? 'URGENT'
                    : _monitor.urgencyLevel == UrgencyLevel.urgent
                    ? 'SOON'
                    : 'PENDING',
                style: AppTypography.captionBold.copyWith(
                  color: urgencyColor,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _monitor.removeListener(_onMonitorUpdate);
    _monitor.dispose();
    super.dispose();
  }
}
