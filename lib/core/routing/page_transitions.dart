import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// A shared fade + slide-up page transition so every route in the app feels
/// consistent and polished, instead of the platform default.
CustomTransitionPage<void> buildFadeSlidePage({
  required GoRouterState state,
  required Widget child,
  LocalKey? key,
}) {
  return CustomTransitionPage<void>(
    key: key ?? state.pageKey,
    child: Builder(
      builder: (context) {
        final location = state.uri.path;
        final isExitScreen = location == AppRoutes.login;

        return PopScope(
          canPop: context.canPop() || isExitScreen,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (!context.canPop() && !isExitScreen) {
              context.go(AppRoutes.home);
            }
          },
          child: child,
        );
      },
    ),
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
