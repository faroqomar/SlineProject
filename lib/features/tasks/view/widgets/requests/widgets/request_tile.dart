import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
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

    // Disable actions for expired bids
    final canAct =
        request.isPending &&
        !isExpired &&
        onAccept != null &&
        onReject != null &&
        !isLoading;

    return Card(
      key: Key('request_tile_${request.id}'),
      elevation: hasPaymentError ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasPaymentError
            ? BorderSide(
                color: AppColors.lightRed.withValues(alpha: 0.5),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Row(
              children: [
                Text(
                  priceText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                // Show expiration badge for pending bids (only when not expired yet)
                if (request.isPending && !isExpired)
                  ExpirationBadge(
                    expirationTime: request.expirationTime,
                    size: CountdownSize.small,
                  ),
                // Show expired badge for expired bids
                if (isExpired)
                  const Chip(
                    label: Text('Expired', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.grey,
                    labelStyle: TextStyle(color: Colors.white),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            subtitle: _buildSubtitle(),
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
                                width: 24,
                                height: 24,
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
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                // Action buttons - disabled for expired bids
                if (isOwner && canAct) ...[
                  IconButton(
                    tooltip: 'Award',
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: onAccept,
                  ),
                  IconButton(
                    tooltip: 'Reject',
                    icon: const Icon(Icons.cancel, color: Colors.red),
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

  Widget _buildSubtitle() {
    final daysText = '${request.days} days';
    final statusLabel = _getStatusLabel();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$daysText • $statusLabel'),
        if (request.isPending && !request.isExpired) ...[
          const SizedBox(width: 8),
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

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment deadline countdown with warning
          if (request.paymentDeadline != null && !isExpired)
            _buildPaymentDeadlineWarning(isDeadlineNear),

          // Action buttons row
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payment, size: 16),
                  label: Text(isLoading ? 'Opening...' : 'Pay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDeadlineNear
                        ? AppColors.lightRed
                        : AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // Cancel Award button
              OutlinedButton.icon(
                key: Key('cancel_award_btn_${request.id}'),
                onPressed: isLoading ? null : () => _handleCancelAward(context),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel Award'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkerGrey,
                  side: BorderSide(color: AppColors.mediumGrey),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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

    final color = isDeadlineNear ? AppColors.lightRed : AppColors.gold;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isDeadlineNear ? Icons.warning_rounded : Icons.access_time,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isDeadlineNear
                ? 'URGENT: $timeText'
                : 'Payment deadline: $timeText',
            style: TextStyle(
              fontSize: 12,
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
    final errorColor = isCritical ? AppColors.lightRed : Colors.orange;

    AppLogger.d(
      'Displaying error in RequestTile: $errorMessage (retryable=$isRetryable, critical=$isCritical)',
      tag: 'RequestTile',
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: errorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCritical ? Icons.error : Icons.warning_amber_rounded,
                size: 16,
                color: errorColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: TextStyle(
                    fontSize: 13,
                    color: errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (isRetryable || onDismissError != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isRetryable && onRetryError != null)
                  TextButton.icon(
                    key: Key('retry_error_btn_${request.id}'),
                    onPressed: onRetryError,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Try Again'),
                    style: TextButton.styleFrom(
                      foregroundColor: errorColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                if (onDismissError != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    key: Key('dismiss_error_btn_${request.id}'),
                    onPressed: onDismissError,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.mediumGrey,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
    AppLogger.i(
      'Retry payment clicked for request ${request.id}',
      tag: 'RequestTile',
    );

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
    AppLogger.i(
      'Cancel award clicked for request ${request.id}',
      tag: 'RequestTile',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Award?'),
        content: const Text(
          'This will return the task to open status and the freelancer will be notified. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Award'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Award'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      AppLogger.i(
        'User confirmed cancel award for request ${request.id}',
        tag: 'RequestTile',
      );

      final success = await viewModel?.cancelAwardedOffer(request.id);

      if (context.mounted && (success ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Award cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      AppLogger.d(
        'User cancelled the cancel award dialog for request ${request.id}',
        tag: 'RequestTile',
      );
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
