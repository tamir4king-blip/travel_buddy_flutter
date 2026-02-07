import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_buddy/features/auth/presentation/screens/auth_screen.dart';
import 'package:travel_buddy/features/home/presentation/screens/home_screen.dart';
import 'package:travel_buddy/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:travel_buddy/features/quests/presentation/screens/quests_screen.dart';
import 'package:travel_buddy/features/map/presentation/screens/map_screen.dart';
import 'package:travel_buddy/features/profile/presentation/screens/profile_screen.dart';
import 'package:travel_buddy/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:travel_buddy/shared/widgets/app_shell.dart';
import 'package:travel_buddy/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:travel_buddy/features/profile/presentation/screens/privacy_settings_screen.dart';
import 'package:travel_buddy/features/profile/presentation/screens/app_settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Auth (no bottom nav)
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),

    // Profile sub-routes (no bottom nav)
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/profile/privacy',
      builder: (context, state) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: '/profile/settings',
      builder: (context, state) => const AppSettingsScreen(),
    ),

    // Main app with bottom navigation shell
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/map',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MapScreen(),
          ),
        ),
        GoRoute(
          path: '/quests',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: QuestsScreen(),
          ),
        ),
        GoRoute(
          path: '/achievements',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AchievementsScreen(),
          ),
        ),
        GoRoute(
          path: '/leaderboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LeaderboardScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
  ],
);
