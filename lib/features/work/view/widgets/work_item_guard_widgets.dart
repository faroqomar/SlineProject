import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:sline_app/features/work/models/change_request_model.dart';
import 'package:sline_app/features/work/models/extension_request_model.dart';

// ---------------------------------------------------------------------------
// Dispute / safety guard widgets extracted from WorkItemDetailsScreen
// ---------------------------------------------------------------------------

/// Shows dispute banner text: "Dispute under review" (open) or
/// "Work frozen -- in dispute" (active).
class DisputeBannerContent extends StatelessWidget {
  const DisputeBannerContent({
    super.key,
    required this.sourceType,
    required this.entityId,
    required this.safetyViewModel,
  });

  final String sourceType;
  final String entityId;
  final SafetyViewModel safetyViewModel;

  @override
  Widget build(BuildContext context) {
    Future<String?> statusFuture;
    final safetyVm = safetyViewModel;
    if (sourceType == 'booking') {
      statusFuture = safetyVm.getDisputeStatusForBooking(entityId);
    } else if (sourceType == 'direct_offer') {
      statusFuture = safetyVm.getDisputeStatusForDirectOffer(entityId);
    } else {
      statusFuture = safetyVm.getDisputeStatusForTask(entityId);
    }
    return FutureBuilder<String?>(
      future: statusFuture,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final text = status == 'active'
            ? 'Work frozen — in dispute.'
            : 'Dispute under review. Approve and release disabled.';
        return AppCardContainer(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppLayout.iconStandard,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: AppDimens.p8),
                Expanded(
                  child: Text(
                    text,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.colorScheme.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Wraps the Report Issue button: hidden when an open dispute exists.
class ReportIssueGuard extends StatelessWidget {
  const ReportIssueGuard({
    super.key,
    required this.sourceType,
    required this.entityId,
    required this.onReportIssue,
    required this.builder,
    required this.safetyViewModel,
    this.reserveSpace = false,
  });

  final String sourceType;
  final String entityId;
  final VoidCallback onReportIssue;
  final Widget Function(BuildContext, VoidCallback) builder;
  final SafetyViewModel safetyViewModel;
  final bool reserveSpace;

  @override
  Widget build(BuildContext context) {
    final safetyVm = safetyViewModel;
    final Future<bool> hasDisputeFuture;
    if (sourceType == 'booking') {
      hasDisputeFuture = safetyVm.hasOpenDisputeForBooking(entityId);
    } else if (sourceType == 'direct_offer') {
      hasDisputeFuture = safetyVm.hasOpenDisputeForDirectOffer(entityId);
    } else {
      hasDisputeFuture = safetyVm.hasOpenDisputeForTask(entityId);
    }
    return FutureBuilder<bool>(
      future: hasDisputeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _reservedGuardSpace();
        }
        final hasOpenDispute = snapshot.data ?? true;
        if (hasOpenDispute) return _reservedGuardSpace();
        return builder(context, onReportIssue);
      },
    );
  }

  Widget _reservedGuardSpace() {
    if (!reserveSpace) return const SizedBox.shrink();
    return const SizedBox(
      width: AppLayout.minTouchTarget,
      height: AppLayout.minTouchTarget,
    );
  }
}

/// Wraps the Review button: disabled while an open dispute exists for this
/// work item.
class ReviewWithDisputeGuard extends StatelessWidget {
  const ReviewWithDisputeGuard({
    super.key,
    required this.sourceType,
    required this.entityId,
    required this.onReview,
    required this.safetyViewModel,
    this.height,
  });

  final String sourceType;
  final String entityId;
  final VoidCallback onReview;
  final SafetyViewModel safetyViewModel;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final safetyVm = safetyViewModel;
    final Future<bool> hasDisputeFuture;
    if (sourceType == 'booking') {
      hasDisputeFuture = safetyVm.hasOpenDisputeForBooking(entityId);
    } else if (sourceType == 'direct_offer') {
      hasDisputeFuture = safetyVm.hasOpenDisputeForDirectOffer(entityId);
    } else {
      hasDisputeFuture = safetyVm.hasOpenDisputeForTask(entityId);
    }

    return FutureBuilder<bool>(
      future: hasDisputeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppButton(
            text: 'Checking…',
            onPressed: null,
            height: height,
          );
        }
        final hasOpenDispute = snapshot.data ?? true;
        return AppButton(
          text: 'Review',
          onPressed: hasOpenDispute ? null : onReview,
          icon: Icons.rate_review_outlined,
          height: height,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Extension / Change request list items
// ---------------------------------------------------------------------------

/// Card for an extension request entry in the Extensions tab.
class ExtensionRequestItem extends StatelessWidget {
  final ExtensionRequestModel req;
  const ExtensionRequestItem(this.req, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: const Text('Extension Request'),
        subtitle: Text(
          '${req.reason} (+${_calculateDays(req.newDeadline)} days)',
        ),
        trailing: Text(req.status),
      ),
    );
  }

  int _calculateDays(DateTime newDeadline) {
    return newDeadline.difference(DateTime.now()).inDays; // Rough estimate
  }
}

/// Card for a change request entry in the Extensions tab.
class ChangeRequestItem extends StatelessWidget {
  final ChangeRequestModel req;
  const ChangeRequestItem(this.req, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.edit_note),
        title: const Text('Change Request'),
        subtitle: Text(req.description ?? 'No description'),
        trailing: Text(req.status),
      ),
    );
  }
}
