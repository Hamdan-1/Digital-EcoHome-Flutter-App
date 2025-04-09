import 'package:flutter/material.dart';

/// Custom page route with optimized transitions for smooth navigation
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final TransitionType transitionType;

  CustomPageRoute({
    required this.page,
    this.transitionType = TransitionType.fade,
    RouteSettings? settings,
  }) : super(
         settings: settings,
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: const Duration(milliseconds: 300),
         reverseTransitionDuration: const Duration(milliseconds: 250),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curve = Curves.easeOutCubic;
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: curve,
           );

           switch (transitionType) {
             case TransitionType.fade:
               return FadeTransition(opacity: curvedAnimation, child: child);

             case TransitionType.slideUp:
               return SlideTransition(
                 position: Tween<Offset>(
                   begin: const Offset(0, 0.25),
                   end: Offset.zero,
                 ).animate(curvedAnimation),
                 child: FadeTransition(opacity: curvedAnimation, child: child),
               );

             case TransitionType.slideRight:
               return SlideTransition(
                 position: Tween<Offset>(
                   begin: const Offset(-0.25, 0),
                   end: Offset.zero,
                 ).animate(curvedAnimation),
                 child: FadeTransition(opacity: curvedAnimation, child: child),
               );

             case TransitionType.slideLeft:
               return SlideTransition(
                 position: Tween<Offset>(
                   begin: const Offset(0.25, 0),
                   end: Offset.zero,
                 ).animate(curvedAnimation),
                 child: FadeTransition(opacity: curvedAnimation, child: child),
               );

             case TransitionType.scale:
               return ScaleTransition(
                 scale: Tween<double>(
                   begin: 0.9,
                   end: 1.0,
                 ).animate(curvedAnimation),
                 child: FadeTransition(opacity: curvedAnimation, child: child),
               );

             case TransitionType.scaleWithFadeThrough:
               // Optimized for bottom navigation transitions
               final fadeInAnimation = Tween<double>(
                 begin: 0.0,
                 end: 1.0,
               ).animate(
                 CurvedAnimation(
                   parent: animation,
                   curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                 ),
               );
               final fadeOutAnimation = Tween<double>(
                 begin: 1.0,
                 end: 0.0,
               ).animate(
                 CurvedAnimation(
                   parent: secondaryAnimation,
                   curve: const Interval(0.0, 0.3, curve: Curves.easeInCubic),
                 ),
               );
               final scaleAnimation = Tween<double>(
                 begin: 0.92,
                 end: 1.0,
               ).animate(
                 CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
               );

               return FadeTransition(
                 opacity: fadeInAnimation,
                 child: FadeTransition(
                   opacity: fadeOutAnimation,
                   child: ScaleTransition(scale: scaleAnimation, child: child),
                 ),
               );
           }
         },
       );
}

/// Types of transitions available for the app
enum TransitionType {
  fade,
  slideUp,
  slideRight,
  slideLeft,
  scale,
  scaleWithFadeThrough,
}

/// Extension for easier Navigator usage
extension NavigatorExtension on BuildContext {
  Future<T?> pushPageWithTransition<T extends Object?>({
    required Widget page,
    TransitionType transitionType = TransitionType.fade,
    RouteSettings? settings,
    bool replace = false,
  }) {
    final route = CustomPageRoute<T>(
      page: page,
      transitionType: transitionType,
      settings: settings,
    );

    if (replace) {
      return Navigator.of(this).pushReplacement(route);
    } else {
      return Navigator.of(this).push(route);
    }
  }
}
