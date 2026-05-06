import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/utils/status_presenter.dart';
import 'package:sline_app/core/utils/unified_cta_resolver.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/viewmodels/award_expiration_monitor.dart';

/// Dashboard-style offer card for inbox; lives in tasks feature.
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
        duration: const Duration(seconds: 2),
        vsync: this,
      );
      _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
      _pulseController!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final statusColor = StatusPresenter.offerStatusColor(widget.offer.status);
    final isPending = widget.offer.status == OfferStatus.pending;
    final isDark = colorScheme.isDark;

    return ScaleButton(
      onPressed: () {
        AppLogger.d('DashboardOfferCard tapped', tag: 'Cards');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.p16),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppDimens.r16),
          border: Border.all(color: colorScheme.cardBorder),
          boxShadow: AppDecorations.elevation(1, isDark: isDark),
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
                          size: AppDimens.iconSizeSmall,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppDimens.p8),
                        Text(
                          'OFFER',
                          style: AppTypography.captionBold.copyWith(
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: AppDimens.p8),
                        Flexible(
                          child: Text(
                            widget.offer.taskTitle ?? 'Unknown Task',
                            style: AppTypography.caption.copyWith(
                              color: colorScheme.textSecondary,
                              overflow: TextOverflow.ellipsis,
                            ),
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
              _PaymentDeadlineCountdown(
                deadline: widget.offer.paymentDeadline!,
              ),
            // ── HERO PRICE ZONE ─────────────────────────────────────
            // Phase 7 REDESIGN: Price is the #1 information — give it a
            // dedicated zone with h2 typography instead of burying it in
            // a 12px info chip. Days get their own badge.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p16,
                vertical: AppDimens.p16,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OFFER PRICE',
                          style: AppTypography.overline.copyWith(
                            color: colorScheme.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppDimens.p4),
                        Text(
                          PriceFormatter.formatPrice(
                            widget.offer.price.toDouble(),
                          ),
                          style: AppTypography.h2.copyWith(
                            color: colorScheme.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Days badge with info color
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p12,
                      vertical: AppDimens.p8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.infoMuted,
                      borderRadius: BorderRadius.circular(AppDimens.r12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${widget.offer.days}',
                          style: AppTypography.h4.copyWith(
                            color: colorScheme.info,
                          ),
                        ),
                        Text(
                          'DAYS',
                          style: AppTypography.micro.copyWith(
                            color: colorScheme.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── BIDDER SECTION ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + name + date row
                  Row(
                    children: [
                      if (widget.offer.bidderAvatar != null)
                        Padding(
                          padding: const EdgeInsets.only(right: AppDimens.p12),
                          child: SignedAvatar(
                            storagePathOrUrl: widget.offer.bidderAvatar,
                            // Phase 7 REDESIGN: avatarDefault (40px) for
                            // more personality, up from 20px radius
                            radius: AppLayout.avatarDefault / 2,
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
                              style: AppTypography.h6.copyWith(
                                color: colorScheme.text,
                              ),
                            ),
                            _buildDeadlineText(colorScheme),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Note block
                  if (widget.offer.note != null &&
                      widget.offer.note!.isNotEmpty) ...[
                    const SizedBox(height: AppDimens.p12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.p10),
                      decoration: BoxDecoration(
                        color: colorScheme.background.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                      ),
                      child: Text(
                        '"${widget.offer.note}"',
                        style: AppTypography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.textSecondary,
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
      ),
    );
  }

  Widget _buildDeadlineText(AppColorScheme colorScheme) {
    final text = Text(
      formatUtcToLocal(widget.offer.createdAt),
      style: AppTypography.caption.copyWith(color: colorScheme.textSecondary),
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
    final colorScheme = context.colorScheme;
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
                  foregroundColor: colorScheme.danger,
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
                  backgroundColor: colorScheme.primary,
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
                  backgroundColor: colorScheme.warning,
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
                  backgroundColor: colorScheme.primary,
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
                  backgroundColor: colorScheme.primary,
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
                  backgroundColor: colorScheme.primary,
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
                  foregroundColor: colorScheme.danger,
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
                  foregroundColor: colorScheme.danger,
                  side: BorderSide(
                    color: colorScheme.danger.withValues(alpha: 0.5),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p8,
        vertical: AppDimens.p4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.captionBold.copyWith(color: color, fontSize: 10),
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
      // Phase 7: replaced hardcoded 1000ms with dramatic (800ms) + standard
      // curve for a slightly faster pulse that feels more urgent
      duration: AppMotion.dramatic,
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
        return colorScheme.success;
      case UrgencyLevel.urgent:
        return colorScheme.warning;
      case UrgencyLevel.critical:
      case UrgencyLevel.expired:
        return colorScheme.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final urgencyColor = _getUrgencyColor(colorScheme);

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
              style: AppTypography.captionBold.copyWith(color: urgencyColor),
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
