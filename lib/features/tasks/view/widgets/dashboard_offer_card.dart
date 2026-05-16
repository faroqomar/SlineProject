import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/utils/status_presenter.dart';
import 'package:sline_app/core/utils/unified_cta_resolver.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/viewmodels/award_expiration_monitor.dart';

/// Dashboard-style offer card for inbox; lives in tasks feature.
///
/// The card keeps offer/payment callbacks injected while normalizing dashboard
/// colors, motion, and typography to the staged Amber Dusk token layer.
class DashboardOfferCard extends StatefulWidget {
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
  State<DashboardOfferCard> createState() => _DashboardOfferCardState();
}

class _DashboardOfferCardState extends State<DashboardOfferCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initPulseIfNeeded();
  }

  @override
  void didUpdateWidget(DashboardOfferCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offer.id != widget.offer.id) {
      _pulseController?.dispose();
      _pulseController = null;
      _pulseAnimation = null;
      _initPulseIfNeeded();
    }
  }

  void _initPulseIfNeeded() {
    final remaining = widget.offer.expirationTime.difference(DateTime.now());
    if (remaining > Duration.zero && remaining.inHours < 2) {
      _pulseController = AnimationController(
        // Slow pulse avoids layout noise while still drawing attention to expiring offers.
        duration: AppMotion.slow,
        vsync: this,
      );
      _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(
          parent: _pulseController!,
          curve: AppMotion.curveStandard,
        ),
      );
      unawaited(_pulseController!.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const spacing = AmberDuskTokens.spacing;
    const typography = AmberDuskTokens.typography;
    final statusColor = _offerStatusColor(widget.offer.status);
    final isPending = widget.offer.status == OfferStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p10),
      decoration: AmberDuskMaterial.surfaceDecoration(
        radius: spacing.taskCardRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p12,
              vertical: AppDimens.p8,
            ),
            decoration: BoxDecoration(
              gradient: AmberDuskMaterial.activeWashGradient,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(spacing.taskCardRadius),
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
                        size: AppDimens.iconSizeSmall,
                        color: statusColor,
                      ),
                      const SizedBox(width: AppDimens.p8),
                      Text(
                        'OFFER',
                        style: typography.chip.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: AppDimens.p8),
                      Flexible(
                        child: Text(
                          widget.offer.taskTitle ?? 'Unknown Task',
                          style: typography.bodySmall.copyWith(
                            color: amber.muted,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                _OfferStatusBadge(
                  status: widget.offer.status,
                  color: statusColor,
                ),
              ],
            ),
          ),
          // Payment deadline countdown for accepted unpaid offers
          if (widget.offer.status == OfferStatus.accepted &&
              widget.offer.paymentStatus == PaymentStatus.unpaid &&
              widget.offer.paymentDeadline != null)
            _PaymentDeadlineCountdown(deadline: widget.offer.paymentDeadline!),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p12,
              vertical: AppDimens.p8,
            ),
            decoration: const BoxDecoration(
              color: AmberDuskWidgetTheme.taskPillSurface,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OFFER PRICE',
                        style: typography.chip.copyWith(color: amber.muted),
                      ),
                      const SizedBox(height: AppDimens.p4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          PriceFormatter.formatPrice(
                            widget.offer.price.toDouble(),
                          ),
                          style: typography.moneyMedium.copyWith(
                            color: amber.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Days badge with info color
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p8,
                    vertical: AppDimens.p6,
                  ),
                  decoration: BoxDecoration(
                    color: amber.infoMuted,
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${widget.offer.days}',
                        style: typography.sectionTitle.copyWith(
                          color: amber.info,
                        ),
                      ),
                      Text(
                        'DAYS',
                        style: typography.chip.copyWith(color: amber.info),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.p12,
              AppDimens.p10,
              AppDimens.p12,
              AppDimens.p8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.offer.bidderAvatar != null)
                      Padding(
                        padding: const EdgeInsets.only(right: AppDimens.p12),
                        child: SignedAvatar(
                          storagePathOrUrl: widget.offer.bidderAvatar,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isClientView
                                ? (widget.offer.bidderName ?? 'Freelancer')
                                : 'My Offer',
                            style: typography.sectionTitle.copyWith(
                              color: amber.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          _buildDeadlineText(),
                        ],
                      ),
                    ),
                  ],
                ),
                // Note block
                if (widget.offer.note != null &&
                    widget.offer.note!.isNotEmpty) ...[
                  const SizedBox(height: AppDimens.p8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p10,
                      vertical: AppDimens.p8,
                    ),
                    decoration: BoxDecoration(
                      color: amber.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppDimens.r8),
                    ),
                    child: Text(
                      '"${widget.offer.note}"',
                      style: typography.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: amber.textSubtle,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _OfferActionRow(
            offer: widget.offer,
            isClientView: widget.isClientView,
            isPending: isPending,
            onAccept: widget.onAccept,
            onReject: widget.onReject,
            onWithdraw: widget.onWithdraw,
            onRelease: widget.onRelease,
            onRefund: widget.onRefund,
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineText() {
    const colors = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;
    final text = Text(
      formatFriendlyTime(widget.offer.createdAt.toLocal()),
      style: typography.bodySmall.copyWith(color: colors.muted),
    );

    if (_pulseAnimation != null) {
      return FadeTransition(opacity: _pulseAnimation!, child: text);
    }
    return text;
  }
}

/// Extracted action row with conditional buttons for different offer states.
class _OfferActionRow extends StatelessWidget {
  final TaskRequest offer;
  final bool isClientView;
  final bool isPending;
  final VoidCallback onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onWithdraw;
  final VoidCallback? onRelease;
  final VoidCallback? onRefund;

  const _OfferActionRow({
    required this.offer,
    required this.isClientView,
    required this.isPending,
    required this.onAccept,
    this.onReject,
    this.onWithdraw,
    this.onRelease,
    this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    const colors = AmberDuskTokens.colors;
    final ctaMeta = UnifiedCtaResolver.resolveActions(
      status: offer.status.name,
      paymentStatus: offer.paymentStatus.name,
      actorRole: isClientView ? 'client' : 'provider',
      entityType: 'task_request',
    );
    final showAward = ctaMeta.allowedActions.contains('award');
    final showPay = ctaMeta.allowedActions.contains('pay');
    final showEscrow = ctaMeta.allowedActions.contains('escrow_hold');
    final showRelease = ctaMeta.allowedActions.contains('release_with_fee');
    final showRefund = ctaMeta.allowedActions.contains('refund');

    if (!isPending && !showRelease && !showRefund && !showPay) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p12,
        0,
        AppDimens.p12,
        AppDimens.p10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isClientView) ...[
            if (onReject != null && isPending)
              TextButton(
                onPressed: () {
                  AppLogger.i('Offer card reject tapped', tag: 'OfferCard');
                  onReject?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: colors.danger,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p12,
                  ),
                ),
                child: const Text('Reject'),
              ),
            const SizedBox(width: AppDimens.p8),
            if (showAward)
              FilledButton(
                onPressed: () {
                  AppLogger.i('Offer card award tapped', tag: 'OfferCard');
                  onAccept();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.text,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p14,
                  ),
                ),
                child: const Text('Award'),
              ),
            if (showPay)
              FilledButton(
                onPressed: () {
                  AppLogger.i('Offer card pay tapped', tag: 'OfferCard');
                  onAccept();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.warning,
                  foregroundColor: colors.text,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p14,
                  ),
                ),
                child: const Text('Pay Now'),
              ),
            if (showEscrow)
              FilledButton(
                onPressed: () {
                  AppLogger.i('Offer card escrow tapped', tag: 'OfferCard');
                  onAccept();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.text,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p14,
                  ),
                ),
                child: const Text('Escrow Funds'),
              ),
            if (!showEscrow && !showAward && !showPay && isPending)
              FilledButton(
                onPressed: () {
                  AppLogger.i('Offer card accept tapped', tag: 'OfferCard');
                  onAccept();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.text,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p14,
                  ),
                ),
                child: const Text('Accept'),
              ),
            if (onRelease != null && showRelease)
              FilledButton(
                onPressed: () {
                  AppLogger.i('Offer card release tapped', tag: 'OfferCard');
                  onRelease?.call();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.text,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p14,
                  ),
                ),
                child: const Text('Release Funds'),
              ),
            if (onRefund != null && showRefund)
              TextButton(
                onPressed: () {
                  AppLogger.i('Offer card refund tapped', tag: 'OfferCard');
                  onRefund?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: colors.danger,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p12,
                  ),
                ),
                child: const Text('Refund'),
              ),
          ] else ...[
            if (onWithdraw != null && isPending)
              OutlinedButton.icon(
                onPressed: () {
                  AppLogger.i('Offer card withdraw tapped', tag: 'OfferCard');
                  onWithdraw?.call();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.danger,
                  side: BorderSide(color: colors.danger.withValues(alpha: 0.5)),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p12,
                  ),
                ),
                icon: const Icon(Icons.close, size: AppDimens.iconSizeSmall),
                label: const Text('Withdraw'),
              ),
          ],
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
    final pills = AmberDuskTokens.widgetTheme.statusPills;
    return Container(
      padding: pills.smallPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(pills.radius),
      ),
      child: Text(
        label.toUpperCase(),
        style: pills.smallTextStyle.copyWith(color: color),
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
    _monitor
      ..startMonitoring(widget.deadline)
      ..addListener(_onMonitorUpdate);

    _pulseController = AnimationController(
      // Dramatic motion makes critical payment windows visible without custom timing.
      duration: AppMotion.dramatic,
      vsync: this,
    );
  }

  void _onMonitorUpdate() {
    if (!mounted) return;

    // Start/stop pulse animation based on urgency
    if (_monitor.shouldPulse && !_pulseController!.isAnimating) {
      unawaited(_pulseController!.repeat(reverse: true));
    } else if (!_monitor.shouldPulse && _pulseController!.isAnimating) {
      _pulseController!.stop();
      _pulseController!.value = 1.0;
    }

    setState(() {});
  }

  Color _getUrgencyColor(AmberDuskColorTokens colors) {
    switch (_monitor.urgencyLevel) {
      case UrgencyLevel.relaxed:
        return colors.success;
      case UrgencyLevel.urgent:
        return colors.warning;
      case UrgencyLevel.critical:
      case UrgencyLevel.expired:
        return colors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    const colors = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;
    final urgencyColor = _getUrgencyColor(colors);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p16,
        vertical: AppDimens.p8,
      ),
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
                  size: AppDimens.iconSizeSmall,
                  color: urgencyColor,
                ),
              );
            },
          ),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: Text(
              _monitor.isExpired
                  ? 'Payment window closed'
                  : 'Payment deadline: ${_monitor.countdownText ?? ''}',
              style: typography.chip.copyWith(color: urgencyColor),
            ),
          ),
          if (!_monitor.isExpired)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p8,
                vertical: AppDimens.p2,
              ),
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppDimens.r12),
              ),
              child: Text(
                _monitor.urgencyLevel == UrgencyLevel.critical
                    ? 'URGENT'
                    : _monitor.urgencyLevel == UrgencyLevel.urgent
                    ? 'SOON'
                    : 'PENDING',
                style: typography.chip.copyWith(color: urgencyColor),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _monitor
      ..removeListener(_onMonitorUpdate)
      ..dispose();
    super.dispose();
  }
}

/// Amber Dusk status color mapping for dashboard offer cards.
Color _offerStatusColor(OfferStatus status) {
  const colors = AmberDuskTokens.colors;
  switch (status) {
    case OfferStatus.pending:
      return colors.warning;
    case OfferStatus.accepted:
      return colors.success;
    case OfferStatus.rejected:
    case OfferStatus.withdrawn:
    case OfferStatus.unknown:
      return colors.danger;
  }
}
