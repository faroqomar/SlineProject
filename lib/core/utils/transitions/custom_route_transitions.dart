import 'package:flutter/material.dart';

/// A route that slides up from the bottom, commonly used for modals in this app.
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

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
           const curve = Curves.easeOutCubic; // Smooth cubic ease

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
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

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
