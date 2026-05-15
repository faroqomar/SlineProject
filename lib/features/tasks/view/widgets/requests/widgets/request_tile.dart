import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/features/favorites/models/favorites_mutation_result.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/proposals/routes/proposal_payment_route.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/view/widgets/expiration_countdown.dart';
import 'package:sline_app/features/tasks/view/widgets/payment_status_badge.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';

/// One row/tile for a TaskRequest in the offers list.
/// Add-to-favorites uses FavoritesViewModel only (MVVM; no direct service).
///
/// Phase 3.5: Enhanced with error recovery UI for payment failures:
/// - Retry Payment button for failed/unpaid payments
/// - Cancel Award action with confirmation
/// - Error display with color coding and actionable buttons
/// - Payment deadline countdown with warning states
class RequestTile extends StatelessWidget {
  final TaskRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isOwner;
  final bool isLoading;

  /// FavoritesViewModel from app-level provider. Required for add-to-favorites when !isOwner.
  final FavoritesViewModel? favoritesVM;

  /// When set, favorite button is hidden for the current user's own offer (self-favorite guard).
  final String? viewerUserId;

  /// Error message from ViewModel for this specific tile
  final String? errorMessage;

  /// Called when user taps "Try Again" on a retryable error
  final VoidCallback? onRetryError;

  /// Called when user dismisses an error
  final VoidCallback? onDismissError;

  /// TaskRequestsViewModel for cancel award operation
  final TaskRequestsViewModel? viewModel;

