import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../../models/activity_log.dart';

class ActivityFeedPreview extends StatelessWidget {
  final int? limit;

  const ActivityFeedPreview({super.key, this.limit});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    var activities = vm.activityFeed;

    if (limit != null && activities.length > limit!) {
      activities = activities.sublist(0, limit);
    }

    if (vm.isLoading && activities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Text(
          'No recent activity.',
          style: AppTypography.caption.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        return _ActivityRow(
          item: activities[index],
          isLast: index == activities.length - 1,
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityLog item;
  final bool isLast;

  const _ActivityRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final info = _mapActivityToInfo(item);
    final deepLinkService = context.read<DeepLinkService>();

    return InkWell(
      onTap: () => deepLinkService.handleActivity(context, item),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.inputBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  info.icon,
                  size: 16,
                  color: colorScheme.textSecondary,
                ),
              ),
              if (!isLast)
                Container(width: 1, height: 40, color: colorScheme.divider),
            ],
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        info.title,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatFriendlyTime(item.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: colorScheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.description,
                    style: AppTypography.caption.copyWith(
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ActivityInfo _mapActivityToInfo(ActivityLog log) {
    // Map event type to UI text and icon
    String title = 'Notification';
    String description = 'New activity';
    IconData icon = Icons.notifications_none;

    final type = log.eventType;
    final entity = log.entityType;

    if (entity == 'booking') {
      icon = Icons.calendar_today;
      if (type == 'created') {
        title = 'New Booking Request';
        description = 'You have a new booking request.';
      } else if (type == 'status_change') {
        final newStatus = log.metadata['new_status'];
        title = 'Booking $newStatus'; // e.g. Booking confirmed
        description = 'Booking status changed to $newStatus.';
        if (newStatus == 'confirmed') icon = Icons.check_circle_outline;
        if (newStatus == 'canceled') icon = Icons.cancel_outlined;
      }
    } else if (entity == 'task') {
      icon = Icons.assignment;
      if (type == 'status_change') {
        final newStatus = log.metadata['new_status'];
        description = 'Task status updated to $newStatus.';
        title = 'Task Update';
      }
    }

    return _ActivityInfo(title, description, icon);
  }
}

class _ActivityInfo {
  final String title;
  final String description;
  final IconData icon;

  _ActivityInfo(this.title, this.description, this.icon);
}
