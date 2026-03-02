import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/core/widgets/signed_image.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';

class ManagePortfolioScreen extends StatefulWidget {
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
          // Local state for the dialog
          bool isUploading = localImagePath == 'loading';

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
                              final path = await vm.pickAndUploadPortfolioImage(
                                context,
                              );

                              // Critical: Add delay to let iOS picker fully cleanup
                              // This prevents race condition crash on iPhone
                              await Future.delayed(
                                const Duration(milliseconds: 300),
                              );

                              if (context.mounted) {
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
                            } catch (e) {
                              // Also delay on error path
                              await Future.delayed(
                                const Duration(milliseconds: 300),
                              );
                              if (context.mounted) {
                                setState(() {
                                  localImagePath =
                                      item?['image_url']; // Revert on error
                                  isUploading = false;
                                });
                              }
                            }
                          },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
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
                                  size: 48,
                                  color: AppColors.teal,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image uploaded!',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to change',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
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
            style: TextButton.styleFrom(foregroundColor: AppColors.lightRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: colorScheme.text,
                          ),
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
                          size: 64,
                          color: colorScheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
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
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.lightRed,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          _confirmDelete(context, vm, item['id']);
                          return false; // Handled by dialog
                        },
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 80,
                                  height: 80,
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
                              const SizedBox(width: 16),
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
                                icon: Icon(
                                  Icons.edit,
                                  color: colorScheme.primary,
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
        backgroundColor: AppColors.teal,
        label: const Text('Add Item', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
