import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';

final class LoadingHandle {
  LoadingHandle._(this._entry);

  OverlayEntry? _entry;

  void close() {
    _entry?.remove();
    _entry = null;
  }
}

class LoadingUtils {
  // Prevent instantiation
  LoadingUtils._();

  static LoadingHandle show(BuildContext context, {String? debugLabel}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return LoadingHandle._(null);
    }

    final entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withValues(alpha: 0.3),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppDimens.p24),
                decoration: BoxDecoration(
                  color: Theme.of(overlayContext).cardColor,
                  borderRadius: BorderRadius.circular(AppDimens.r16),
                ),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(entry);
    return LoadingHandle._(entry);
  }
}
