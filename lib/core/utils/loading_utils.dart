import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// Handle returned by [LoadingUtils.show] so callers can close the overlay.
///
/// The handle owns only the overlay entry. It deliberately does not know about
/// the operation being loaded, so feature code keeps business-state ownership.
final class LoadingHandle {
  LoadingHandle._(this._entry, this._debugLabel);

  OverlayEntry? _entry;
  final String? _debugLabel;

  /// Removes the loading overlay if it is still mounted.
  ///
  /// Close calls can race with route disposal, so repeated calls log and no-op
  /// instead of throwing.
  void close() {
    final entry = _entry;
    if (entry == null) {
      AppLogger.d(
        'LoadingUtils.close skipped because no overlay was mounted',
        tag: 'LoadingUtils',
        json: <String, dynamic>{'debug_label': _debugLabel ?? 'unlabeled'},
      );
      return;
    }

    entry.remove();
    _entry = null;
    AppLogger.d(
      'LoadingUtils overlay closed',
      tag: 'LoadingUtils',
      json: <String, dynamic>{'debug_label': _debugLabel ?? 'unlabeled'},
    );
  }
}

/// Shared blocking loader for view-layer async actions.
///
/// The overlay uses the Amber Dusk solid scrim and sheet surface pattern. It
/// avoids blur/glass effects so the loader stays readable and cheap to render.
class LoadingUtils {
  /// Prevents instantiation; this class only exposes static UI helpers.
  LoadingUtils._();

  /// Shows a non-dismissible loading overlay above the root navigator.
  ///
  /// Returns a [LoadingHandle] even when no overlay exists so callers can use a
  /// single `try/finally` close path without checking for null.
  static LoadingHandle show(BuildContext context, {String? debugLabel}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      AppLogger.w(
        'LoadingUtils.show skipped because no root overlay was available',
        tag: 'LoadingUtils',
        json: <String, dynamic>{'debug_label': debugLabel ?? 'unlabeled'},
      );
      return LoadingHandle._(null, debugLabel);
    }

    final entry = OverlayEntry(
      builder: (overlayContext) {
        final amberColors = overlayContext.amberColors;
        final colorScheme = overlayContext.colorScheme;
        final surfaceRecipe = AmberDuskTokens.surfaces.sheet;

        return Stack(
          children: [
            ModalBarrier(dismissible: false, color: amberColors.scrim),
            Center(
              child: Semantics(
                label: 'Loading',
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.p24),
                  decoration: BoxDecoration(
                    color: surfaceRecipe.fill,
                    borderRadius: BorderRadius.circular(surfaceRecipe.radius),
                    boxShadow: AppDecorations.elevation(
                      surfaceRecipe.elevationLevel,
                      isDark: colorScheme.isDark,
                    ),
                  ),
                  child: CircularProgressIndicator(
                    color: amberColors.primary,
                    strokeWidth: AppDimens.p4,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(entry);
    AppLogger.d(
      'LoadingUtils overlay shown',
      tag: 'LoadingUtils',
      json: <String, dynamic>{'debug_label': debugLabel ?? 'unlabeled'},
    );
    return LoadingHandle._(entry, debugLabel);
  }
}
