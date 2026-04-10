import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';

/// Offer status enum for display purposes.
enum OfferStatus { pending, accepted, declined }

/// A message bubble widget for displaying custom offers in chat.
///
/// Phase 5 redesign: replaced all hardcoded `AppColors.teal/gold/lightTeal/lightRed`
/// with semantic color tokens (`colorScheme.primary/warning/success/danger`).
/// Added haptic feedback on action buttons, full Semantics coverage for
/// accessibility, and consistent dimension tokens. View-layer only.
///
/// Phase 6 conversion: promoted from StatelessWidget to StatefulWidget to
/// support future interactive states. Added elevated card treatment with
/// `AppDecorations.elevation(2)` shadow and a status-driven 1.5px border
/// (gold for pending, green for accepted, muted red for declined) so the
/// offer card visually pops off the chat surface.
///
/// Supports both legacy (message-only) and direct offers (offer_id + lifecycle).
class OfferMessageBubble extends StatefulWidget {
  final String title;
  final String description;
  final String price;
  final String deliveryDays;
  final OfferStatus status;
  final bool isMine;
  final String time;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  /// Direct offer id (from payload). When set, lifecycle actions are shown.
  final String? offerId;

  /// Raw status from payload: sent, active, delivered, completed, rejected, canceled, refunded.
  final String? rawStatus;
  final VoidCallback? onCancel;
  final VoidCallback? onDeliver;
  final VoidCallback? onComplete;

  const OfferMessageBubble({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.deliveryDays,
    this.status = OfferStatus.pending,
    required this.isMine,
    required this.time,
    this.onAccept,
    this.onDecline,
    this.offerId,
    this.rawStatus,
    this.onCancel,
    this.onDeliver,
    this.onComplete,
  });

  @override
  State<OfferMessageBubble> createState() => _OfferMessageBubbleState();
}

