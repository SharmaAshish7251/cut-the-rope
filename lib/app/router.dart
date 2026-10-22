import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/level_selection/level_selection_screen.dart';
import '../features/gameplay/gameplay_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/achievements/achievements_screen.dart';

class AppRoutes {
  static const splash         = '/';
  static const onboarding     = '/onboarding';
  static const home           = '/home';
  static const levelSelection = '/levels';
  static const gameplay       = '/play/:levelId';
  static const settings       = '/settings';
  static const shop           = '/shop';
  static const achievements   = '/achievements';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.levelSelection,
      builder: (_, __) => const LevelSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.gameplay,
      builder: (context, state) {
        final levelId = int.parse(state.pathParameters['levelId']!);
        return GameplayScreen(levelId: levelId);
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.shop,
      builder: (_, __) => const ShopScreen(),
    ),
    GoRoute(
      path: AppRoutes.achievements,
      builder: (_, __) => const AchievementsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.error}')),
  ),
);
