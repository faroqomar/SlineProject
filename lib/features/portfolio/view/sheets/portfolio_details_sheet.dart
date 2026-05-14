import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/portfolio/models/portfolio_item.dart';
import 'package:sline_app/features/portfolio/view/sheets/edit_portfolio_sheet.dart';
import 'package:sline_app/features/portfolio/view/widgets/image_placeholder.dart';
import 'package:sline_app/features/portfolio/viewmodels/portfolio_view_model.dart';

/// Bottom sheet that shows portfolio item details and actions.
///
/// Uses [PortfolioViewModel.getImageUrl] for image rendering so storage path
/// resolution and legacy URL fallback remain unchanged.
class PortfolioDetailsSheet extends StatelessWidget {
  const PortfolioDetailsSheet({
    super.key,
    required this.item,
    required this.controller,
  });
  final PortfolioItem item;
  final PortfolioViewModel controller;

  static Future<void> open(
    BuildContext context,
    PortfolioItem item,
    PortfolioViewModel controller,
  ) {
    AppLogger.d(
      'Opening portfolio details sheet',
      tag: 'PortfolioDetailsSheet',
      json: {'itemId': item.id},
    );
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      barrierColor: context.amberColors.scrim,
      backgroundColor: AmberDuskTokens.colors.transparent,
      builder: (ctx) => _InsetSheetFrame(
        child: PortfolioDetailsSheet(item: item, controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdLocal = item.createdAt.toLocal();
    final imageUrl = controller.getImageUrl(item);
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;
    final buttonTheme = AmberDuskTokens.widgetTheme.buttons;

    AppLogger.d(
      'Building portfolio details',
      tag: 'PortfolioDetailsSheet',
      json: {'itemId': item.id, 'hasImage': imageUrl != null},
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.p16,
          AppDimens.p16,
          AppDimens.p16,
          AppDimens.p24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: _SheetHandle()),
            const SizedBox(height: AppDimens.p12),
            Text(
              'Portfolio Item',
              style: AppTypography.h5.copyWith(color: colorScheme.text),
            ),
            const SizedBox(height: AppDimens.p12),
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.r18),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: AppDimens.p100 + AppDimens.p100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, _) {
                    AppLogger.w(
                      'Failed to load portfolio image in details',
                      tag: 'PortfolioDetailsSheet',
                      error: error,
                    );
                    return ImagePlaceholder(
                      title: item.title,
                      height: AppDimens.p100 + AppDimens.p100,
                    );
                  },
                ),
              )
            else
              ImagePlaceholder(
                title: item.title,
                height: AppDimens.p100 + AppDimens.p100,
              ),
            const SizedBox(height: AppDimens.p12),
            Text(
              item.title,
              style: AppTypography.h6.copyWith(color: colorScheme.text),
            ),
            if ((item.description ?? '').isNotEmpty) ...[
              const SizedBox(height: AppDimens.p6),
              Text(
                item.description!,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppDimens.p8),
            Text(
              'Created: ${createdLocal.year}-${createdLocal.month.toString().padLeft(2, '0')}-${createdLocal.day.toString().padLeft(2, '0')} '
              '${createdLocal.hour.toString().padLeft(2, '0')}:${createdLocal.minute.toString().padLeft(2, '0')}',
              style: AppTypography.caption.copyWith(
                color: colorScheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.p16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.text,
                      minimumSize: Size.fromHeight(buttonTheme.minHeight),
                      side: BorderSide(color: colorScheme.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonTheme.radius),
                      ),
                      textStyle: buttonTheme.textStyle,
                    ),
                    onPressed: () async {
                      AppLogger.d(
                        'Edit button pressed',
                        tag: 'PortfolioDetailsSheet',
                      );
                      final updated = await EditPortfolioSheet.open(
                        context,
                        item,
                        controller,
                      );
                      if ((updated ?? false) && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: amberColors.dangerMuted,
                      foregroundColor: amberColors.text,
                      minimumSize: Size.fromHeight(buttonTheme.minHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonTheme.radius),
                      ),
                      textStyle: buttonTheme.textStyle,
                    ),
                    onPressed: () async {
                      AppLogger.d(
                        'Delete button pressed',
                        tag: 'PortfolioDetailsSheet',
                      );
                      final ok = await showDialog<bool>(
                        context: context,
                        barrierColor: amberColors.scrim,
                        builder: (ctx) {
                          final dialogColors = ctx.colorScheme;
                          final dialogAmber = ctx.amberColors;
                          return AlertDialog(
                            backgroundColor: dialogColors.cardBackground,
                            title: Text(
                              'Delete item?',
                              style: AppTypography.h5.copyWith(
                                color: dialogColors.text,
                              ),
                            ),
                            content: Text(
                              'This will permanently remove the portfolio entry.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: dialogColors.textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: dialogAmber.dangerMuted,
                                  foregroundColor: dialogAmber.text,
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                      if (!context.mounted) return;
                      if (ok ?? false) {
                        AppLogger.i(
                          'User confirmed delete',
                          tag: 'PortfolioDetailsSheet',
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await controller.deleteItem(item.id);
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Deleted successfully'
                                  : 'Delete failed. Please try again.',
                            ),
                          ),
                        );
                        if (success) Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Inset frame for details sheets using the Open Design rounded sheet geometry.
class _InsetSheetFrame extends StatelessWidget {
  const _InsetSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sheetRecipe = AmberDuskTokens.surfaces.sheet;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p10,
        AppDimens.p0,
        AppDimens.p10,
        AppDimens.p10,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sheetRecipe.fill,
          borderRadius: BorderRadius.circular(sheetRecipe.radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// Visual drag affordance for Amber Dusk bottom sheets.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimens.p40,
      height: AppDimens.p4,
      decoration: BoxDecoration(
        color: context.colorScheme.textSecondary.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppDimens.r4),
      ),
    );
  }
}
