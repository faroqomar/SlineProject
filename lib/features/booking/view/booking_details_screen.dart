import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart';
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/features/management/view/order_management_panel.dart';
import 'package:sline_app/features/management/viewmodels/order_management_view_model.dart';

class BookingDetailsScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isProvider =
        context.read<BookingViewModel>().currentUserId == booking.providerId;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            _buildStatusBanner(context, booking.status),
            const SizedBox(height: AppDimens.p24),

            // Service Card (Task Info)
            _buildSectionHeader(context, 'Service'),
            const SizedBox(height: AppDimens.p12),
            GlassContainer(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimens.r12),
                    ),
                    child: Icon(Icons.work_outline, color: AppColors.teal),
                  ),
                  const SizedBox(width: AppDimens.p16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task #${booking.taskId?.substring(0, 8) ?? "N/A"}',
                          style: AppTypography.h6.copyWith(
                            color: colorScheme.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Booked on ${formatUtcToLocal(booking.createdAtUtc)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.p24),

            // Counterparty Info
            _buildSectionHeader(context, isProvider ? 'Client' : 'Provider'),
            const SizedBox(height: AppDimens.p12),
            GlassContainer(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Row(
                children: [
                  SignedAvatar(
                    // Ideally we fetch profiles, but for now we might only have IDs.
                    storagePathOrUrl: null,
                    radius: 24,
                  ),
                  const SizedBox(width: AppDimens.p16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isProvider ? 'Client' : 'Provider',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.text,
                          ),
                        ),
                        Text(
                          isProvider
                              ? 'ID: ${booking.clientId.substring(0, 8)}'
                              : 'ID: ${booking.providerId.substring(0, 8)}',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.teal,
                    ),
                    onPressed: () => _handleMessage(context, booking),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.p24),

            // Slot Details
            _buildSectionHeader(context, 'Schedule'),
            const SizedBox(height: AppDimens.p12),
            GlassContainer(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: AppColors.teal),
                  const SizedBox(width: AppDimens.p12),
                  Expanded(
                    child: Text(
                      'Slot ID: ${booking.slotId}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.p24),

            // Order Management
            ChangeNotifierProvider(
              create: (_) => OrderManagementViewModel(),
              child: OrderManagementPanel(
                entityId: booking.id,
                entityType: 'booking',
                currentUserId:
                    context.read<BookingViewModel>().currentUserId ?? '',
              ),
            ),

            const SizedBox(height: AppDimens.p24),

            // Actions
            if (isProvider && booking.status == BookingStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Reject',
                      isPrimary: false,
                      onPressed: () => _updateStatus(
                        context,
                        booking,
                        BookingStatus.canceled,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.p16),
                  Expanded(
                    child: AppButton(
                      text: 'Confirm',
                      onPressed: () => _updateStatus(
                        context,
                        booking,
                        BookingStatus.confirmed,
                      ),
                    ),
                  ),
                ],
              ),

            if (!isProvider && booking.status == BookingStatus.pending)
              AppButton(
                text: 'Cancel Booking',
                isPrimary: false,
                onPressed: () =>
                    _updateStatus(context, booking, BookingStatus.canceled),
              ),

            // --- Phase 1 Payment/Flow Actions ---

            // 1. Provider Actions
            if (isProvider) ...[
              // Accept Request (Funds held)
              if (booking.status == BookingStatus.paidRequestPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Decline',
                        isPrimary: false,
                        onPressed: () => context
                            .read<BookingViewModel>()
                            .declineBooking(booking.id),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p16),
                    Expanded(
                      child: AppButton(
                        text: 'Accept Job',
                        onPressed: () => context
                            .read<BookingViewModel>()
                            .acceptBooking(booking.id),
                      ),
                    ),
                  ],
                ),
              ],
              // Mark Delivered
              if (booking.status == BookingStatus.active) ...[
                AppButton(
                  text: 'Mark Delivered',
                  onPressed: () => context
                      .read<BookingViewModel>()
                      .markDelivered(booking.id),
                ),
              ],
            ],

            // 2. Client Actions
            if (!isProvider) ...[
              // Approve & Release (Funds released)
              if (booking.status == BookingStatus.delivered) ...[
                AppButton(
                  text: 'Approve & Release Funds',
                  onPressed: () => context
                      .read<BookingViewModel>()
                      .approveBooking(booking.id),
                ),
              ],
              // Dispute/Cancel (If needed)
              if (booking.status == BookingStatus.delivered) ...[
                const SizedBox(height: AppDimens.p12),
                Center(
                  child: TextButton(
                    onPressed: () {}, // TODO: Dispute Flow
                    child: Text(
                      'Report Issue',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.lightRed,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: AppTypography.h5.copyWith(color: context.colorScheme.text),
    );
  }

  Widget _buildStatusBanner(BuildContext context, BookingStatus status) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = AppColors.gold;
        text = 'Pending Confirmation';
        break;
      case BookingStatus.confirmed:
        color = AppColors.teal;
        text = 'Confirmed';
        break;
      case BookingStatus.completed:
        color = AppColors.mediumGrey;
        text = 'Completed';
        break;
      case BookingStatus.canceled:
        color = AppColors.lightRed;
        text = 'Canceled';
        break;
      case BookingStatus.noShow:
        color = AppColors.lightRed;
        text = 'No Show';
        break;
      case BookingStatus.inProgress:
        color = AppColors.teal;
        text = 'In Progress';
        break;
      case BookingStatus.declined:
        color = AppColors.lightRed;
        text = 'Declined';
        break;
      case BookingStatus.active:
        color = AppColors.teal;
        text = 'Active';
        break;
      case BookingStatus.paidRequestPending:
        color = AppColors.gold;
        text = 'Request Pending';
        break;
      case BookingStatus.delivered:
        color = AppColors.teal;
        text = 'Delivered (Review)';
        break;
      case BookingStatus.refunded:
        color = AppColors.mediumGrey;
        text = 'Refunded';
        break;
      case BookingStatus.expiredUnanswered:
        color = AppColors.mediumGrey;
        text = 'Expired';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: AppDimens.p12),
          Text(
            text,
            style: AppTypography.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMessage(
    BuildContext context,
    BookingModel booking,
  ) async {
    final vm = context.read<BookingViewModel>();
    final uid = vm.currentUserId;
    if (uid == null) return;

    LoadingUtils.show(context);
    final convo = await vm.contactProvider(booking, uid);
    if (!context.mounted) return;
    LoadingUtils.hide(context);

    if (convo != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)),
      );
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    BookingModel booking,
    BookingStatus status,
  ) async {
    final vm = context.read<BookingViewModel>();
    LoadingUtils.show(context);
    final success = await vm.updateBookingStatus(
      bookingId: booking.id,
      newStatus: status,
    );
    if (!context.mounted) return;
    LoadingUtils.hide(context);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Status updated')));
      Navigator.pop(context); // Refresh/Back
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update status')));
    }
  }
}
