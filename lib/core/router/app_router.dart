import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/features/auth/presentation/screens/auth_screen.dart';
import 'package:travel_buddy_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:travel_buddy_mobile/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:travel_buddy_mobile/features/quests/presentation/screens/quests_screen.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:travel_buddy_mobile/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:travel_buddy_mobile/features/map/presentation/screens/map_screen.dart';
import 'package:travel_buddy_mobile/features/skills/presentation/screens/skills_screen.dart';
import 'package:travel_buddy_mobile/features/activity_log/presentation/screens/activity_log_screen.dart';
import 'package:travel_buddy_mobile/shared/widgets/app_shell.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/screens/privacy_settings_screen.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/screens/app_settings_screen.dart';
import 'package:travel_buddy_mobile/shared/providers/auth_provider.dart';
import 'package:travel_buddy_mobile/features/dev_panel/presentation/screens/dev_panel_screen.dart';
import 'package:travel_buddy_mobile/features/dev_panel/presentation/screens/gps_spoof_screen.dart';
import 'package:travel_buddy_mobile/features/dev_panel/presentation/screens/achievement_editor_screen.dart';
import 'package:travel_buddy_mobile/features/dev_panel/presentation/screens/quest_editor_screen.dart';
import 'package:travel_buddy_mobile/features/dev_panel/presentation/screens/data_management_screen.dart';
import 'package:travel_buddy_mobile/features/dev_panel/presentation/screens/debug_tools_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Provides the GoRouter instance with auth-based redirect.
///
/// Uses [refreshListenable] so GoRouter re-evaluates its redirect
/// without rebuilding the entire router on every auth state change.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Create a listenable that triggers GoRouter redirect re-evaluation
  final authNotifier = _RouterAuthNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final isOnAuth = state.matchedLocation == '/auth';

      if (!isAuthenticated && !isOnAuth) return '/auth';
      if (isAuthenticated && isOnAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
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
      GoRoute(
        path: '/dev-panel',
        builder: (context, state) => const DevPanelScreen(),
      ),
      GoRoute(
        path: '/dev-panel/gps',
        builder: (context, state) => const GpsSpoofScreen(),
      ),
      GoRoute(
        path: '/dev-panel/achievements',
        builder: (context, state) => const AchievementEditorScreen(),
      ),
      GoRoute(
        path: '/dev-panel/quests',
        builder: (context, state) => const QuestEditorScreen(),
      ),
      GoRoute(
        path: '/dev-panel/data',
        builder: (context, state) => const DataManagementScreen(),
      ),
      GoRoute(
        path: '/dev-panel/debug',
        builder: (context, state) => const DebugToolsScreen(),
      ),
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
            path: '/log',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ActivityLogScreen(),
            ),
          ),
          GoRoute(
            path: '/quests',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QuestsScreen(),
            ),
          ),
          GoRoute(
            path: '/skills',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SkillsScreen(),
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
          GoRoute(
            path: '/map',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MapScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod auth state changes to GoRouter's [refreshListenable].
class _RouterAuthNotifier extends ChangeNotifier {
  _RouterAuthNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}
