import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/presentation/screens/map_screen.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/nearby_achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/notification_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/proximity_alert.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  String? _alertAchievementId;
  double? _overlayTop;
  bool _mapDockExpanded = false;
  bool _isDraggingOverlay = false;

  // Horizontal swipe state
  int _previousIndex = 0;
  double _horizontalDragStart = 0;
  double _horizontalDragDelta = 0;
  bool _isHorizontalSwiping = false;
  double _slideOffset = 0; // -1 to 1, used for slide visual feedback

  static const _routes = ['/', '/map', '/quests', '/skills', '/achievements', '/leaderboard', '/profile'];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location == '/map') return 1;
    if (location == '/quests') return 2;
    if (location == '/skills') return 3;
    if (location == '/achievements') return 4;
    if (location == '/leaderboard') return 5;
    if (location == '/profile') return 6;
    return 0;
  }

  bool _isOnMap(BuildContext context) {
    return GoRouterState.of(context).uri.path == '/map';
  }

  double _collapsedTopFor(BuildContext context, double navBarHeight) {
    final h = MediaQuery.of(context).size.height;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    const peekHeight = 84.0;
    final collapsed = h - navBarHeight - peekHeight - bottomSafe;
    return collapsed.clamp(0, h);
  }

  double _midTopFor(BuildContext context, double navBarHeight) {
    final h = MediaQuery.of(context).size.height;
    return (h * 0.42).clamp(0, _collapsedTopFor(context, navBarHeight));
  }

  void _syncOverlayTop(BuildContext context, double navBarHeight, {required int currentIndex}) {
    final collapsed = _collapsedTopFor(context, navBarHeight);
    if (_overlayTop == null) {
      _overlayTop = 0;
      _previousIndex = currentIndex;
      return;
    }
    // Reset overlay to fully expanded when arriving from the map page
    if (_previousIndex == 1 && currentIndex != 1) {
      _overlayTop = 0;
    }
    _previousIndex = currentIndex;
    _overlayTop = _overlayTop!.clamp(0, collapsed);
  }

  void _snapOverlayTo(double target, {bool strong = false}) {
    setState(() => _overlayTop = target);
    if (strong) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _handleDragEnd(BuildContext context, double navBarHeight, {double velocity = 0}) {
    final collapsed = _collapsedTopFor(context, navBarHeight);
    final mid = _midTopFor(context, navBarHeight);
    final current = _overlayTop!;
    double target;
    if (velocity.abs() > 700) {
      target = velocity > 0 ? collapsed : 0;
    } else {
      final points = [0.0, mid, collapsed];
      points.sort(
          (a, b) => (a - current).abs().compareTo((b - current).abs()));
      target = points.first;
    }
    _snapOverlayTo(target, strong: target == 0 || target == collapsed);
    _isDraggingOverlay = false;
  }

  void _navigateToIndex(BuildContext context, int index) {
    if (index < 0 || index >= _routes.length) return;
    context.go(_routes[index]);
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _horizontalDragStart = details.globalPosition.dx;
    _horizontalDragDelta = 0;
    _isHorizontalSwiping = false;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragDelta = details.globalPosition.dx - _horizontalDragStart;
    // After 15px of horizontal movement, commit to horizontal swipe
    if (_horizontalDragDelta.abs() > 15) {
      _isHorizontalSwiping = true;
    }
    if (_isHorizontalSwiping) {
      final screenWidth = MediaQuery.of(context).size.width;
      setState(() {
        _slideOffset = (_horizontalDragDelta / screenWidth).clamp(-0.35, 0.35);
      });
    }
  }

  void _onHorizontalDragEnd(BuildContext context, DragEndDetails details, int currentIndex) {
    if (!_isHorizontalSwiping) {
      setState(() => _slideOffset = 0);
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    final threshold = MediaQuery.of(context).size.width * 0.15;
    int targetIndex = currentIndex;

    if (velocity < -300 || (_horizontalDragDelta < -threshold && velocity <= 0)) {
      // Swiped left → next page
      if (currentIndex < _routes.length - 1) targetIndex = currentIndex + 1;
    } else if (velocity > 300 || (_horizontalDragDelta > threshold && velocity >= 0)) {
      // Swiped right → previous page
      if (currentIndex > 0) targetIndex = currentIndex - 1;
    }

    if (targetIndex != currentIndex) {
      HapticFeedback.selectionClick();
      _navigateToIndex(context, targetIndex);
    }
    setState(() => _slideOffset = 0);
    _isHorizontalSwiping = false;
  }

  void _toggleMapDock() {
    setState(() => _mapDockExpanded = !_mapDockExpanded);
    HapticFeedback.selectionClick();
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
        context.go('/skills');
      case 4:
        context.go('/achievements');
      case 5:
        context.go('/leaderboard');
      case 6:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final geo = ref.watch(geolocationProvider);
    final nearbyState = ref.watch(nearbyAchievementsProvider);
    final selectedIndex = _currentIndex(context);
    final onMapRoute = _isOnMap(context);

    // Show proximity alert when new achievements are discovered during live tracking
    ref.listen(nearbyAchievementsProvider, (prev, next) {
      if (!geo.isLiveTracking) return;
      if (next.newlyDiscovered.isNotEmpty) {
        final achievement = next.newlyDiscovered.first;
        setState(() {
          _alertAchievementId = achievement.id;
        });

        // Fire native notification if enabled
        if (ref.read(notificationsEnabledProvider)) {
          final distance = geo.hasLocation
              ? geo.distanceTo(achievement.latitude!, achievement.longitude!)
              : 0.0;
          ref.read(notificationServiceProvider).showProximityNotification(
                id: achievement.hashCode,
                title: achievement.title,
                body: '${distance.round()}m away · ${achievement.xpReward} XP',
              );
        }

        // Auto-dismiss after 8 seconds
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && _alertAchievementId == achievement.id) {
            setState(() => _alertAchievementId = null);
          }
        });
      }
    });

    // Find the alert achievement if active
    final alertAchievement = _alertAchievementId != null
        ? nearbyState.nearby.where((a) => a.id == _alertAchievementId).firstOrNull
        : null;

    // Mobile layout — map as persistent background with slide-down pages
    const navBarHeight = 68.0;

    final bottomNav = Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        backgroundColor: AppColors.bgCard,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: navBarHeight,
        destinations: [
          NavigationDestination(
            icon: Icon(LucideIcons.home, color: AppColors.textMuted.withValues(alpha: 0.6), size: 20),
            selectedIcon: const Icon(LucideIcons.home, color: AppColors.primaryLight, size: 22),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.map, color: AppColors.textMuted.withValues(alpha: 0.6), size: 20),
            selectedIcon: const Icon(LucideIcons.map, color: AppColors.primaryLight, size: 22),
            label: l10n.navMap,
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.compass, color: AppColors.textMuted.withValues(alpha: 0.6), size: 20),
            selectedIcon: const Icon(LucideIcons.compass, color: AppColors.primaryLight, size: 22),
            label: l10n.navQuests,
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.sparkles, color: AppColors.textMuted.withValues(alpha: 0.6), size: 20),
            selectedIcon: const Icon(LucideIcons.sparkles, color: AppColors.primaryLight, size: 22),
            label: l10n.navSkills,
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.award, color: AppColors.textMuted.withValues(alpha: 0.6), size: 20),
            selectedIcon: const Icon(LucideIcons.award, color: AppColors.primaryLight, size: 22),
            label: l10n.navAchievements,
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.trophy, color: AppColors.textMuted.withValues(alpha: 0.6), size: 20),
            selectedIcon: const Icon(LucideIcons.trophy, color: AppColors.primaryLight, size: 22),
            label: l10n.navRankings,
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user, color: AppColors.textMuted.withValues(alpha: 0.6), size: 20),
            selectedIcon: const Icon(LucideIcons.user, color: AppColors.primaryLight, size: 22),
            label: l10n.navProfile,
          ),
        ],
      ),
    );

    _syncOverlayTop(context, navBarHeight, currentIndex: selectedIndex);

    final screenWidth = MediaQuery.of(context).size.width;
    final slideTranslation = _slideOffset * screenWidth;

    final body = Stack(
      children: [
        // Layer 1: Persistent map background (truly full screen)
        const Positioned.fill(
          child: MapScreen(),
        ),

        // Layer 2: Smooth snap page overlay (non-map pages)
        if (!onMapRoute)
          AnimatedPositioned(
            duration: _isHorizontalSwiping ? Duration.zero : const Duration(milliseconds: 340),
            curve: Curves.easeOutBack,
            left: 0,
            right: 0,
            top: _overlayTop!,
            bottom: navBarHeight,
            child: Transform.translate(
              offset: Offset(slideTranslation, 0),
              child: Material(
                color: AppColors.bgDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: [
                    // Drag handle — supports both vertical (overlay) and horizontal (page swipe)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        _horizontalDragStart = details.globalPosition.dx;
                        _horizontalDragDelta = 0;
                        _isHorizontalSwiping = false;
                      },
                      onPanUpdate: (details) {
                        final dx = details.globalPosition.dx - _horizontalDragStart;
                        _horizontalDragDelta = dx;
                        // Determine dominant axis
                        if (!_isHorizontalSwiping && dx.abs() > 15 && dx.abs() > details.delta.dy.abs() * 1.5) {
                          _isHorizontalSwiping = true;
                        }
                        if (_isHorizontalSwiping) {
                          final sw = MediaQuery.of(context).size.width;
                          setState(() {
                            _slideOffset = (_horizontalDragDelta / sw).clamp(-0.35, 0.35);
                          });
                        } else {
                          final collapsed = _collapsedTopFor(context, navBarHeight);
                          setState(() {
                            _overlayTop = (_overlayTop! + details.delta.dy).clamp(0, collapsed);
                          });
                        }
                      },
                      onPanEnd: (details) {
                        if (_isHorizontalSwiping) {
                          _onHorizontalDragEnd(context, DragEndDetails(primaryVelocity: details.velocity.pixelsPerSecond.dx), selectedIndex);
                        } else {
                          _handleDragEnd(context, navBarHeight, velocity: details.velocity.pixelsPerSecond.dy);
                        }
                      },
                      onTap: () {
                        final collapsed = _collapsedTopFor(context, navBarHeight);
                        _snapOverlayTo(
                          _overlayTop! < collapsed / 2 ? collapsed : 0,
                          strong: true,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.bgCard.withValues(alpha: 0.55),
                              AppColors.bgDark.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Page content with slide-down-to-reveal-map and horizontal swipe support
                    Expanded(
                      child: _overlayTop! > 5
                          // Overlay is partially down: drag anywhere to move it, disable inner scroll
                          ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragUpdate: (details) {
                                final collapsed = _collapsedTopFor(context, navBarHeight);
                                setState(() {
                                  _overlayTop = (_overlayTop! + details.delta.dy).clamp(0, collapsed);
                                });
                              },
                              onVerticalDragEnd: (details) {
                                _handleDragEnd(context, navBarHeight, velocity: details.primaryVelocity ?? 0);
                              },
                              child: AbsorbPointer(child: widget.child),
                            )
                          // Overlay is fully expanded: normal scrolling + horizontal swipe to change page
                          : GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragStart: _onHorizontalDragStart,
                              onHorizontalDragUpdate: _onHorizontalDragUpdate,
                              onHorizontalDragEnd: (details) => _onHorizontalDragEnd(context, details, selectedIndex),
                              child: NotificationListener<OverscrollNotification>(
                                onNotification: (notification) {
                                  // User overscrolling past the top → slide overlay down
                                  if (notification.overscroll < 0) {
                                    final collapsed = _collapsedTopFor(context, navBarHeight);
                                    setState(() {
                                      _isDraggingOverlay = true;
                                      _overlayTop = (_overlayTop! + notification.overscroll.abs())
                                          .clamp(0.0, collapsed);
                                    });
                                    return true;
                                  }
                                  return false;
                                },
                                child: NotificationListener<ScrollEndNotification>(
                                  onNotification: (notification) {
                                    // When scroll ends and overlay was moved, snap to nearest anchor
                                    if (_isDraggingOverlay && _overlayTop! > 5) {
                                      _handleDragEnd(context, navBarHeight);
                                    }
                                    return false;
                                  },
                                  child: ScrollConfiguration(
                                    behavior: _ClampingScrollBehavior(),
                                    child: widget.child,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Layer 2b: Edge swipe zones on map route (swipe from edges to change page)
        if (onMapRoute) ...[
          // Left edge swipe zone
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 24,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: (details) => _onHorizontalDragEnd(context, details, selectedIndex),
            ),
          ),
          // Right edge swipe zone
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 24,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: (details) => _onHorizontalDragEnd(context, details, selectedIndex),
            ),
          ),
          _MapQuickDock(
            selectedIndex: selectedIndex,
            expanded: _mapDockExpanded,
            onToggle: _toggleMapDock,
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
          ),
        ],

        // Layer 3: Bottom nav bar (hidden on map route)
        if (!onMapRoute)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: bottomNav,
          ),
      ],
    );

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
  }
}

// ─── Slide-up Navigation Menu for Map Page ──────────────────────────────────

class _MapQuickDock extends StatelessWidget {
  final int selectedIndex;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<int> onDestinationSelected;

  const _MapQuickDock({
    required this.selectedIndex,
    required this.expanded,
    required this.onToggle,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          top: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 112),
            padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + bottomPadding * 0.25),
            decoration: BoxDecoration(
              color: AppColors.bgCard.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onToggle,
                  child: Row(
                    children: [
                      Icon(
                        expanded ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        expanded ? l10n.navMap : l10n.mapView,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  firstChild: const SizedBox(height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _NavItem(icon: LucideIcons.home, label: l10n.navHome, isSelected: selectedIndex == 0, onTap: () => onDestinationSelected(0)),
                          _NavItem(icon: LucideIcons.map, label: l10n.navMap, isSelected: selectedIndex == 1, onTap: () => onDestinationSelected(1)),
                          _NavItem(icon: LucideIcons.compass, label: l10n.navQuests, isSelected: selectedIndex == 2, onTap: () => onDestinationSelected(2)),
                          _NavItem(icon: LucideIcons.sparkles, label: l10n.navSkills, isSelected: selectedIndex == 3, onTap: () => onDestinationSelected(3)),
                          _NavItem(icon: LucideIcons.award, label: l10n.navAchievements, isSelected: selectedIndex == 4, onTap: () => onDestinationSelected(4)),
                          _NavItem(icon: LucideIcons.trophy, label: l10n.navRankings, isSelected: selectedIndex == 5, onTap: () => onDestinationSelected(5)),
                          _NavItem(icon: LucideIcons.user, label: l10n.navProfile, isSelected: selectedIndex == 6, onTap: () => onDestinationSelected(6)),
                        ],
                      ),
                    ),
                  ),
                  crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                icon,
                size: isSelected ? 22 : 20,
                color: isSelected
                    ? AppColors.primaryLight
                    : AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryLight
                    : AppColors.textMuted.withValues(alpha: 0.6),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Forces ClampingScrollPhysics so OverscrollNotification fires on all platforms
class _ClampingScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
