/// Provides Amber Dusk material decorations for tactile depth and safe areas.
///
/// The helpers keep the authored surface, fade, and wash rules in the design
/// layer so feature widgets can render the same material without copying raw
/// colors, gradients, or shadow recipes.
library;

import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_colors.dart';

/// Shared Amber Dusk material recipes for surfaces, fades, and active washes.
///
/// Flutter widgets use this namespace when they need concrete [BoxDecoration]
/// values instead of passive tokens. The recipes intentionally avoid glass,
/// hard borders, and decorative gradients.
abstract final class AmberDuskMaterial {
  const AmberDuskMaterial._();

  /// Raised surface fill matching `rgba(36,31,26,.88)` from the visual spec.
  static const Color raisedSurface = Color.fromRGBO(36, 31, 26, 0.88);

  /// Warm booking fallback fill used beneath the V2 hero gradient.
  static const Color bookingSurface = AmberDuskColors.hero;

  /// Row separator used instead of hard card outlines.
  static const Color rowSeparator = Color.fromRGBO(242, 232, 213, 0.058);

  /// Amber glow used only for the top-left atmospheric phone-shell fade.
  static const Color atmosphericAmber = Color.fromRGBO(212, 144, 106, 0.12);

  /// Green-brown glow used only for the top-right atmospheric phone-shell fade.
  static const Color atmosphericForest = Color.fromRGBO(127, 168, 114, 0.075);

  /// Creates the restrained tactile surface used by cards and dense panels.
  ///
  /// Flutter cannot render CSS inset shadows directly in a decoration that also
  /// clips to a radius, so the tiny vertical overlay fakes the top highlight and
  /// bottom shade while the only real shadow stays small and black.
  static BoxDecoration surfaceDecoration({
    double radius = 24,
    bool strong = true,
    Color color = raisedSurface,
  }) {
    return BoxDecoration(
      color: color,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.022),
          Colors.black.withValues(alpha: 0.02),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: strong ? strongSurfaceDepthShadows : surfaceDepthShadows,
    );
  }

  /// Original SLine V2 premium booking-card surface.
  ///
  /// This recipe is intentionally stronger than row/dashboard surfaces because
  /// booking cards represent service providers and need the hero-card identity.
  static BoxDecoration bookingCardDecoration({double radius = 24}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          AmberDuskColors.heroTop,
          AmberDuskColors.hero,
          AmberDuskColors.heroDeep,
        ],
        stops: <double>[0, 0.56, 1],
      ),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.38),
          offset: Offset(0, 20),
          blurRadius: 44,
        ),
      ],
    );
  }

  /// Original SLine V2 tender/task post surface.
  ///
  /// The subtle vertical overlay mimics the requested inset highlight and
  /// bottom darkening without giving the card the booking hero gradient.
  static BoxDecoration taskCardDecoration({double radius = 22}) {
    return BoxDecoration(
      color: AmberDuskColors.surface,
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.fromRGBO(255, 255, 255, 0.018),
          Color.fromRGBO(0, 0, 0, 0.035),
        ],
      ),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.23),
          offset: Offset(0, 10),
          blurRadius: 24,
        ),
      ],
    );
  }

  /// Minimal raised depth for standard card and panel surfaces.
  static List<BoxShadow> get surfaceDepthShadows => const <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.18),
      offset: Offset(0, 12),
      blurRadius: 26,
    ),
  ];

  /// Stronger raised depth is intentionally the same to avoid loud cards.
  static List<BoxShadow> get strongSurfaceDepthShadows => surfaceDepthShadows;

  /// Bottom safe-area fade used only where fixed navigation overlaps content.
  static const LinearGradient bottomNavFadeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: <double>[0, 0.44, 1],
    colors: <Color>[
      Color.fromRGBO(26, 22, 18, 0),
      Color.fromRGBO(26, 22, 18, 0.92),
      AmberDuskColors.background,
    ],
  );

  /// Quiet amber wash for unread, active, or high-attention rows.
  static const LinearGradient activeWashGradient = LinearGradient(
    colors: <Color>[
      Color.fromRGBO(212, 144, 106, 0.105),
      Color.fromRGBO(212, 144, 106, 0.018),
      AmberDuskColors.transparent,
    ],
    stops: <double>[0, 0.58, 1],
  );

  /// Top-left atmospheric fade decoration for the app shell.
  static const BoxDecoration atmosphericAmberDecoration = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(-0.75, -0.95),
      radius: 0.75,
      stops: <double>[0, 1],
      colors: <Color>[atmosphericAmber, AmberDuskColors.transparent],
    ),
  );

  /// Top-right atmospheric fade decoration for the app shell.
  static const BoxDecoration atmosphericForestDecoration = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0.9, -1),
      radius: 0.65,
      stops: <double>[0, 1],
      colors: <Color>[atmosphericForest, AmberDuskColors.transparent],
    ),
  );
}

/// Paints the Amber Dusk screen background exactly once behind page content.
///
/// Screens with opaque [Scaffold] backgrounds hide the app shell fades. This
/// widget keeps the `#1A1612` base and the two subtle radial fades inside the
/// screen body so the recipe is visible on every tab.
class AmberDuskBackground extends StatelessWidget {
  /// Creates a reusable Amber Dusk background wrapper.
  const AmberDuskBackground({super.key, required this.child});

  /// Page content rendered above the solid background and radial fades.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AmberDuskColors.background,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: AmberDuskMaterial.atmosphericAmberDecoration,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: AmberDuskMaterial.atmosphericForestDecoration,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
