import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/account_guard_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/features/booking/view/payment_checkout_screen.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart'; // Added
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/management/models/work_log_scope.dart';
import 'package:sline_app/features/management/view/widgets/order_management_section.dart';
import 'package:sline_app/features/profile/view/widgets/profile_preview_modal.dart';
import 'package:sline_app/features/proposals/view/proposals_list_screen.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';

/// Shows task details with solid SLine surfaces and MVVM-controlled actions.
class TaskDetailsScreen extends StatefulWidget {
  final Task task;
  final bool showProposalsInitially;

  const TaskDetailsScreen({
    super.key,
    required this.task,
    this.showProposalsInitially = false,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  String _selectedPackageTier = 'Basic';

  @override
  void initState() {
    super.initState();
    if (widget.showProposalsInitially) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openProposals();
      });
    }
  }

  void _openProposals() {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RequestsListScreen(
            taskId: widget.task.id,
            autoOpenSubmitSheet: false, // Just list
            isTender: true,
            isOwner: true,
            budget: widget.task.budget.toString(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;
    final task = widget.task;
    final isTender = task.isTender;
    final isBooking = task.isBooking;

    final currentUserId = context.read<TaskViewModel>().currentUserId;
    final isOwner = currentUserId != null && currentUserId == task.userId;

    return Scaffold(
      backgroundColor: amberColors.page,
      body: Column(
        children: [
          // --- Header ---
          AppCardContainer(
            borderRadius: BorderRadius.zero,
            padding: EdgeInsets.fromLTRB(
              AppDimens.p24,
              MediaQuery.of(context).padding.top + AppDimens.p16,
              AppDimens.p24,
              AppDimens.p16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: amberColors.text,
                    size: 20,
                  ),
                ),
                Text(
                  isBooking ? 'Booking Details' : 'Job Details',
                  style: AppTypography.h5.copyWith(color: amberColors.text),
                ),
                Icon(Icons.share, color: amberColors.text, size: 20),
              ],
            ),
          ),

          // --- Scrollable Content ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    task.title,
                    style: AppTypography.h3.copyWith(color: colorScheme.text),
                  ),
                  const SizedBox(height: AppDimens.p16),

                  // Author
                  GestureDetector(
                    onTap: () {
                      showProfilePreview(context, task.userId);
                    },
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: amberColors.warning,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: SignedAvatar(
                            storagePathOrUrl: task.userAvatar,
                            radius: 20,
                          ),
                        ),
                        const SizedBox(width: AppDimens.p12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  task.userName ?? 'Unknown User',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.text,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: amberColors.success,
                                ),
                              ],
                            ),
                            Text(
                              'View Profile',
                              style: AppTypography.micro.copyWith(
                                color: amberColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.p24),

                  // Packages (Booking Only)
                  if (isBooking) ...[
                    _buildPackageSelector(context),
                    const SizedBox(height: AppDimens.p16),
                    _buildPackageDetails(context),
                    const SizedBox(height: AppDimens.p24),
                  ],

                  // Description
                  Text(
                    task.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p24),

                  // Images
                  if (task.imagePaths.isNotEmpty) ...[
                    SignedImage(
                      storagePathOrUrl: task.imagePaths.first,
                      width: double.infinity,
                      height: 200,
                      borderRadius: AppDimens.r16,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: AppDimens.p24),
                  ],

                  // Order Management (Notes & Timeline)
                  if (currentUserId != null)
                    OrderManagementSection(
                      padding: const EdgeInsets.only(bottom: AppDimens.p24),
                      scope: WorkLogScope(
                        entityId: task.id,
                        entityType: 'task',
                      ),
                      currentUserId: currentUserId,
                    ),

                  // Proposals Link (Owner of Tender)
                  if (isOwner && isTender)
                    GestureDetector(
                      onTap: () {
                        unawaited(
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RequestsListScreen(
                                taskId: task.id,
                                autoOpenSubmitSheet: false,
                                isTender: true,
                                isOwner: true,
                                budget: task.budget.toString(),
                              ),
                            ),
                          ),
                        );
                      },
                      child: AppCardContainer(
                        padding: const EdgeInsets.all(AppDimens.p16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'View Received Proposals',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.text,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: colorScheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --- Bottom Bar ---
          Container(
            padding: EdgeInsets.fromLTRB(
              AppDimens.p24,
              AppDimens.p16,
              AppDimens.p24,
              MediaQuery.of(context).padding.bottom + AppDimens.p16,
            ),
            decoration: BoxDecoration(
              color: amberColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.r30),
              ),
              border: Border(top: BorderSide(color: amberColors.surface)),
              boxShadow: AppDecorations.elevation(
                AmberDuskTokens.surfaces.nav.elevationLevel,
                isDark: amberColors.isDark,
              ),
            ),
            child: Row(
              children: [
                if (!isOwner) ...[
                  _buildBottomIconButton(
                    context,
                    icon: Icons.chat_bubble_outline,
                    color: amberColors.primary,
                    semanticsLabel: 'Start chat',
                    onPressed: () => _handleChatAction(
                      context,
                      task.id,
                      task.userId,
                      currentUserId,
                    ),
                  ),
                  const SizedBox(width: AppDimens.p12),
                ],
                Expanded(
                  child: AppButton(
                    text: _getButtonLabel(isOwner, isTender, isBooking),
                    onPressed: _canTriggerPrimaryAction(isOwner, isBooking)
                        ? () async => _handlePrimaryAction(
                            context,
                            isOwner,
                            isTender,
                            isBooking,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                _buildBottomIconButton(
                  context,
                  icon: Icons.flag_outlined,
                  color: amberColors.danger,
                  semanticsLabel: 'Report task',
                  onPressed: () => _showReportTaskDialog(context, task.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReportTaskDialog(
    BuildContext context,
    String taskId,
  ) async {
    var draftReason = '';
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Task'),
        content: TextField(
          maxLines: 4,
          onChanged: (value) => draftReason = value,
          decoration: const InputDecoration(
            hintText: 'Describe the issue',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, draftReason.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (!context.mounted || reason == null || reason.isEmpty) return;

    final vm = context.read<SafetyViewModel>();
    final ok = await vm.submitReport(
      entityType: 'task',
      entityId: taskId,
      reason: reason,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Report submitted.' : (vm.error ?? 'Report failed.'),
        ),
      ),
    );
  }

  Future<void> _handleChatAction(
    BuildContext context,
    String taskId,
    String ownerId,
    String? currentUserId,
  ) async {
    final allowed = await context
        .read<AccountGuardService>()
        .canPerformSensitiveAction();
    if (!context.mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account is restricted. Please contact support.'),
        ),
      );
      return;
    }

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to chat.')),
      );
      return;
    }

    final chatVm = context.read<ChatViewModel>();
    final loader = LoadingUtils.show(context, debugLabel: 'task_chat');
    try {
      final conversation = await chatVm.createOrGetConversation(
        taskId: taskId,
        user1Id: currentUserId,
        user2Id: ownerId,
      );
      loader.close();

      // Handle double-tap or error (conversation is null)
      if (conversation == null) return;
      if (!context.mounted) return;

      unawaited(
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: conversation),
          ),
        ),
      );
    } on Exception catch (e) {
      AppLogger.e(
        'Failed to start chat for task=$taskId owner=$ownerId',
        tag: 'Task',
        error: e,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
    } finally {
      loader.close();
    }
  }

  // --- Mock UI Helpers ---

  Widget _buildBottomIconButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String semanticsLabel,
    required VoidCallback onPressed,
  }) {
    final amberColors = context.amberColors;
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: amberColors.surface,
          borderRadius: BorderRadius.circular(
            AmberDuskTokens.spacing.compactControlRadius,
          ),
          border: Border.all(color: amberColors.surfaceHighest),
        ),
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildPackageSelector(BuildContext context) {
    final amberColors = context.amberColors;
    const tiers = ['Basic', 'Standard', 'Premium'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: amberColors.surface,
        borderRadius: BorderRadius.circular(
          AmberDuskTokens.spacing.compactControlRadius,
        ),
        border: Border.all(color: amberColors.surfaceHighest),
      ),
      child: Row(
        children: tiers.map((tier) {
          final isSelected = _selectedPackageTier == tier;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPackageTier = tier),
              child: AnimatedContainer(
                duration: AmberDuskTokens.motion.activeState,
                curve: AmberDuskTokens.motion.stateCurve,
                padding: const EdgeInsets.symmetric(vertical: AppDimens.p10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? amberColors.primary
                      : AmberDuskColors.transparent,
                  borderRadius: BorderRadius.circular(
                    AmberDuskTokens.spacing.md,
                  ),
                  boxShadow: isSelected
                      ? AppDecorations.elevation(1, isDark: amberColors.isDark)
                      : [],
                ),
                child: Center(
                  child: Text(
                    tier,
                    style: AppTypography.captionBold.copyWith(
                      color: isSelected
                          ? amberColors.textInverse
                          : amberColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPackageDetails(BuildContext context) {
    final amberColors = context.amberColors;
    // Real Data from Task
    var price = 'N/A';
    var delivery = 'N/A';
    var revisions = 'N/A';
    var desc = 'No description provided.';

    if (widget.task.packages != null &&
        widget.task.packages!.containsKey(_selectedPackageTier)) {
      final pkg = widget.task.packages![_selectedPackageTier];
      if (pkg != null) {
        price = _formatPackagePrice(pkg['price']);
        delivery = '${pkg['delivery'] ?? '0'} Days';
        final revCount = pkg['revisions'] ?? 0;
        revisions = '$revCount ${revCount == 1 ? 'Revision' : 'Revisions'}';
        desc = pkg['description'] ?? '';
      }
    }

    return AppCardContainer(
      padding: const EdgeInsets.all(AppDimens.p20),
      borderRadius: BorderRadius.circular(AppDimens.r18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: AppTypography.h4.copyWith(color: amberColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: amberColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(
                    AmberDuskTokens.spacing.pillRadius,
                  ),
                ),
                child: Text(
                  _selectedPackageTier.toUpperCase(),
                  style: AppTypography.micro.copyWith(
                    color: amberColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p12),
          Text(
            desc,
            style: AppTypography.bodySmall.copyWith(
              color: amberColors.textSubtle,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: amberColors.primary),
              const SizedBox(width: 4),
              Text(
                delivery,
                style: AppTypography.captionBold.copyWith(
                  color: amberColors.text,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.refresh, size: 14, color: amberColors.primary),
              const SizedBox(width: 4),
              Text(
                revisions,
                style: AppTypography.captionBold.copyWith(
                  color: amberColors.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPackagePrice(Object? raw) {
    if (raw is num) return PriceFormatter.formatPrice(raw.toDouble());
    final parsed = double.tryParse(raw?.toString() ?? '');
    if (parsed == null) return PriceFormatter.formatPrice(0);
    return PriceFormatter.formatPrice(parsed);
  }

  String _getButtonLabel(bool isOwner, bool isTender, bool isBooking) {
    if (isOwner) return 'Manage Task';
    if (isBooking && widget.task.status != TaskStatus.open) {
      return 'Booking Unavailable';
    }
    if (isBooking) return 'Book $_selectedPackageTier';
    return 'Apply Now';
  }

  bool _canTriggerPrimaryAction(bool isOwner, bool isBooking) {
    if (isOwner) return false;
    if (isBooking) {
      return widget.task.status == TaskStatus.open;
    }
    return true;
  }

  Map<String, dynamic>? _selectedPackageData() {
    if (widget.task.packages == null) return null;
    return widget.task.packages![_selectedPackageTier] as Map<String, dynamic>?;
  }

  String? _selectedPackageId() {
    final packages = widget.task.packages;
    if (packages == null || !packages.containsKey(_selectedPackageTier)) {
      return null;
    }
    return _selectedPackageTier;
  }

  double _selectedBookingPrice() {
    final pkg = _selectedPackageData();
    final raw = pkg?['price'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? widget.task.budget;
  }

  int? _selectedDeliveryDays() {
    final pkg = _selectedPackageData();
    final raw = pkg?['delivery'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    bool isOwner,
    bool isTender,
    bool isBooking,
  ) async {
    final allowed = await context
        .read<AccountGuardService>()
        .canPerformSensitiveAction();
    if (!context.mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account is restricted. Please contact support.'),
        ),
      );
      return;
    }

    if (isOwner) {
      // Owner logic (maybe edit or view offers)
      return;
    }

    if (isBooking) {
      if (widget.task.status != TaskStatus.open) return;

      AppLogger.i(
        'Opening slotless booking checkout task=${widget.task.id} package=${_selectedPackageId() ?? 'none'}',
        tag: 'Task',
        json: <String, dynamic>{
          'task_id': widget.task.id,
          'provider_id': widget.task.userId,
          'package_id': _selectedPackageId(),
          'delivery_days': _selectedDeliveryDays(),
        },
      );
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentCheckoutScreen(
              providerId: widget.task.userId,
              taskId: widget.task.id,
              taskTitle: widget.task.title,
              price: _selectedBookingPrice(),
              packageTier: _selectedPackageId(),
              packageData: _selectedPackageData(),
              deliveryDays: _selectedDeliveryDays(),
              taskDeadline: widget.task.deadline,
            ),
          ),
        ),
      );
    } else {
      // Tender -> Open Proposal Sheet
      // For now, just push the RequestsListScreen with autoOpen (or we can implement the modal later)
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestsListScreen(
              taskId: widget.task.id,
              autoOpenSubmitSheet: true,
              isTender: true,
              isOwner: false,
              budget: widget.task.budget.toString(),
            ),
          ),
        ),
      );
    }
  }
}
