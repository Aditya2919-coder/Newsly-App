import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/home/view_model/home_viewmodel.dart';
import '../../features/home/data/model/news_model.dart';
import '../../features/login/view/login_screen.dart';
import '../../features/login/view/otp_verification_screen.dart';
import '../../features/setting/view/setting_screen.dart';
import '../bottom_navigation_bar/widgets/app_bottom_navigation_bar.dart';
import '../storage/secure_storage_service.dart';
import '../../features/home/view/home_screen.dart';
import 'app_nav_keys.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

class AppRouter {
  AppRouter._();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: AppNavKeys.appNavKey,
    initialLocation: AppRoutes.login,
    redirect: _guardRedirect,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Page Not Found'),
      ),
      body: Center(child: Text('404 — No route defined for ${state.uri.path}')),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.login,
        pageBuilder: (context, state) =>
            buildFadeSlidePage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        name: AppRoutes.otpVerification,
        pageBuilder: (context, state) {
          final phone = state.extra is String ? state.extra as String : null;
          return buildFadeSlidePage(
            state: state,
            child: OtpVerificationScreen(phoneNumber: phone),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _MainNavigationScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: AppRoutes.search,
                name: AppRoutes.search,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bookmarks,
                name: AppRoutes.bookmarks,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: AppRoutes.settings,
                builder: (context, state) => const SettingScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.articleDetails,
        parentNavigatorKey: AppNavKeys.appNavKey,
        builder: (context, state) {
          final article = state.extra;
          if (article is! NewsArticle) {
            return const Scaffold(
              body: Center(child: Text('Article details are unavailable.')),
            );
          }
          return NewsArticleDetailsScreen(article: article);
        },
      ),
    ],
  );

  static Future<String?> _guardRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final isLoggedIn = await SecureStorageService.isLoggedIn();
    final isOnAuthRoute =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.otpVerification;

    if (isLoggedIn && isOnAuthRoute) {
      return AppRoutes.home;
    }
    if (!isLoggedIn && !isOnAuthRoute) {
      return AppRoutes.login;
    }
    return null;
  }
}

class _MainNavigationScaffold extends StatelessWidget {
  const _MainNavigationScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF8F8F3),
      body: navigationShell,
      bottomNavigationBar: Selector<HomeViewModel, int>(
        selector: (context, homeViewModel) => homeViewModel.bookmarks.length,
        builder: (context, bookmarkCount, _) => AppBottomNavigationBar(
          selectedIndex: navigationShell.currentIndex,
          bookmarkCount: bookmarkCount,
          onDestinationSelected: navigationShell.goBranch,
        ),
      ),
    );
  }
}
