import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/features/work/viewmodels/work_item_details_view_model.dart';

class WorkItemDetailsScreen extends StatefulWidget {
  final String id;
  final WorkItemType type;

  const WorkItemDetailsScreen({
    super.key,
    required this.id,
    required this.type,
  });

  @override
  State<WorkItemDetailsScreen> createState() => _WorkItemDetailsScreenState();
}

class _WorkItemDetailsScreenState extends State<WorkItemDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkItemDetailsViewModel>().loadItem(widget.id, widget.type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkItemDetailsViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text(vm.error!)),
          );
        }

        final isBooking = widget.type == WorkItemType.booking;
        final title = vm.title ?? 'Work Item';
        // Fallback or specific data

        return Scaffold(
          backgroundColor: context.colorScheme.phoneBackground,
          appBar: AppBar(
            title: Text(isBooking ? 'Booking' : 'Order'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(title),
                const SizedBox(height: AppDimens.p24),
                _buildUnifiedStatus(vm),
                const SizedBox(height: AppDimens.p24),
                // TODO: Add detailed sections (Requirements, Timeline, etc.)
                // For MVP Phase 1 Unified Screen, start with basic info.
                _buildActionCenter(vm),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: AppTypography.h3.copyWith(color: context.colorScheme.text),
    );
  }

  Widget _buildUnifiedStatus(WorkItemDetailsViewModel vm) {
    // Display status nicely
    // Reuse GlassContainer logic
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Text(
          'Status: ${vm.booking?.status.name ?? vm.task?.status.name}',
        ),
      ),
    );
  }

  Widget _buildActionCenter(WorkItemDetailsViewModel vm) {
    // Buttons based on status
    return Column(
      children: [
        if (vm.booking?.status == BookingStatus.paidRequestPending)
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Decline',
                  isPrimary: false,
                  onPressed: vm.declineBooking,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(text: 'Accept', onPressed: vm.acceptBooking),
              ),
            ],
          ),
        // Add more unified actions
      ],
    );
  }
}
