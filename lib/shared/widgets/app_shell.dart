import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location == '/map') return 1;
    if (location == '/quests') return 2;
    if (location == '/leaderboard') return 3;
    if (location == '/profile') return 4;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/map');
      case 2:
        context.go('/quests');
      case 3:
        context.go('/leaderboard');
      case 4:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final isWide = constraints.maxWidth >= 1200;
        final selectedIndex = _currentIndex(context);

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  extended: isWide,
                  onDestinationSelected: (index) =>
                      _onDestinationSelected(context, index),
                  backgroundColor: AppColors.bgCard,
                  selectedIconTheme: const IconThemeData(color: AppColors.primary),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
                  unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted),
                  indicatorColor: AppColors.primary.withValues(alpha: 0.2),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(LucideIcons.home),
                      selectedIcon: const Icon(LucideIcons.home),
                      label: Text(l10n.navHome),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(LucideIcons.map),
                      selectedIcon: const Icon(LucideIcons.map),
                      label: Text(l10n.navMap),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(LucideIcons.compass),
                      selectedIcon: const Icon(LucideIcons.compass),
                      label: Text(l10n.navQuests),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(LucideIcons.trophy),
                      selectedIcon: const Icon(LucideIcons.trophy),
                      label: Text(l10n.navRankings),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(LucideIcons.user),
                      selectedIcon: const Icon(LucideIcons.user),
                      label: Text(l10n.navProfile),
                    ),
                  ],
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.bgCardLight,
                ),
                Expanded(child: child),
              ],
            ),
          );
        }

        // Mobile layout with bottom navigation bar
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
            backgroundColor: AppColors.bgCard,
            indicatorColor: AppColors.primary.withValues(alpha: 0.2),
            destinations: [
              NavigationDestination(
                icon: const Icon(LucideIcons.home),
                selectedIcon: const Icon(LucideIcons.home, color: AppColors.primary),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(LucideIcons.map),
                selectedIcon: const Icon(LucideIcons.map, color: AppColors.primary),
                label: l10n.navMap,
              ),
              NavigationDestination(
                icon: const Icon(LucideIcons.compass),
                selectedIcon: const Icon(LucideIcons.compass, color: AppColors.primary),
                label: l10n.navQuests,
              ),
              NavigationDestination(
                icon: const Icon(LucideIcons.trophy),
                selectedIcon: const Icon(LucideIcons.trophy, color: AppColors.primary),
                label: l10n.navRankings,
              ),
              NavigationDestination(
                icon: const Icon(LucideIcons.user),
                selectedIcon: const Icon(LucideIcons.user, color: AppColors.primary),
                label: l10n.navProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}