/// State for [OfferMessageBubble].
///
/// Holds the build logic that was previously in the StatelessWidget. All field
/// references now go through `widget.*` to access the immutable parameters.
class _OfferMessageBubbleState extends State<OfferMessageBubble> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    // 85% max width — consistent with chat bubble proportions for offer cards
    final maxWidth = MediaQuery.of(context).size.width * 0.85;

    // Status-driven border color: gives immediate visual feedback on offer
    // state without the user needing to read the status chip.
    final borderColor = _statusBorderColor(colorScheme);

    return Semantics(
      label:
          'Direct offer: ${widget.title}, \$${widget.price}, '
          '${widget.deliveryDays} days delivery, '
          'status: ${_semanticStatus()}',
      child: Align(
        alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        // AnimatedContainer smoothly transitions shadow and border when the
        // offer status changes (e.g. pending -> accepted), using motion tokens.
        child: AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.curveStandard,
          width: maxWidth,
          margin: const EdgeInsets.symmetric(vertical: AppDimens.p8),
          decoration: BoxDecoration(
            // Semantic primary at 10% opacity — replaces hardcoded AppColors.teal
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimens.r20),
            // 1.5px status-driven border — thicker than the previous 1px to
            // emphasize the elevated card treatment and reinforce status color.
            border: Border.all(color: borderColor, width: 1.5),
            // Level 2 raised shadow — lifts the offer card above regular
            // message bubbles so it draws the user's eye immediately.
            boxShadow: AppDecorations.elevation(2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.r20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with badge and price
                Padding(
                  padding: const EdgeInsets.all(AppDimens.p16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Badge and Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Offer badge — semantic primary replaces hardcoded teal
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.p8,
                              vertical: AppDimens.p4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(AppDimens.r8),
                            ),
                            child: Text(
                              'CUSTOM OFFER',
                              style: AppTypography.micro.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Price — semantic primary replaces hardcoded teal
                          Text(
                            '\$${widget.price}',
                            style: AppTypography.h4.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.p12),

                      // Title
                      Text(
                        widget.title,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.text,
                        ),
                      ),
                      const SizedBox(height: AppDimens.p4),

                      // Description
                      Text(
                        widget.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimens.p12),

                      // Delivery time
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: AppLayout.iconTiny,
                            color: colorScheme.textSecondary,
                          ),
                          const SizedBox(width: AppLayout.spacingTight),
                          Text(
                            '${widget.deliveryDays} Days Delivery',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.p16),

                      // Action buttons or status
                      _buildActions(colorScheme),
                    ],
                  ),
                ),

                // Time stamp
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.p16,
                    0,
                    AppDimens.p16,
                    AppDimens.p8,
                  ),
                  child: Text(
                    widget.time,
                    style: AppTypography.micro.copyWith(
                      color: colorScheme.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the border color based on the current offer status.
  ///
  /// Uses semantic color tokens so the border adapts to light/dark mode:
  /// - pending  -> warning (gold)  — draws attention to actionable offers
  /// - accepted -> success (green) — positive confirmation
  /// - declined -> danger at 60%   — muted red, not as aggressive as full red
  Color _statusBorderColor(AppColorScheme colorScheme) {
    switch (widget.status) {
      case OfferStatus.pending:
        return colorScheme.warning;
      case OfferStatus.accepted:
        return colorScheme.success;
      case OfferStatus.declined:
        // 60% opacity — softens the rejected state so it doesn't feel alarming
        return colorScheme.danger.withValues(alpha: 0.6);
    }
  }

  /// Returns a human-readable status string for accessibility labels.
  String _semanticStatus() {
    if (widget.rawStatus != null) return widget.rawStatus!;
    switch (widget.status) {
      case OfferStatus.pending:
        return 'pending';
      case OfferStatus.accepted:
        return 'accepted';
      case OfferStatus.declined:
        return 'declined';
    }
  }

  /// Builds contextual action buttons or status chip based on offer lifecycle.
  ///
  /// Status-driven conditionals are intentionally complex — they map 1:1 to
  /// the direct offer lifecycle. Do NOT restructure; only change token usage.
  Widget _buildActions(AppColorScheme colorScheme) {
    final isSent =
        widget.rawStatus == 'sent' || widget.rawStatus == 'sent_unpaid';
    final isActive =
        widget.rawStatus == 'active' || widget.rawStatus == 'active_held';
    final isDelivered =
        widget.rawStatus == 'delivered' || widget.rawStatus == 'delivered_held';
    final isAcceptedPendingPayment =
        widget.rawStatus == 'accepted' || widget.rawStatus == 'accepted_unpaid';

    // Direct offer: accepted but not yet paid (client must pay from dashboard)
    if (isAcceptedPendingPayment && widget.offerId != null) {
      return _buildStatusChip(
        'Pending Payment',
        Icons.payment,
        colorScheme.warning, // semantic warning replaces hardcoded gold
      );
    }

    // Payment done, work in progress (escrow held)
    if (isActive && widget.offerId != null) {
      return _buildStatusChip(
        'Paid',
        Icons.check_circle,
        colorScheme.success, // semantic success replaces hardcoded lightTeal
      );
    }

    // Full lifecycle done (completed and payment released)
    final isCompletedPaid =
        widget.rawStatus == 'completed' ||
        widget.rawStatus == 'completed_released';
    if (isCompletedPaid) {
      return _buildStatusChip(
        'Completed \u2022 Paid',
        Icons.check_circle,
        colorScheme.success, // semantic success replaces hardcoded lightTeal
      );
    }

    final isEndState =
        widget.status != OfferStatus.pending ||
        widget.rawStatus == 'completed' ||
        widget.rawStatus == 'rejected' ||
        widget.rawStatus == 'canceled' ||
        widget.rawStatus == 'refunded';

    if (isEndState) {
      final accepted =
          widget.status == OfferStatus.accepted ||
          widget.rawStatus == 'completed';
      // Accepted = success token, declined/canceled = danger token
      final stateColor = accepted ? colorScheme.success : colorScheme.danger;
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p12,
          vertical: AppDimens.p8,
        ),
        decoration: BoxDecoration(
          color: stateColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppDimens.r8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              accepted ? Icons.check_circle : Icons.cancel,
              size: AppDimens.iconSizeSmall,
              color: stateColor,
            ),
            const SizedBox(width: AppLayout.spacingTight),
            Text(
              accepted
                  ? 'Accepted'
                  : (widget.rawStatus == 'canceled' ? 'Canceled' : 'Declined'),
              style: AppTypography.captionBold.copyWith(color: stateColor),
            ),
          ],
        ),
      );
    }

    // Client actions (not mine)
    if (!widget.isMine) {
      if (isSent && (widget.onAccept != null || widget.onDecline != null)) {
        // Only render the row when at least one action is available.
        // Individual buttons are conditionally included so neither is shown
        // if its callback is null.
        return Row(
          children: [
            // Accept button — only rendered when onAccept is provided
            if (widget.onAccept != null) ...[
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Accept offer',
                  child: AppButton(
                    text: 'Accept',
                    height: AppLayout.buttonHeightSmall,
                    onPressed: () {
                      AppInteractionStates.hapticTap();
                      AppLogger.d(
                        'OfferMessageBubble: Accept tapped for offer ${widget.offerId ?? 'unknown'}',
                        tag: 'Chat',
                      );
                      widget.onAccept!();
                    },
                  ),
                ),
              ),
              if (widget.onDecline != null) const SizedBox(width: AppDimens.p8),
            ],
            // Decline button — only rendered when onDecline is provided
            if (widget.onDecline != null)
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Decline offer',
                  child: Container(
                    height: AppLayout.buttonHeightSmall,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimens.r14),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          AppInteractionStates.hapticTap();
                          AppLogger.d(
                            'OfferMessageBubble: Decline tapped for offer ${widget.offerId ?? 'unknown'}',
                            tag: 'Chat',
                          );
                          widget.onDecline!();
                        },
                        borderRadius: BorderRadius.circular(AppDimens.r14),
                        child: Center(
                          child: Text(
                            'Decline',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }
      if (isDelivered && widget.onComplete != null) {
        return SizedBox(
          width: double.infinity,
          child: Semantics(
            button: true,
            label: 'Approve and complete offer',
            child: AppButton(
              text: 'Approve & Complete',
              height: AppLayout.buttonHeightSmall,
              onPressed: () {
                AppInteractionStates.hapticTap();
                AppLogger.d(
                  'OfferMessageBubble: Complete tapped for offer ${widget.offerId ?? 'unknown'}',
                  tag: 'Chat',
                );
                widget.onComplete!();
              },
            ),
          ),
        );
      }
    }

    // Freelancer actions (mine)
    if (widget.isMine) {
      if (isSent && widget.onCancel != null) {
        return SizedBox(
          width: double.infinity,
          child: Semantics(
            button: true,
            label: 'Cancel offer',
            child: Container(
              height: AppLayout.buttonHeightSmall,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.r14),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    AppInteractionStates.hapticTap();
                    AppLogger.d(
                      'OfferMessageBubble: Cancel tapped for offer ${widget.offerId ?? 'unknown'}',
                      tag: 'Chat',
                    );
                    widget.onCancel!();
                  },
                  borderRadius: BorderRadius.circular(AppDimens.r14),
                  child: Center(
                    child: Text(
                      'Cancel Offer',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      if (isActive && widget.onDeliver != null) {
        return SizedBox(
          width: double.infinity,
          child: Semantics(
            button: true,
            label: 'Mark offer as delivered',
            child: AppButton(
              text: 'Mark Delivered',
              height: AppLayout.buttonHeightSmall,
              onPressed: () {
                AppInteractionStates.hapticTap();
                AppLogger.d(
                  'OfferMessageBubble: Deliver tapped for offer ${widget.offerId ?? 'unknown'}',
                  tag: 'Chat',
                );
                widget.onDeliver!();
              },
            ),
          ),
        );
      }
    }

    // Pending response (no action for this viewer)
    return _buildStatusChip(
      'Pending Response',
      Icons.schedule,
      colorScheme.warning, // semantic warning replaces hardcoded gold
    );
  }

  /// Status chip with semantic color and icon.
  Widget _buildStatusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimens.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimens.iconSizeSmall, color: color),
          const SizedBox(width: AppLayout.spacingTight),
          Text(label, style: AppTypography.captionBold.copyWith(color: color)),
        ],
      ),
    );
  }
}
