import 'package:flutter/material.dart';

import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_motion.dart';

/// Centralized route transition factory for the SLine app.
///
/// All screen navigation transitions MUST use this class. The three named
/// constructors cover every navigation pattern in the app:
///
/// - [SlinePageRoute.forwardPush] — standard screen-to-screen (slide up + fade)
/// - [SlinePageRoute.modalSheet] — bottom sheet / modal (slide from bottom, spring)
/// - [SlinePageRoute.fade] — subtle crossfade (tab replacements, splash → home)
///
/// Respects reduced-motion: when [MediaQuery.disableAnimations] is true,
/// transitions complete instantly.
class SlinePageRoute<T> extends PageRouteBuilder<T> {
  SlinePageRoute._({
    required WidgetBuilder pageBuilder,
    required Duration duration,
    required super.transitionsBuilder,
    super.settings,
    super.fullscreenDialog,
    super.barrierColor,
    super.opaque,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             pageBuilder(context),
         transitionDuration: duration,
         reverseTransitionDuration: duration,
       );

  /// Standard forward push — slide up + fade (vertical shared-axis feel).
  ///
  /// Duration: [AppMotion.standard] (300ms).
  /// Curve: [AppMotion.curveDecel].
  factory SlinePageRoute.forwardPush({
    required Widget child,
    RouteSettings? settings,
  }) {
    AppLogger.d(
      'Route transition: forwardPush → ${settings?.name ?? child.runtimeType}',
      tag: 'Navigation',
    );
    return SlinePageRoute._(
      settings: settings,
      opaque: true,
      pageBuilder: (_) => child,
      duration: AppMotion.standard,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.of(context).disableAnimations) return child;

        final offsetTween = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).chain(CurveTween(curve: AppMotion.curveDecel));

        final fadeTween = Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: AppMotion.curveDecel));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(offsetTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Modal sheet — slides up from bottom with spring curve.
  ///
  /// Duration: [AppMotion.emphasis] (500ms).
  /// Curve: [AppMotion.curveSpring].
  factory SlinePageRoute.modalSheet({
    required Widget child,
    RouteSettings? settings,
  }) {
    AppLogger.d(
      'Route transition: modalSheet → ${settings?.name ?? child.runtimeType}',
      tag: 'Navigation',
    );
    return SlinePageRoute._(
      settings: settings,
      fullscreenDialog: true,
      opaque: false,
      pageBuilder: (_) => child,
      duration: AppMotion.emphasis,
      barrierColor: Colors.black38,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.of(context).disableAnimations) return child;

        final offsetTween = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: AppMotion.curveSpring));

        return SlideTransition(
          position: animation.drive(offsetTween),
          child: child,
        );
      },
    );
  }

  /// Simple crossfade — for subtle transitions.
  ///
  /// Duration: [AppMotion.fast] (200ms).
  /// Curve: [AppMotion.curveStandard].
  factory SlinePageRoute.fade({
    required Widget child,
    RouteSettings? settings,
  }) {
    AppLogger.d(
      'Route transition: fade → ${settings?.name ?? child.runtimeType}',
      tag: 'Navigation',
    );
    return SlinePageRoute._(
      settings: settings,
      opaque: true,
      pageBuilder: (_) => child,
      duration: AppMotion.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.of(context).disableAnimations) return child;

        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: AppMotion.curveStandard)),
          child: child,
        );
      },
    );
  }
}

/// A route that slides up from the bottom, commonly used for modals.
@Deprecated('Use SlinePageRoute.modalSheet() instead')
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  @Deprecated('Use SlinePageRoute.modalSheet() instead')
  SlideUpRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           const begin = Offset(0.0, 1.0);
           const end = Offset.zero;
           const curve = Curves.easeOutCubic;

           final tween = Tween(
             begin: begin,
             end: end,
           ).chain(CurveTween(curve: curve));

           return SlideTransition(
             position: animation.drive(tween),
             child: child,
           );
         },
       );
}

/// A route that fades in, used for smoother tab or replacement transitions.
@Deprecated('Use SlinePageRoute.fade() instead')
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  @Deprecated('Use SlinePageRoute.fade() instead')
  FadeRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return FadeTransition(opacity: animation, child: child);
         },
       );
}
