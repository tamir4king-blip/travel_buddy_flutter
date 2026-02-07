import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/shared/providers/achievements_provider.dart';
import 'package:travel_buddy/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy/shared/providers/nearby_achievements_provider.dart';
import 'package:travel_buddy/shared/widgets/proximity_alert.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  String? _alertAchievementId;

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
    final geo = ref.watch(geolocationProvider);
    final nearbyState = ref.watch(nearbyAchievementsProvider);

    // Show proximity alert when new achievements are discovered during live tracking
    ref.listen(nearbyAchievementsProvider, (prev, next) {
      if (!geo.isLiveTracking) return;
      if (next.newlyDiscovered.isNotEmpty) {
        setState(() {
          _alertAchievementId = next.newlyDiscovered.first.id;
        });
        // Auto-dismiss after 8 seconds
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && _alertAchievementId == next.newlyDiscovered.first.id) {
            setState(() => _alertAchievementId = null);
          }
        });
      }
    });

    // Find the alert achievement if active
    final alertAchievement = _alertAchievementId != null
        ? nearbyState.nearby.where((a) => a.id == _alertAchievementId).firstOrNull
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final isWide = constraints.maxWidth >= 1200;
        final selectedIndex = _currentIndex(context);

        Widget body;
        if (isDesktop) {
          body = Scaffold(
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
                Expanded(child: widget.child),
              ],
            ),
          );
        } else {
          // Mobile layout with bottom navigation bar
          body = Scaffold(
            body: widget.child,
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
        }

        // Overlay proximity alert on top of the shell
        return Stack(
          children: [
            body,
            if (alertAchievement != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ProximityAlert(
                      achievement: alertAchievement,
                      distance: geo.hasLocation
                          ? geo.distanceTo(alertAchievement.latitude!, alertAchievement.longitude!)
                          : 0,
                      onClaim: () {
                        ref.read(achievementsProvider.notifier).claimAchievement(
                              alertAchievement.id,
                              userLat: geo.latitude,
                              userLng: geo.longitude,
                            );
                        setState(() => _alertAchievementId = null);
                      },
                      onDismiss: () {
                        setState(() => _alertAchievementId = null);
                      },
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