  const RequestTile({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
    required this.isOwner,
    this.favoritesVM,
    this.viewerUserId,
    this.isLoading = false,
    this.errorMessage,
    this.onRetryError,
    this.onDismissError,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = PriceFormatter.formatPrice(request.price.toDouble());
    final isExpired = request.isExpired;
    final hasPaymentError = _hasPaymentError();
    const amberColors = AmberDuskTokens.colors;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;

    // Disable actions for expired bids
    final canAct =
        request.isPending &&
        !isExpired &&
        onAccept != null &&
        onReject != null &&
        !isLoading;

    return Card(
      key: Key('request_tile_${request.id}'),
      color: cardTheme.panel.background,
      shadowColor: amberColors.page,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.spacing.taskCardRadius,
        ),
        side: hasPaymentError
            ? BorderSide(
                color: amberColors.danger,
                width: AppDimens.hairlineDivider,
              )
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p16,
              vertical: AppDimens.p8,
            ),
            title: Row(
              children: [
                Text(
                  priceText,
                  style: AmberDuskTokens.typography.moneyMedium.copyWith(
                    color: amberColors.primary,
                  ),
                ),
                const SizedBox(width: AppDimens.p8),
                // Show expiration badge for pending bids (only when not expired yet)
                if (request.isPending && !isExpired)
                  ExpirationBadge(
                    expirationTime: request.expirationTime,
                  ),
                // Show expired badge for expired bids
                if (isExpired)
                  Chip(
                    label: Text(
                      'Expired',
                      style: AmberDuskTokens.typography.chip.copyWith(
                        color: amberColors.text,
                      ),
                    ),
                    backgroundColor: amberColors.surfaceRaised,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            subtitle: _buildSubtitle(context),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isOwner &&
                    favoritesVM != null &&
                    request.bidderId != viewerUserId)
                  Consumer<FavoritesViewModel>(
                    builder: (context, vm, _) {
                      final pending = vm.isPending(request.bidderId);
                      return IconButton(
                        key: Key(
                          'request_tile_add_favorite_${request.bidderId}',
                        ),
                        tooltip: pending ? null : 'Add to favorites',
                        icon: pending
                            ? const SizedBox(
                                width: AppDimens.p24,
                                height: AppDimens.p24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.favorite_border),
                        onPressed: pending
                            ? null
                            : () => _handleAddFavorite(context),
                      );
                    },
                  ),
                if (isOwner && isLoading)
                  const SizedBox(
                    width: AppDimens.p24,
                    height: AppDimens.p24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                // Action buttons - disabled for expired bids
                if (isOwner && canAct) ...[
                  IconButton(
                    tooltip: 'Award',
                    icon: Icon(Icons.check_circle, color: amberColors.forest),
                    onPressed: onAccept,
                  ),
                  IconButton(
                    tooltip: 'Reject',
                    icon: Icon(Icons.cancel, color: amberColors.danger),
                    onPressed: onReject,
                  ),
                ],
                // Show payment status badge for accepted bids (both owner and bidder views)
                if (!canAct && !isLoading && request.isAccepted)
                  PaymentStatusBadge(
                    status: request.paymentStatus,
                    deadline: request.paymentDeadline,
                    showDeadline: request.isPendingPayment,
                  ),
              ],
            ),
            titleTextStyle: AmberDuskTokens.typography.body.copyWith(
              color: amberColors.text,
            ),
            subtitleTextStyle: AmberDuskTokens.typography.bodySmall.copyWith(
              color: amberColors.muted,
            ),
          ),
          // Payment Recovery Actions - Phase 3.5
          if (request.isAccepted && request.isPendingPayment && isOwner)
            _buildPaymentRecoveryActions(context),
          // Error Display with Recovery Options - Phase 3.5
          if (errorMessage != null && errorMessage!.isNotEmpty)
            _buildErrorDisplay(context),
        ],
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final daysText = '${request.days} days';
    final statusLabel = _getStatusLabel();
    const amberColors = AmberDuskTokens.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '$daysText • $statusLabel',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AmberDuskTokens.typography.bodySmall.copyWith(
              color: amberColors.muted,
            ),
          ),
        ),
        if (request.isPending && !request.isExpired) ...[
          const SizedBox(width: AppDimens.p8),
          // Detailed countdown for pending bids
          ExpirationCountdown(
            expirationTime: request.expirationTime,
            size: CountdownSize.small,
            showIcon: false,
            labelPrefix: 'Expires in',
          ),
        ],
      ],
    );
  }

  String _getStatusLabel() {
    if (isLoading) return 'Processing...';

    // For accepted bids, show payment-aware status
    if (request.isAccepted) {
      switch (request.paymentStatus) {
        case PaymentStatus.unpaid:
          return 'Accepted • Awaiting Payment';
        case PaymentStatus.held:
          return 'Active • Escrow Funded';
        case PaymentStatus.released:
          return 'Completed • Paid';
        case PaymentStatus.refunded:
          return 'Canceled • Refunded';
      }
    }

    return request.status.name;
  }

  /// Builds payment recovery actions for accepted but unpaid bids
  Widget _buildPaymentRecoveryActions(BuildContext context) {
    final isDeadlineNear = _isDeadlineNear();
    final isExpired = _isPaymentDeadlineExpired();
    const amberColors = AmberDuskTokens.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p16,
        0,
        AppDimens.p16,
        AppDimens.p12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment deadline countdown with warning
          if (request.paymentDeadline != null && !isExpired)
            _buildPaymentDeadlineWarning(isDeadlineNear),

          // Action buttons row
          Wrap(
            spacing: AppDimens.p8,
            runSpacing: AppDimens.p8,
            children: [
              // Retry Payment button
              if (!isExpired)
                ElevatedButton.icon(
                  key: Key('retry_payment_btn_${request.id}'),
                  onPressed: isLoading
                      ? null
                      : () => _handleRetryPayment(context),
                  icon: isLoading
                      ? const SizedBox(
                          width: AppDimens.iconSizeSmall,
                          height: AppDimens.iconSizeSmall,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.payment,
                          size: AppDimens.iconSizeSmall,
                        ),
                  label: Text(isLoading ? 'Opening...' : 'Pay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDeadlineNear
                        ? amberColors.danger
                        : amberColors.primary,
                    foregroundColor: amberColors.textInverse,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p12,
                      vertical: AppDimens.p8,
                    ),
                    textStyle: AppTypography.captionBold,
                  ),
                ),

              // Cancel Award button
              OutlinedButton.icon(
                key: Key('cancel_award_btn_${request.id}'),
                onPressed: isLoading ? null : () => _handleCancelAward(context),
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: AppDimens.iconSizeSmall,
                ),
                label: const Text('Cancel Award'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: amberColors.muted,
                  side: BorderSide(color: amberColors.surfaceRaised),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p12,
                    vertical: AppDimens.p8,
                  ),
                  textStyle: AppTypography.captionBold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds payment deadline warning widget
  Widget _buildPaymentDeadlineWarning(bool isDeadlineNear) {
    final remaining = request.paymentDeadline!.difference(DateTime.now());
    final hoursLeft = remaining.inHours;
    final minutesLeft = remaining.inMinutes.remainder(60);

    String timeText;
    if (hoursLeft > 0) {
      timeText =
          '$hoursLeft:${minutesLeft.toString().padLeft(2, '0')} hours left';
    } else {
      timeText = '$minutesLeft minutes left';
    }

    const amberColors = AmberDuskTokens.colors;
    final color = isDeadlineNear ? amberColors.danger : amberColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p8),
      child: Row(
        children: [
          Icon(
            isDeadlineNear ? Icons.warning_rounded : Icons.access_time,
            size: AppDimens.p14,
            color: color,
          ),
          const SizedBox(width: AppDimens.p4),
          Text(
            isDeadlineNear
                ? 'URGENT: $timeText'
                : 'Payment deadline: $timeText',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds error display with recovery options
  Widget _buildErrorDisplay(BuildContext context) {
    final isRetryable = viewModel?.isRetryableError(errorMessage) ?? false;
    final isCritical = _isCriticalError();
    const amberColors = AmberDuskTokens.colors;
    final errorColor = isCritical ? amberColors.danger : amberColors.warning;

    AppLogger.d(
      'request_tile_error_visible',
      tag: 'RequestTile',
      json: {'retryable': isRetryable, 'critical': isCritical},
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimens.p12,
        0,
        AppDimens.p12,
        AppDimens.p12,
      ),
      padding: const EdgeInsets.all(AppDimens.p12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.r8),
        border: Border.all(color: errorColor.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCritical ? Icons.error : Icons.warning_amber_rounded,
                size: AppDimens.iconSizeSmall,
                color: errorColor,
              ),
              const SizedBox(width: AppDimens.p8),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    color: errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (isRetryable || onDismissError != null) ...[
            const SizedBox(height: AppDimens.p8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isRetryable && onRetryError != null)
                  TextButton.icon(
                    key: Key('retry_error_btn_${request.id}'),
                    onPressed: onRetryError,
                    icon: const Icon(
                      Icons.refresh,
                      size: AppDimens.iconSizeSmall,
                    ),
                    label: const Text('Try Again'),
                    style: TextButton.styleFrom(
                      foregroundColor: errorColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p8,
                      ),
                    ),
                  ),
                if (onDismissError != null) ...[
                  const SizedBox(width: AppDimens.p8),
                  TextButton(
                    key: Key('dismiss_error_btn_${request.id}'),
                    onPressed: onDismissError,
                    style: TextButton.styleFrom(
                      foregroundColor: amberColors.muted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p8,
                      ),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Returns true if payment deadline is approaching (less than 1 hour)
  bool _isDeadlineNear() {
    if (request.paymentDeadline == null) return false;
    final remaining = request.paymentDeadline!.difference(DateTime.now());
    return remaining.inHours < 1 && !remaining.isNegative;
  }

  /// Returns true if payment deadline has expired
  bool _isPaymentDeadlineExpired() {
    if (request.paymentDeadline == null) return false;
    return DateTime.now().isAfter(request.paymentDeadline!);
  }

  /// Returns true if there's a payment-related error
  bool _hasPaymentError() {
    if (errorMessage == null) return false;
    final msg = errorMessage!.toLowerCase();
    return msg.contains('payment') ||
        msg.contains('deadline expired') ||
        msg.contains('escrow');
  }

  /// Returns true for critical errors (payment failed, expired, etc.)
  bool _isCriticalError() {
    if (errorMessage == null) return false;
    final msg = errorMessage!.toLowerCase();
    return msg.contains('failed') ||
        msg.contains('expired') ||
        msg.contains('error') ||
        msg.contains('rejected');
  }

  /// Opens payment screen for retry
  Future<void> _handleRetryPayment(BuildContext context) async {
    AppLogger.i('request_tile_retry_payment_tapped', tag: 'RequestTile');

    final summary = ProposalPaymentSummary(
      requestId: request.id,
      taskId: request.taskId,
      taskTitle: request.taskTitle ?? 'Task',
      freelancerName: request.bidderName ?? 'Freelancer',
      amount: request.price.toDouble(), // DB stores price in IQD
      paymentDeadline: request.paymentDeadline,
    );

    await openProposalPayment(
      context,
      summary: summary,
      launcherSource: 'request_tile_retry',
    );
  }

  /// Shows confirmation dialog and cancels the award
  Future<void> _handleCancelAward(BuildContext context) async {
    AppLogger.i('request_tile_cancel_award_tapped', tag: 'RequestTile');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        const amberColors = AmberDuskTokens.colors;
        return AlertDialog(
          backgroundColor: amberColors.background,
          title: Text(
            'Cancel Award?',
            style: AppTypography.h5.copyWith(color: amberColors.text),
          ),
          content: Text(
            'This returns the task to open status and notifies the freelancer.',
            style: AppTypography.bodyMedium.copyWith(color: amberColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Award'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: amberColors.danger,
                foregroundColor: amberColors.textInverse,
                textStyle: AppTypography.captionBold,
              ),
              child: const Text('Cancel Award'),
            ),
          ],
        );
      },
    );

    if ((confirmed ?? false) && context.mounted) {
      AppLogger.i('request_tile_cancel_award_confirmed', tag: 'RequestTile');

      final success = await viewModel?.cancelAwardedOffer(request.id);

      if (context.mounted && (success ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Award cancelled successfully'),
            backgroundColor: AmberDuskTokens.colors.forest,
          ),
        );
      }
    } else {
      AppLogger.d('request_tile_cancel_award_dismissed', tag: 'RequestTile');
    }
  }

  /// Add bidder to favorites via ViewModel (typed result).
  Future<void> _handleAddFavorite(BuildContext context) async {
    final vm = favoritesVM;
    if (vm == null) return;
    final result = await vm.add(request.bidderId);
    if (!context.mounted) return;
    switch (result) {
      case FavoritesMutationResult.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
      case FavoritesMutationResult.duplicate:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Already in favorites')));
      case FavoritesMutationResult.skipped:
        // Already in progress; no snackbar (button is disabled via Consumer).
        break;
      case FavoritesMutationResult.unauthenticated:
      case FavoritesMutationResult.forbidden:
      case FavoritesMutationResult.failure:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.error ?? 'Could not add. Please try again.'),
          ),
        );
    }
  }
}
