import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
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
  bool _isDraggingOverlay = false;
  double _lastOverscrollVelocity = 0;

  // Horizontal swipe state
  int _previousIndex = 0;
  double _horizontalDragStart = 0;
  double _horizontalDragDelta = 0;
  bool _isHorizontalSwiping = false;
  double _slideOffset = 0; // -1 to 1, used for slide visual feedback

  static const _routes = ['/', '/quests', '/skills', '/achievements', '/leaderboard', '/profile'];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location == '/quests') return 1;
    if (location == '/skills') return 2;
    if (location == '/achievements') return 3;
    if (location == '/leaderboard') return 4;
    if (location == '/profile') return 5;
    return 0;
  }

  // Bottom snap: page peeks with just the drag handle visible
  double _collapsedTopFor(BuildContext context, double navBarHeight) {
    final h = MediaQuery.of(context).size.height;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    const peekHeight = 84.0;
    final collapsed = h - navBarHeight - peekHeight - bottomSafe;
    return collapsed.clamp(0, h);
  }

  // Middle snap: page at ~50% of screen
  double _midTopFor(BuildContext context, double navBarHeight) {
    final h = MediaQuery.of(context).size.height;
    return (h * 0.45).clamp(0, _collapsedTopFor(context, navBarHeight));
  }

  void _syncOverlayTop(BuildContext context, double navBarHeight, {required int currentIndex}) {
    final collapsed = _collapsedTopFor(context, navBarHeight);
    if (_overlayTop == null) {
      _overlayTop = 0;
      _previousIndex = currentIndex;
      return;
    }
    // Reset overlay to fully expanded when switching tabs
    if (_previousIndex != currentIndex) {
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

    // Velocity-based directional snap
    if (velocity > 400) {
      // Flicking down → snap to next position below current
      if (current < mid * 0.7) {
        target = mid;
      } else {
        target = collapsed;
      }
    } else if (velocity < -400) {
      // Flicking up → snap to next position above current
      if (current > (mid + collapsed) / 2) {
        target = mid;
      } else {
        target = 0;
      }
    } else {
      // No strong velocity → snap to nearest using region boundaries
      final topMidBoundary = mid / 2;
      final midBottomBoundary = (mid + collapsed) / 2;
      if (current < topMidBoundary) {
        target = 0;
      } else if (current < midBottomBoundary) {
        target = mid;
      } else {
        target = collapsed;
      }
    }

    _snapOverlayTo(target, strong: target == 0 || target == collapsed);
    _isDraggingOverlay = false;
    _lastOverscrollVelocity = 0;
  }

  void _navigateToIndex(BuildContext context, int index) {
    if (index < 0 || index >= _routes.length) return;
    context.go(_routes[index]);
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

  void _onDestinationSelected(BuildContext context, int index) {
    if (index >= 0 && index < _routes.length) {
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final geo = ref.watch(geolocationProvider);
    final nearbyState = ref.watch(nearbyAchievementsProvider);
    final selectedIndex = _currentIndex(context);

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

        // Layer 2: Page overlay (slides down to reveal map behind)
        AnimatedPositioned(
            duration: _isDraggingOverlay
                ? Duration.zero
                : _isHorizontalSwiping
                    ? Duration.zero
                    : const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
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
                        _isDraggingOverlay = true;
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
                            _slideOffset = (_horizontalDragDelta / sw).clamp(-1.0, 1.0);
                          });
                        } else {
                          final collapsed = _collapsedTopFor(context, navBarHeight);
                          setState(() {
                            _overlayTop = (_overlayTop! + details.delta.dy).clamp(0, collapsed);
                          });
                        }
                      },
                      onPanEnd: (details) {
                        _isDraggingOverlay = false;
                        if (_isHorizontalSwiping) {
                          _onHorizontalDragEnd(context, DragEndDetails(primaryVelocity: details.velocity.pixelsPerSecond.dx), selectedIndex);
                        } else {
                          _handleDragEnd(context, navBarHeight, velocity: details.velocity.pixelsPerSecond.dy);
                        }
                      },
                      onTap: () {
                        final mid = _midTopFor(context, navBarHeight);
                        final collapsed = _collapsedTopFor(context, navBarHeight);
                        // Cycle through snap points: top → mid → bottom → top
                        double target;
                        if (_overlayTop! < mid / 2) {
                          target = mid;
                        } else if (_overlayTop! < (mid + collapsed) / 2) {
                          target = collapsed;
                        } else {
                          target = 0;
                        }
                        _snapOverlayTo(target, strong: true);
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
                    // Page content with overscroll-to-reveal-map + horizontal swipe to switch tabs
                    Expanded(
                      child: _overlayTop! > 10
                          // Overlay is not at top: drag anywhere to reposition, freeze inner scroll
                          ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragStart: (_) {
                                _isDraggingOverlay = true;
                              },
                              onVerticalDragUpdate: (details) {
                                final collapsed = _collapsedTopFor(context, navBarHeight);
                                setState(() {
                                  _overlayTop = (_overlayTop! + details.delta.dy).clamp(0, collapsed);
                                });
                              },
                              onVerticalDragEnd: (details) {
                                _isDraggingOverlay = false;
                                _handleDragEnd(context, navBarHeight, velocity: details.primaryVelocity ?? 0);
                              },
                              child: AbsorbPointer(child: widget.child),
                            )
                          // Overlay is at top: normal vertical scrolling + horizontal swipe to switch tabs
                          : GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragStart: (details) {
                                _horizontalDragStart = details.globalPosition.dx;
                                _horizontalDragDelta = 0;
                                _isHorizontalSwiping = false;
                              },
                              onHorizontalDragUpdate: (details) {
                                _horizontalDragDelta = details.globalPosition.dx - _horizontalDragStart;
                                if (_horizontalDragDelta.abs() > 10) {
                                  _isHorizontalSwiping = true;
                                }
                                if (_isHorizontalSwiping) {
                                  final sw = MediaQuery.of(context).size.width;
                                  setState(() {
                                    _slideOffset = (_horizontalDragDelta / sw).clamp(-1.0, 1.0);
                                  });
                                }
                              },
                              onHorizontalDragEnd: (details) {
                                _onHorizontalDragEnd(context, details, selectedIndex);
                              },
                              child: NotificationListener<OverscrollNotification>(
                                onNotification: (notification) {
                                  // User overscrolling past the top → slide overlay down
                                  if (notification.overscroll < 0) {
                                    final collapsed = _collapsedTopFor(context, navBarHeight);
                                    final delta = notification.overscroll.abs() * 3.0;
                                    _lastOverscrollVelocity = delta * 60;
                                    setState(() {
                                      _isDraggingOverlay = true;
                                      _overlayTop = (_overlayTop! + delta).clamp(0.0, collapsed);
                                    });
                                    return true;
                                  }
                                  return false;
                                },
                                child: NotificationListener<ScrollEndNotification>(
                                  onNotification: (notification) {
                                    if (_isDraggingOverlay) {
                                      _isDraggingOverlay = false;
                                      if (_overlayTop! > 5) {
                                        _handleDragEnd(context, navBarHeight, velocity: _lastOverscrollVelocity);
                                      }
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

        // Layer 3: Bottom nav bar (always visible)
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

// Forces ClampingScrollPhysics so OverscrollNotification fires on all platforms
class _ClampingScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
