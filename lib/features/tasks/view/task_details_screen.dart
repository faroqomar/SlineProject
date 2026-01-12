import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/features/profile/view/public_profile_screen.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/widgets/requests/requests_list_screen.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';
import 'package:sline_app/features/chat/view/chat_screen.dart'; // Added
import 'package:sline_app/core/utils/loading_utils.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart'; // Added

/// Shows details of a task with Glassmorphism design.
class TaskDetailsScreen extends StatefulWidget {
  final Task task;
  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  String _selectedPackageTier = 'Basic';

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final Task task = widget.task;
    final bool isTender = task.isTender;
    final bool isBooking = task.isBooking;

    final String? currentUserId = context.read<TaskViewModel>().currentUserId;
    final bool isOwner = currentUserId != null && currentUserId == task.userId;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: Column(
        children: [
          // --- Header ---
          GlassContainer(
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
                    color: colorScheme.text,
                    size: 20,
                  ),
                ),
                Text(
                  isBooking ? 'Booking Details' : 'Job Details',
                  style: AppTypography.h5.copyWith(color: colorScheme.text),
                ),
                Icon(Icons.share, color: colorScheme.text, size: 20),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PublicProfileScreen(userId: task.userId),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gold, width: 2),
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
                                  color: AppColors.lightTeal,
                                ),
                              ],
                            ),
                            Text(
                              'View Profile',
                              style: AppTypography.micro.copyWith(
                                color: AppColors.teal,
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

                  // Proposals Link (Owner of Tender)
                  if (isOwner && isTender)
                    GestureDetector(
                      onTap: () {
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
                        );
                      },
                      child: GlassContainer(
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
          GlassContainer(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimens.r30),
            ),
            padding: EdgeInsets.fromLTRB(
              AppDimens.p24,
              AppDimens.p16,
              AppDimens.p24,
              MediaQuery.of(context).padding.bottom + AppDimens.p16,
            ),
            child: Row(
              children: [
                if (!isOwner) ...[
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimens.r14),
                      border: Border.all(color: colorScheme.cardBorder),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: colorScheme.text,
                      ),
                      onPressed: () => _handleChatAction(
                        context,
                        task.id,
                        task.userId,
                        currentUserId,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.p12),
                ],
                Expanded(
                  child: AppButton(
                    text: _getButtonLabel(isOwner, isTender, isBooking),
                    onPressed: () => _handlePrimaryAction(
                      context,
                      isOwner,
                      isTender,
                      isBooking,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colorScheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppDimens.r14),
                    border: Border.all(color: colorScheme.cardBorder),
                  ),
                  child: Icon(Icons.favorite_border, color: colorScheme.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChatAction(
    BuildContext context,
    String taskId,
    String ownerId,
    String? currentUserId,
  ) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to chat.')),
      );
      return;
    }

    final chatVm = context.read<ChatViewModel>();
    try {
      LoadingUtils.show(context);
      final conversation = await chatVm.createOrGetConversation(
        taskId: taskId,
        user1Id: currentUserId,
        user2Id: ownerId,
      );

      if (!context.mounted) return;
      LoadingUtils.hide(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conversation),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      LoadingUtils.hide(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
    }
  }

  // --- Mock UI Helpers ---

  Widget _buildPackageSelector(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    const tiers = ['Basic', 'Standard', 'Premium'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.inputBackground,
        borderRadius: BorderRadius.circular(AppDimens.r14),
        border: Border.all(color: colorScheme.inputBorder),
      ),
      child: Row(
        children: tiers.map((tier) {
          final isSelected = _selectedPackageTier == tier;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPackageTier = tier),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppDimens.p10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimens.r10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    tier,
                    style: AppTypography.captionBold.copyWith(
                      color: isSelected
                          ? AppColors.offWhite
                          : colorScheme.textSecondary,
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
    final AppColorScheme colorScheme = context.colorScheme;
    // Real Data from Task
    String price = 'N/A';
    String delivery = 'N/A';
    String revisions = 'N/A';
    String desc = 'No description provided.';

    if (widget.task.packages != null &&
        widget.task.packages!.containsKey(_selectedPackageTier)) {
      final pkg = widget.task.packages![_selectedPackageTier];
      if (pkg != null) {
        price = '\$${pkg['price'] ?? '0'}';
        delivery = '${pkg['delivery'] ?? '0'} Days';
        revisions = '${pkg['revisions'] ?? '0'} Revisions';
        desc = pkg['description'] ?? '';
      }
    }

    return GlassContainer(
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
                style: AppTypography.h4.copyWith(color: AppColors.teal),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedPackageTier.toUpperCase(),
                  style: AppTypography.micro.copyWith(
                    color: AppColors.teal,
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
              color: colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: AppColors.teal),
              const SizedBox(width: 4),
              Text(
                delivery,
                style: AppTypography.captionBold.copyWith(
                  color: colorScheme.text,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.refresh, size: 14, color: AppColors.teal),
              const SizedBox(width: 4),
              Text(
                revisions,
                style: AppTypography.captionBold.copyWith(
                  color: colorScheme.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getButtonLabel(bool isOwner, bool isTender, bool isBooking) {
    if (isOwner) return 'Manage Task';
    if (isBooking) return 'Book $_selectedPackageTier';
    return 'Apply Now';
  }

  void _handlePrimaryAction(
    BuildContext context,
    bool isOwner,
    bool isTender,
    bool isBooking,
  ) {
    if (isOwner) {
      // Owner logic (maybe edit or view offers)
      return;
    }

    if (isBooking) {
      // Navigate to availability
      Navigator.of(context).pushNamed(
        '/availability',
        arguments: {
          'freelancerId': widget.task.userId,
          'taskId': widget.task.id,
          'packageTier': _selectedPackageTier,
          'packagePrice':
              widget.task.packages?[_selectedPackageTier]?['price'] ?? '0',
          'packageData': widget.task.packages?[_selectedPackageTier],
        },
      );
    } else {
      // Tender -> Open Proposal Sheet
      // For now, just push the RequestsListScreen with autoOpen (or we can implement the modal later)
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
      );
    }
  }
}
