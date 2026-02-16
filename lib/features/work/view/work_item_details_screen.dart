import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/work/viewmodels/work_item_details_view_model.dart';
import 'package:sline_app/features/work/view/widgets/submit_delivery_modal.dart';
import 'package:sline_app/features/work/view/widgets/request_extension_modal.dart';
import 'package:sline_app/features/work/models/change_request_model.dart';
import 'package:sline_app/features/work/models/extension_request_model.dart';

class WorkItemDetailsScreen extends StatelessWidget {
  final String id;
  final WorkItemType type;

  const WorkItemDetailsScreen({
    super.key,
    required this.id,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkItemDetailsViewModel(),
      child: _WorkItemDetailsContent(id: id, type: type),
    );
  }
}

class _WorkItemDetailsContent extends StatefulWidget {
  final String id;
  final WorkItemType type;

  const _WorkItemDetailsContent({required this.id, required this.type});

  @override
  State<_WorkItemDetailsContent> createState() =>
      _WorkItemDetailsContentState();
}

class _WorkItemDetailsContentState extends State<_WorkItemDetailsContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkItemDetailsViewModel>().loadData(
        widget.id,
        widget.type.name,
      );
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

        if (vm.workItem == null) {
          return const Scaffold(body: Center(child: Text('No details found')));
        }

        final isBooking = widget.type == WorkItemType.booking;
        final title = vm.title.isNotEmpty
            ? vm.title
            : (isBooking ? 'Booking' : 'Task');

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: context.colorScheme.phoneBackground,
            appBar: AppBar(
              title: Text(isBooking ? 'Booking' : 'Task'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Extensions'),
                  Tab(text: 'Contract'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildOverviewTab(vm, title),
                _buildExtensionsTab(vm),
                _buildContractTab(vm),
              ],
            ),
            bottomNavigationBar: _buildBottomActions(vm, context),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(WorkItemDetailsViewModel vm, String title) {
    if (vm.booking != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.h3.copyWith(color: context.colorScheme.text),
            ),
            const SizedBox(height: AppDimens.p24),
            _buildBookingSpecifics(vm),
            const SizedBox(height: AppDimens.p24),
            _buildUnifiedStatus(vm),
            const SizedBox(height: AppDimens.p24),
            _buildContractInfo(vm),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(color: context.colorScheme.text),
          ),
          const SizedBox(height: AppDimens.p24),
          _buildUnifiedStatus(vm),
          const SizedBox(height: AppDimens.p24),
          _buildContractInfo(vm),
        ],
      ),
    );
  }

  Widget _buildExtensionsTab(WorkItemDetailsViewModel vm) {
    if (vm.extensionRequests.isEmpty && vm.changeRequests.isEmpty) {
      return const Center(child: Text('No requests history'));
    }

    final allRequests = [
      ...vm.extensionRequests.map((e) => _ExtensionRequestItem(e)),
      ...vm.changeRequests.map((c) => _ChangeRequestItem(c)),
    ];
    // Sort by createdAt desc?

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.p16),
      itemCount: allRequests.length,
      itemBuilder: (context, index) {
        return allRequests[index];
      },
    );
  }

  Widget _buildContractTab(WorkItemDetailsViewModel vm) {
    final contract = vm.activeContract;
    if (contract == null) {
      return const Center(child: Text('No active contract'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contract Info', style: AppTypography.h3),
          const SizedBox(height: AppDimens.p16),
          _infoRow('Version', contract.version.toString()),
          _infoRow(
            'Effective Date',
            contract.createdAt.toString().split(' ')[0],
          ),
          const SizedBox(height: AppDimens.p16),
          Text('Snapshot Data', style: AppTypography.bodyLarge),
          const SizedBox(height: AppDimens.p8),
          ...contract.snapshot.entries.map(
            (e) => _infoRow(e.key, e.value.toString()),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildUnifiedStatus(WorkItemDetailsViewModel vm) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Row(
          children: [
            Text(
              'Status:',
              style: AppTypography.bodyLarge.copyWith(
                color: context.colorScheme.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppDimens.p8),
            Text(
              vm.status.name.toUpperCase(),
              style: AppTypography.bodyMedium.copyWith(
                color: context.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractInfo(WorkItemDetailsViewModel vm) {
    if (vm.activeContract == null) return const SizedBox.shrink();
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contract Info',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.p8),
            Text(
              'Price: \$${vm.workItem?.price}',
              style: AppTypography.bodyMedium,
            ),
            if (vm.workItem?.deadline != null)
              Text(
                'Deadline: ${vm.workItem!.deadline}',
                style: AppTypography.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSpecifics(WorkItemDetailsViewModel vm) {
    final booking = vm.booking!;
    final profile = vm.otherPartyProfile;
    final otherName = profile?['full_name'] ?? 'Unknown User';
    final otherAvatar = profile?['avatar_url'];

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: AppTypography.h4.copyWith(color: context.colorScheme.text),
            ),
            const SizedBox(height: AppDimens.p16),
            // Who
            Row(
              children: [
                SignedAvatar(
                  storagePathOrUrl: otherAvatar,
                  radius: 20,
                  placeholder: CircleAvatar(
                    radius: 20,
                    backgroundColor: context.colorScheme.primary,
                    child: Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.isFreelancer ? 'Booked by' : 'Provider',
                      style: AppTypography.bodySmall,
                    ),
                    Text(
                      otherName,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimens.p16),
            // When
            _infoRow('Scheduled', booking.scheduledAt?.toString() ?? 'Pending'),
            // Payment
            _infoRow('Payment', booking.paymentStatus.name.toUpperCase()),
            // Note
            if (booking.note != null && booking.note!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.p16),
              Text('Note', style: AppTypography.bodySmall),
              const SizedBox(height: AppDimens.p4),
              Text(
                booking.note!,
                style: AppTypography.bodyMedium.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomActions(
    WorkItemDetailsViewModel vm,
    BuildContext context,
  ) {
    // Determine actions based on role and status
    final canSubmit = vm.isFreelancer && vm.status == UnifiedWorkStatus.active;
    final canRequestExtension = vm.status == UnifiedWorkStatus.active;

    // Booking Acceptance logic
    final isPendingBooking =
        vm.workItem?.isBooking == true &&
        vm.status == UnifiedWorkStatus.pending;
    final canAccept = vm.isFreelancer && isPendingBooking;

    if (!canSubmit && !canRequestExtension && !canAccept) return null;

    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      color: context.colorScheme.cardBackground,
      child: Row(
        children: [
          if (canAccept) ...[
            Expanded(
              child: AppButton(
                text: 'Decline',
                isPrimary: false,
                backgroundColor: AppColors.lightRed,
                onPressed: () => vm.declineBooking(),
              ),
            ),
            const SizedBox(width: AppDimens.p16),
            Expanded(
              child: AppButton(
                text: 'Accept',
                onPressed: () => vm.acceptBooking(),
              ),
            ),
          ] else ...[
            if (canRequestExtension)
              Expanded(
                child: AppButton(
                  text: 'Extension',
                  isPrimary: false,
                  onPressed: () => _showExtensionModal(context, vm),
                ),
              ),
            if (canSubmit && canRequestExtension)
              const SizedBox(width: AppDimens.p16),
            if (canSubmit)
              Expanded(
                child: AppButton(
                  text: 'Submit Work',
                  onPressed: () => _showDeliveryModal(context, vm),
                ),
              ),
          ],
          if (vm.status == UnifiedWorkStatus.active) ...[
            if (canAccept)
              const SizedBox(width: AppDimens.p16), // Spacing if mixed
            Expanded(
              child: AppButton(
                text: 'Message',
                isPrimary: false,
                onPressed: () {
                  // TODO: Navigate to chat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat navigation not implemented yet'),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeliveryModal(BuildContext context, WorkItemDetailsViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SubmitDeliveryModal(
          isLoading: vm.isLoading,
          onSubmit: (note) async {
            await vm.submitDelivery(note);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showExtensionModal(BuildContext context, WorkItemDetailsViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: RequestExtensionModal(
          isLoading: vm.isLoading,
          onSubmit: (note, days) async {
            await vm.requestExtension(note, days);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _ExtensionRequestItem extends StatelessWidget {
  final ExtensionRequestModel req;
  const _ExtensionRequestItem(this.req);

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

class _ChangeRequestItem extends StatelessWidget {
  final ChangeRequestModel req;
  const _ChangeRequestItem(this.req);

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
