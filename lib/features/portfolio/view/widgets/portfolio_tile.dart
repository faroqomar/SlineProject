import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/portfolio/models/portfolio_item.dart';
import 'package:sline_app/features/portfolio/view/sheets/portfolio_details_sheet.dart';
import 'package:sline_app/features/portfolio/view/widgets/image_placeholder.dart';
import 'package:sline_app/features/portfolio/viewmodels/portfolio_view_model.dart';

/// Grid tile for a single portfolio item.
///
/// Uses [PortfolioViewModel.getImageUrl] so canonical storage paths and legacy
/// public URLs keep the existing repository-owned resolution behavior.
class PortfolioTile extends StatelessWidget {
  const PortfolioTile({
    super.key,
    required this.item,
    required this.controller,
    required this.onLongPress,
  });

  final PortfolioItem item;
  final PortfolioViewModel controller;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    // The ViewModel owns portfolio bucket URL resolution; the tile only renders.
    final imageUrl = controller.getImageUrl(item);
    final colorScheme = context.colorScheme;
    final cardTheme = AmberDuskTokens.widgetTheme.cards;
    final radius = BorderRadius.circular(cardTheme.panel.radius);

    AppLogger.d(
      'Building portfolio tile',
      tag: 'PortfolioTile',
      json: {
        'itemId': item.id,
        'hasImage': imageUrl != null,
        'imagePath': item.imagePath,
        'imageUrl': item.imageUrl != null ? '(legacy)' : null,
      },
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardTheme.panel.background,
        borderRadius: radius,
        boxShadow: AppDecorations.elevation(
          cardTheme.panel.elevationLevel,
          isDark: colorScheme.isDark,
        ),
      ),
      child: Material(
        color: AmberDuskTokens.colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onLongPress: onLongPress,
          borderRadius: radius,
          onTap: () {
            AppLogger.d(
              'Opening portfolio details',
              tag: 'PortfolioTile',
              json: {'itemId': item.id},
            );
            PortfolioDetailsSheet.open(context, item, controller);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(cardTheme.panel.radius),
                  ),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, __) {
                            AppLogger.w(
                              'Failed to load portfolio image',
                              tag: 'PortfolioTile',
                              error: error,
                            );
                            return ImagePlaceholder(title: item.title);
                          },
                        )
                      : ImagePlaceholder(title: item.title),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimens.p10),
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionBold.copyWith(
                    color: colorScheme.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
