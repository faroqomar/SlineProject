/// Reusable fullscreen image viewer with pinch-to-zoom and drag-to-dismiss.
///
/// Designed to be shared across any feature that displays tappable images
/// (chat attachments, portfolio galleries, profile avatars, task images, etc.).
/// Uses [CachedNetworkImage] for efficient loading and caching, [Hero] for
/// a smooth transition from the thumbnail, and [InteractiveViewer] for
/// pinch-to-zoom up to 4x.
///
/// Usage:
/// ```dart
/// FullscreenImageViewer.show(
///   context,
///   imageUrl: signedUrl,
///   heroTag: 'chat-image-$messageId',
///   caption: 'Delivery proof',
/// );
/// ```
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_typography.dart';

/// A full-screen overlay for viewing a single network image.
///
/// Supports Hero animation, pinch-to-zoom via [InteractiveViewer],
/// vertical drag-to-dismiss, and an optional caption bar.
/// Intentionally a [StatelessWidget] because it holds no mutable state --
/// all interactivity is handled by built-in gesture recognizers.
class FullscreenImageViewer extends StatelessWidget {
  /// Creates a fullscreen image viewer.
  ///
  /// [imageUrl] is the signed or public URL of the image to display.
  /// [heroTag] enables Hero transition from the source thumbnail; defaults
  /// to [imageUrl] so the caller only needs to match tags on its end.
  /// [caption] is optional descriptive text shown at the bottom of the screen.
  const FullscreenImageViewer({
    required this.imageUrl,
    this.heroTag,
    this.caption,
    super.key,
  });

  /// The network URL of the image to display.
  final String imageUrl;

  /// Tag used for the [Hero] animation. Falls back to [imageUrl] when null,
  /// which works as long as the source widget uses the same tag.
  final String? heroTag;

  /// Optional caption displayed in a semi-transparent bar at the bottom.
  final String? caption;

  // ---------------------------------------------------------------------------
  // Static entry point
  // ---------------------------------------------------------------------------

  /// Opens the fullscreen viewer as a new route with a fade transition.
  ///
  /// This is the only intended entry point. Using a static method keeps the
  /// calling code clean and centralises the route/transition definition.
  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? heroTag,
    String? caption,
  }) {
    AppLogger.d('[FullscreenImageViewer] Opening image: $imageUrl');

    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        // Opaque black background so content behind is fully hidden.
        opaque: false,
        barrierColor: Colors.black,
        // 300ms fade feels snappy while giving Hero time to animate.
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullscreenImageViewer(
            imageUrl: imageUrl,
            heroTag: heroTag,
            caption: caption,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Simple opacity fade -- complements the Hero flight nicely.
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Wrap the entire viewer in Semantics so screen readers announce
    // the purpose of this route and any caption context.
    return Semantics(
      label: 'Fullscreen image${caption != null ? ': $caption' : ''}',
      child: Scaffold(
        // Pure black background for an immersive photo-viewing experience.
        backgroundColor: Colors.black,
        body: _DragToDismissWrapper(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- Zoomable image (centre layer) ---
              _buildZoomableImage(),

              // --- Close button (top-right, above safe area) ---
              _buildCloseButton(context),

              // --- Caption bar (bottom, if provided) ---
              if (caption != null) _buildCaptionBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-builders
  // ---------------------------------------------------------------------------

  /// Builds the Hero + InteractiveViewer + CachedNetworkImage stack.
  ///
  /// [InteractiveViewer] provides pinch-to-zoom (1x-4x). The Hero tag
  /// defaults to [imageUrl] when no explicit tag is provided so that a
  /// matching Hero on the source screen triggers the flight animation.
  Widget _buildZoomableImage() {
    // Use LayoutBuilder to give CachedNetworkImage explicit constraints.
    // Without this, InteractiveViewer's unbounded layout causes the image
    // to render at zero size on iOS where intrinsic sizing behaves differently.
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          // 1x min keeps the image from shrinking below its natural size.
          minScale: 1.0,
          // 4x max is enough for inspecting details without going overboard.
          maxScale: 4.0,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Hero(
              tag: heroTag ?? imageUrl,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                // Spinner while the image loads -- white stands out on black.
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                // Show a clear error state so the user knows the load failed.
                errorWidget: (context, url, error) => Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Close button positioned at the top-right inside the safe area.
  ///
  /// Uses [SafeArea] so it avoids the notch / status bar on modern devices.
  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Semi-transparent caption bar anchored to the bottom of the screen.
  ///
  /// Only rendered when [caption] is non-null. The bar uses 60% opacity
  /// black so the image is still partially visible behind the text.
  Widget _buildCaptionBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false, // Only respect bottom safe area (home indicator).
        child: Container(
          width: double.infinity,
          // Semi-transparent bar -- dark enough for legibility, light enough
          // to let the image bleed through.
          color: Colors.black.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            caption!,
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Drag-to-dismiss wrapper
// =============================================================================

/// Wraps its [child] in a vertical-drag gesture that pops the route when the
/// user drags downward past a threshold.
///
/// Implemented as a separate [StatefulWidget] because it needs to track the
/// cumulative drag offset -- the parent [FullscreenImageViewer] stays
/// stateless.
class _DragToDismissWrapper extends StatefulWidget {
  const _DragToDismissWrapper({required this.child});

  final Widget child;

  @override
  State<_DragToDismissWrapper> createState() => _DragToDismissWrapperState();
}

class _DragToDismissWrapperState extends State<_DragToDismissWrapper> {
  /// Accumulated vertical drag distance in logical pixels.
  double _dragOffset = 0;

  /// Threshold in logical pixels the user must drag down to trigger dismiss.
  /// 100px is a comfortable distance -- not too sensitive, not too hard.
  static const double _dismissThreshold = 100;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Track vertical drags only -- horizontal drags are left for
      // InteractiveViewer panning.
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dy;
        });
      },
      onVerticalDragEnd: (details) {
        // Pop when the user has dragged far enough downward.
        if (_dragOffset > _dismissThreshold) {
          Navigator.of(context).pop();
        } else {
          // Snap back if the threshold wasn't reached.
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      child: Transform.translate(
        // Move the content with the finger so the drag feels physical.
        // Clamp to >= 0 so upward drags don't shift the image above origin.
        offset: Offset(0, _dragOffset.clamp(0, double.infinity)),
        child: Opacity(
          // Fade out proportionally as the user drags -- gives a clear visual
          // signal that releasing will dismiss.
          opacity:
              (1 -
                      (_dragOffset.clamp(0, _dismissThreshold) /
                              _dismissThreshold) *
                          0.4)
                  .clamp(0.0, 1.0),
          child: widget.child,
        ),
      ),
    );
  }
}
