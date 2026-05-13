import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';

/// Lets the current user manage portfolio proof items from profile settings.
///
/// The screen keeps CRUD and storage uploads in [ProfileViewModel] while the
/// view renders Amber Dusk list, dialog, and destructive-action treatment.
class ManagePortfolioScreen extends StatefulWidget {
  /// Creates the manage portfolio route.
  const ManagePortfolioScreen({super.key});

  @override
  State<ManagePortfolioScreen> createState() => _ManagePortfolioScreenState();
}

class _ManagePortfolioScreenState extends State<ManagePortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().fetchPortfolio();
    });
  }

  void _showAddEditDialog(
    BuildContext context,
    ProfileViewModel vm, [
    Map<String, dynamic>? item,
  ]) {
    final isEditing = item != null;
    final titleController = TextEditingController(text: item?['title']);
    final descController = TextEditingController(text: item?['description']);
    String? localImagePath = item?['image_url'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final colorScheme = Theme.of(context).colorScheme;
          final amberColors = context.amberColors;
          // Local state for the dialog
          var isUploading = localImagePath == 'loading';

          return AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Text(
              isEditing ? 'Edit Item' : 'Add Item',
              style: AppTypography.h4.copyWith(color: colorScheme.onSurface),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: isUploading
                        ? null
                        : () async {
                            // Set loading state
                            setState(() {
                              localImagePath = 'loading'; // Temporary marker
                              isUploading = true;
                            });

                            try {
                              final path = await vm
                                  .pickAndUploadPortfolioImage();

                              // Critical: Add delay to let iOS picker fully cleanup
                              // This prevents race condition crash on iPhone
                              await Future.delayed(AppMotion.standard);

                              if (context.mounted) {
                                if (vm.portfolioUploadError != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(vm.portfolioUploadError!),
                                    ),
                                  );
                                }
                                setState(() {
                                  if (path != null) {
                                    localImagePath = path;
                                  } else {
                                    localImagePath =
                                        item?['image_url']; // Revert if cancelled
                                  }
                                  isUploading = false;
                                });
                              }
                            } on Exception catch (e, st) {
                              AppLogger.w(
                                'ManagePortfolioScreen: image upload failed',
                                tag: 'Profile',
                                error: e,
                                json: <String, dynamic>{
                                  'stack_trace': st.toString(),
                                },
                              );
                              // Keep upload feedback visible long enough before
                              // reverting the local preview on failure.
                              await Future.delayed(AppMotion.standard);
                              if (context.mounted) {
                                setState(() {
                                  localImagePath = item?['image_url'];
                                  isUploading = false;
                                });
                              }
                            }
                          },
                    child: Container(
                      height: AppDimens.managePortfolioImagePreviewHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : (localImagePath != null &&
                                localImagePath != 'loading')
                          // CRITICAL: Don't use SignedImage here to avoid iOS crash
                          // Just show a success indicator with the upload confirmation
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: AppDimens.emptyStateIconSize,
                                  color: amberColors.success,
                                ),
                                const SizedBox(height: AppDimens.p8),
                                Text(
                                  'Image uploaded!',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppDimens.p4),
                                Text(
                                  'Tap to change',
                                  style: AppTypography.micro.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: AppDimens.iconSizeLarge,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: AppDimens.p8),
                                Text(
                                  'Add Image',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.p16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppDimens.p16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;

                  if (isEditing) {
                    // Update uses explicit parameters (not a map)
                    await vm.updatePortfolioItem(
                      itemId: item['id'],
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                    );
                  } else {
                    // Add portfolio item
                    // Note: Image handling is done via pickAndUploadPortfolioImage first
                    // then the path is stored. For now, we just add without image if
                    // no image was picked in this flow.
                    final effectiveImagePath =
                        (localImagePath != null && localImagePath != 'loading')
                        ? localImagePath
                        : null;
                    await vm.addPortfolioItem(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      imagePath: effectiveImagePath,
                    );
                  }
                  if (context.mounted) Navigator.pop(dialogContext);
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProfileViewModel vm,
    String itemId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              vm.deletePortfolioItem(itemId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: context.amberColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: Consumer<ProfileViewModel>(
        builder: (context, vm, child) {
          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.p24,
                    topPadding + AppDimens.p24,
                    AppDimens.p24,
                    AppDimens.p16,
                  ),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: AppDimens.touchTarget,
                        child: IconButton(
                          tooltip: 'Back',
                          style: IconButton.styleFrom(
                            backgroundColor: amberColors.surface,
                            foregroundColor: amberColors.text,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimens.r12,
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                      const SizedBox(width: AppDimens.p16),
                      Text(
                        'Manage Portfolio',
                        style: AppTypography.h3.copyWith(
                          color: colorScheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (vm.isLoadingPortfolio)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (vm.portfolioItems.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: AppDimens.emptyStateIconSize,
                          color: colorScheme.textSecondary,
                        ),
                        const SizedBox(height: AppDimens.p16),
                        Text(
                          'No items yet',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = vm.portfolioItems[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p24,
                        vertical: AppDimens.p8,
                      ),
                      child: Dismissible(
                        key: Key(item['id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppDimens.p20),
                          decoration: BoxDecoration(
                            color: amberColors.dangerMuted,
                            borderRadius: BorderRadius.circular(AppDimens.r20),
                          ),
                          child: Icon(Icons.delete, color: amberColors.text),
                        ),
                        confirmDismiss: (direction) async {
                          _confirmDelete(context, vm, item['id']);
                          return false; // Handled by dialog
                        },
                        child: AppCardContainer(
                          padding: const EdgeInsets.all(AppDimens.p12),
                          borderRadius: BorderRadius.circular(AppDimens.r20),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppDimens.r12,
                                ),
                                child: Container(
                                  width: AppDimens.p80,
                                  height: AppDimens.p80,
                                  color: colorScheme.background,
                                  child: item['image_url'] != null
                                      ? SignedImage(
                                          storagePathOrUrl: item['image_url'],
                                          fit: BoxFit.cover,
                                          bucket: 'portfolio',
                                        )
                                      : Icon(
                                          Icons.image,
                                          color: colorScheme.textSecondary,
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppDimens.p16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? 'Untitled',
                                      style: AppTypography.h5.copyWith(
                                        color: colorScheme.text,
                                      ),
                                    ),
                                    if (item['description'] != null)
                                      Text(
                                        item['description'],
                                        style: AppTypography.bodySmall.copyWith(
                                          color: colorScheme.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit portfolio item',
                                icon: Icon(
                                  Icons.edit,
                                  color: amberColors.primary,
                                ),
                                onPressed: () =>
                                    _showAddEditDialog(context, vm, item),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: vm.portfolioItems.length),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final vm = context.read<ProfileViewModel>();
          _showAddEditDialog(context, vm);
        },
        backgroundColor: amberColors.primary,
        foregroundColor: amberColors.textInverse,
        label: Text(
          'Add Item',
          style: AppTypography.bodyMedium.copyWith(
            color: amberColors.textInverse,
          ),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
