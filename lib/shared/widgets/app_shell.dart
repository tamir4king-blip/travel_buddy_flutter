import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/activity_log/presentation/screens/activity_log_screen.dart';
import 'package:travel_buddy_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:travel_buddy_mobile/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:travel_buddy_mobile/features/map/presentation/screens/map_screen.dart';
import 'package:travel_buddy_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/nearby_achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/proximity_alert.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with TickerProviderStateMixin {
  String? _alertAchievementId;
  double _overlayTop = 0;
  bool _isDraggingOverlay = false;
  bool _isExploreMode = false;
  bool _initialized = false;

  // Vertical spring animation controller
  late AnimationController _springController;

  // Horizontal slide animation controller (0 = current page, ±1 = fully slid)
  late AnimationController _slideController;
  int? _slideTargetIndex; // The page index we're sliding towards
  bool _isSlideAnimating = false; // True when auto-animating after drag end

  // Overscroll velocity tracking
  double _overscrollVelocity = 0;

  // Horizontal swipe state
  int _previousIndex = 0;
  double _horizontalDragStart = 0;
  double _horizontalDragDelta = 0;
  bool _isHorizontalSwiping = false;

  static const _routes = ['/', '/log', '/leaderboard', '/profile'];

  static const _pageWidgets = <Widget>[
    HomeScreen(),
    ActivityLogScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  // Spring physics for smooth vertical snapping
  static const _snapSpring = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 28.0,
  );

  @override
  void initState() {
    super.initState();
    _springController = AnimationController.unbounded(vsync: this);
    _springController.addListener(_onSpringTick);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideController.addListener(() => setState(() {}));
    _slideController.addStatusListener(_onSlideAnimationStatus);
  }

  @override
  void dispose() {
    _springController.removeListener(_onSpringTick);
    _springController.dispose();
    _slideController.removeStatusListener(_onSlideAnimationStatus);
    _slideController.dispose();
    super.dispose();
  }

  void _onSpringTick() {
    if (!_isDraggingOverlay) {
      setState(() => _overlayTop = _springController.value);
    }
  }

  void _onSlideAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isSlideAnimating) {
      _isSlideAnimating = false;
      // Navigate to the target page now that slide animation is complete
      if (_slideTargetIndex != null && mounted) {
        final targetIndex = _slideTargetIndex!;
        _slideTargetIndex = null;
        _slideController.value = 0;
        context.go(_routes[targetIndex]);
      } else {
        // Bounced back — just reset
        _slideTargetIndex = null;
      }
    }
  }

  /// Current slide offset as -1..+1.
  /// Positive = sliding right (revealing page to the left, i.e. previous page).
  /// Negative = sliding left (revealing page to the right, i.e. next page).
  double get _slideOffset {
    if (_slideTargetIndex == null) return 0;
    final currentIndex = _previousIndex;
    // Sliding to a higher index = next page = slide left = negative
    if (_slideTargetIndex! > currentIndex) {
      return -_slideController.value;
    } else {
      return _slideController.value;
    }
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location == '/log') return 1;
    if (location == '/leaderboard') return 2;
    if (location == '/profile') return 3;
    return 0;
  }

  // Bottom snap: page peeks with just the drag handle visible
  double _collapsedTopFor(BuildContext context, double navBarHeight) {
    final h = MediaQuery.of(context).size.height;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    const peekHeight = 84.0;
    final collapsed = h - navBarHeight - peekHeight - bottomSafe;
    return collapsed.clamp(0.0, h);
  }

  // Middle snap: page at ~45% of screen
  double _midTopFor(BuildContext context, double navBarHeight) {
    final h = MediaQuery.of(context).size.height;
    return (h * 0.45).clamp(0.0, _collapsedTopFor(context, navBarHeight));
  }

  void _syncOverlayTop(BuildContext context, double navBarHeight,
      {required int currentIndex}) {
    final collapsed = _collapsedTopFor(context, navBarHeight);
    if (!_initialized) {
      _overlayTop = 0;
      _previousIndex = currentIndex;
      _initialized = true;
      return;
    }
    // Reset overlay to fully expanded when switching tabs
    if (_previousIndex != currentIndex) {
      _springController.stop();
      _overlayTop = 0;
      _isExploreMode = false;
    }
    _previousIndex = currentIndex;
    _overlayTop = _overlayTop.clamp(0.0, collapsed);
  }

  /// Animates overlay to [target] using spring physics.
  void _animateTo(double target, {double velocity = 0}) {
    final simulation = SpringSimulation(
      _snapSpring,
      _overlayTop,
      target,
      velocity / 1000,
    );
    _springController.animateWith(simulation);
    setState(() => _isExploreMode = target > 0);
  }

  /// Determines the best vertical snap point.
  void _handleDragEnd(BuildContext context, double navBarHeight,
      {double velocity = 0}) {
    final collapsed = _collapsedTopFor(context, navBarHeight);
    final mid = _midTopFor(context, navBarHeight);
    final current = _overlayTop;

    const top = 0.0;
    final snaps = [top, mid, collapsed];

    double target;

    if (velocity.abs() > 300) {
      if (velocity > 0) {
        target = snaps.where((s) => s > current + 1).firstOrNull ?? collapsed;
      } else {
        target =
            snaps.reversed.where((s) => s < current - 1).firstOrNull ?? top;
      }
    } else {
      double minDist = double.infinity;
      target = top;
      for (final snap in snaps) {
        final dist = (current - snap).abs();
        if (dist < minDist) {
          minDist = dist;
          target = snap;
        }
      }
    }

    if (target == top || target == collapsed) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }

    _animateTo(target, velocity: velocity);
    _isDraggingOverlay = false;
    _overscrollVelocity = 0;
  }

  /// Handles horizontal drag start — always uses physical screen coordinates,
  /// ignoring text direction so swipe behavior is identical in LTR and RTL.
  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isSlideAnimating) return;
    _horizontalDragStart = details.globalPosition.dx;
    _horizontalDragDelta = 0;
    _isHorizontalSwiping = false;
    _slideTargetIndex = null;
    _slideController.value = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, int currentIndex) {
    if (_isSlideAnimating) return;

    // Always use physical dx (left-to-right on screen), ignore RTL layout
    _horizontalDragDelta = details.globalPosition.dx - _horizontalDragStart;

    if (!_isHorizontalSwiping && _horizontalDragDelta.abs() > 10) {
      _isHorizontalSwiping = true;
    }

    if (_isHorizontalSwiping) {
      final sw = MediaQuery.of(context).size.width;
      final rawOffset = (_horizontalDragDelta / sw).clamp(-1.0, 1.0);

      // Determine target: drag left (negative) = next page, drag right (positive) = prev page
      int? target;
      if (rawOffset < 0 && currentIndex < _routes.length - 1) {
        target = currentIndex + 1;
      } else if (rawOffset > 0 && currentIndex > 0) {
        target = currentIndex - 1;
      }

      if (target != null) {
        _slideTargetIndex = target;
        _slideController.value = rawOffset.abs();
      } else {
        // At boundary — apply rubber-band resistance
        _slideTargetIndex = null;
        _slideController.value = rawOffset.abs() * 0.2;
      }
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details, int currentIndex) {
    if (_isSlideAnimating || !_isHorizontalSwiping) {
      _isHorizontalSwiping = false;
      if (!_isSlideAnimating && _slideController.value > 0) {
        // Snap back
        _slideTargetIndex = null;
        _isSlideAnimating = true;
        _slideController.animateTo(0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic);
      }
      return;
    }

    _isHorizontalSwiping = false;

    // Use physical velocity (px/s), not logical
    final velocity = details.primaryVelocity ?? 0;
    final progress = _slideController.value;
    final hasTarget = _slideTargetIndex != null;

    // Decide: commit to navigation or bounce back
    bool commit = false;
    if (hasTarget) {
      if (velocity.abs() > 300) {
        // Fling: commit if fling direction matches slide direction
        final slidingToNext = _slideTargetIndex! > currentIndex;
        commit = slidingToNext ? velocity < 0 : velocity > 0;
      } else {
        // No fling: commit if past 35% threshold
        commit = progress > 0.35;
      }
    }

    _isSlideAnimating = true;

    if (commit && hasTarget) {
      HapticFeedback.selectionClick();
      // Animate to full slide, then navigate on completion
      final remainingFraction = 1.0 - progress;
      final duration = Duration(
        milliseconds: (remainingFraction * 250).round().clamp(100, 250),
      );
      _slideController.animateTo(1.0,
          duration: duration, curve: Curves.easeOutCubic);
    } else {
      // Bounce back
      _slideTargetIndex = null;
      final duration = Duration(
        milliseconds: (progress * 250).round().clamp(100, 250),
      );
      _slideController.animateTo(0,
          duration: duration, curve: Curves.easeOutCubic);
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (index >= 0 && index < _routes.length) {
      _springController.stop();
      _slideController.stop();
      _slideTargetIndex = null;
      _slideController.value = 0;
      _isSlideAnimating = false;
      setState(() {
        _isExploreMode = false;
        _overlayTop = 0;
      });
      context.go(_routes[index]);
    }
  }

  void _toggleExploreMode(BuildContext context, double navBarHeight) {
    final collapsed = _collapsedTopFor(context, navBarHeight);
    if (_isExploreMode) {
      _animateTo(0);
      HapticFeedback.mediumImpact();
    } else {
      _animateTo(collapsed);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final geo = ref.watch(geolocationProvider);
    final nearbyState = ref.watch(nearbyAchievementsProvider);
    final selectedIndex = _currentIndex(context);

    // Listen for newly discovered achievements — show in-app alert banner.
    // Notifications and pending claim marking are handled by the
    // nearbyAchievementsProvider itself, so we only drive the UI here.
    ref.listen(nearbyAchievementsProvider, (prev, next) {
      if (!geo.isLiveTracking) return;
      if (next.newlyDiscovered.isNotEmpty) {
        final achievement = next.newlyDiscovered.first;
        setState(() {
          _alertAchievementId = achievement.id;
        });

        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && _alertAchievementId == achievement.id) {
            setState(() => _alertAchievementId = null);
          }
        });
      }
    });

    final alertAchievement = _alertAchievementId != null
        ? nearbyState.nearby
            .where((a) => a.id == _alertAchievementId)
            .firstOrNull
        : null;

    const navBarHeight = 68.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final bottomNav = _buildCustomNavBar(
      context: context,
      l10n: l10n,
      selectedIndex: selectedIndex,
      navBarHeight: navBarHeight,
    );

    _syncOverlayTop(context, navBarHeight, currentIndex: selectedIndex);

    final screenWidth = MediaQuery.of(context).size.width;
    final collapsed = _collapsedTopFor(context, navBarHeight);

    // Overlay progress 0..1 for visual effects
    final overlayProgress =
        collapsed > 0 ? (_overlayTop / collapsed).clamp(0.0, 1.0) : 0.0;

    // Compute slide translation for horizontal page swipe
    final slideOffset = _slideOffset;
    final slideTranslation = slideOffset * screenWidth;

    // Determine which adjacent page to show
    int? adjIndex;
    if (_slideTargetIndex != null && _slideController.value > 0) {
      adjIndex = _slideTargetIndex;
    }

    final body = Stack(
      children: [
        // Layer 1: Persistent map background
        const Positioned.fill(
          child: MapScreen(),
        ),

        // Layer 2: Page overlay (slides down to reveal map)
        Positioned(
          left: 0,
          right: 0,
          top: _overlayTop,
          bottom: navBarHeight + bottomInset,
          child: Material(
            color: AppColors.bgDark,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(22 * (1.0 - overlayProgress * 0.3))),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                // Drag handle
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    _springController.stop();
                    _horizontalDragStart = details.globalPosition.dx;
                    _horizontalDragDelta = 0;
                    _isHorizontalSwiping = false;
                    _isDraggingOverlay = true;
                  },
                  onPanUpdate: (details) {
                    final dx =
                        details.globalPosition.dx - _horizontalDragStart;
                    _horizontalDragDelta = dx;
                    if (!_isHorizontalSwiping &&
                        dx.abs() > 15 &&
                        dx.abs() > details.delta.dy.abs() * 1.5) {
                      _isHorizontalSwiping = true;
                    }
                    if (_isHorizontalSwiping) {
                      _onHorizontalDragUpdate(
                        DragUpdateDetails(
                          globalPosition: details.globalPosition,
                          delta: details.delta,
                        ),
                        selectedIndex,
                      );
                    } else {
                      setState(() {
                        _overlayTop = (_overlayTop + details.delta.dy)
                            .clamp(0.0, collapsed);
                      });
                    }
                  },
                  onPanEnd: (details) {
                    _isDraggingOverlay = false;
                    if (_isHorizontalSwiping) {
                      _onHorizontalDragEnd(
                        DragEndDetails(
                            primaryVelocity:
                                details.velocity.pixelsPerSecond.dx),
                        selectedIndex,
                      );
                    } else {
                      _handleDragEnd(context, navBarHeight,
                          velocity: details.velocity.pixelsPerSecond.dy);
                    }
                  },
                  onTap: () {
                    final mid = _midTopFor(context, navBarHeight);
                    double target;
                    if (_overlayTop < mid / 2) {
                      target = mid;
                    } else if (_overlayTop < (mid + collapsed) / 2) {
                      target = collapsed;
                    } else {
                      target = 0;
                    }
                    HapticFeedback.mediumImpact();
                    _animateTo(target);
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isDraggingOverlay ? 52 : 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(
                              alpha: _isDraggingOverlay ? 0.8 : 0.55),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                // Page content
                Expanded(
                  child: _overlayTop > 10
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragStart: (_) {
                            _springController.stop();
                            _isDraggingOverlay = true;
                          },
                          onVerticalDragUpdate: (details) {
                            setState(() {
                              _overlayTop = (_overlayTop + details.delta.dy)
                                  .clamp(0.0, collapsed);
                            });
                          },
                          onVerticalDragEnd: (details) {
                            _isDraggingOverlay = false;
                            _handleDragEnd(context, navBarHeight,
                                velocity: details.primaryVelocity ?? 0);
                          },
                          child: AbsorbPointer(child: widget.child),
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragStart: (details) {
                            _onHorizontalDragStart(details);
                          },
                          onHorizontalDragUpdate: (details) {
                            _onHorizontalDragUpdate(details, selectedIndex);
                          },
                          onHorizontalDragEnd: (details) {
                            _onHorizontalDragEnd(details, selectedIndex);
                          },
                          child: ClipRect(
                            child: Stack(
                              children: [
                                // Current page — slides with the finger
                                Transform.translate(
                                  offset: Offset(slideTranslation, 0),
                                  child: SizedBox(
                                    width: screenWidth,
                                    child: NotificationListener<
                                        OverscrollNotification>(
                                      onNotification: (notification) {
                                        if (notification.overscroll < 0) {
                                          _springController.stop();
                                          final rawDelta =
                                              notification.overscroll.abs();
                                          final dampingFactor = 1.0 -
                                              (_overlayTop / collapsed)
                                                  .clamp(0.0, 0.85);
                                          final delta =
                                              rawDelta * 1.8 * dampingFactor;
                                          _overscrollVelocity = delta * 60;
                                          setState(() {
                                            _isDraggingOverlay = true;
                                            _overlayTop =
                                                (_overlayTop + delta)
                                                    .clamp(0.0, collapsed);
                                          });
                                          return true;
                                        }
                                        return false;
                                      },
                                      child: NotificationListener<
                                          ScrollEndNotification>(
                                        onNotification: (notification) {
                                          if (_isDraggingOverlay) {
                                            _isDraggingOverlay = false;
                                            if (_overlayTop > 5) {
                                              _handleDragEnd(
                                                  context, navBarHeight,
                                                  velocity:
                                                      _overscrollVelocity);
                                            } else {
                                              _animateTo(0);
                                            }
                                          }
                                          return false;
                                        },
                                        child: ScrollConfiguration(
                                          behavior:
                                              _ClampingScrollBehavior(),
                                          child: widget.child,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Adjacent page — slides in from the opposite edge
                                if (adjIndex != null)
                                  Transform.translate(
                                    offset: Offset(
                                      slideOffset > 0
                                          ? -screenWidth + slideTranslation
                                          : screenWidth + slideTranslation,
                                      0,
                                    ),
                                    child: SizedBox(
                                      width: screenWidth,
                                      height: double.infinity,
                                      child: Material(
                                        color: AppColors.bgDark,
                                        child: AbsorbPointer(
                                          child: _pageWidgets[adjIndex],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        // Layer 3: Bottom nav bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: navBarHeight + bottomInset,
          child: bottomNav,
        ),
      ],
    );

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
                      ? geo.distanceTo(alertAchievement.latitude!,
                          alertAchievement.longitude!)
                      : 0,
                  onClaim: () {
                    // Dismiss the alert — claiming happens on the achievements page
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

  Widget _buildCustomNavBar({
    required BuildContext context,
    required AppLocalizations l10n,
    required int selectedIndex,
    required double navBarHeight,
  }) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final leftTabs = [
      _NavTabData(LucideIcons.home, l10n.navHome, 0),
      _NavTabData(LucideIcons.bookOpen, l10n.navLog, 1),
    ];
    final rightTabs = [
      _NavTabData(LucideIcons.trophy, l10n.navRankings, 2),
      _NavTabData(LucideIcons.user, l10n.navProfile, 3),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: navBarHeight + bottomInset,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              border: Border(
                top: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset,
          height: navBarHeight,
          child: Row(
            children: [
              ...leftTabs.map((tab) => Expanded(
                    child: _buildNavTab(
                      context: context,
                      icon: tab.icon,
                      label: tab.label,
                      index: tab.index,
                      selectedIndex: selectedIndex,
                    ),
                  )),
              const Expanded(child: SizedBox()),
              ...rightTabs.map((tab) => Expanded(
                    child: _buildNavTab(
                      context: context,
                      icon: tab.icon,
                      label: tab.label,
                      index: tab.index,
                      selectedIndex: selectedIndex,
                    ),
                  )),
            ],
          ),
        ),
        Positioned(
          bottom: bottomInset + navBarHeight - 40,
          left: 0,
          right: 0,
          child: Center(
            child: _buildExploreButton(
                context, AppLocalizations.of(context)!, navBarHeight),
          ),
        ),
      ],
    );
  }

  Widget _buildNavTab({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required int selectedIndex,
  }) {
    final isSelected = index == selectedIndex && !_isExploreMode;
    const duration = Duration(milliseconds: 250);
    const curve = Curves.easeOutCubic;
    final activeColor = AppColors.primaryLight;
    final inactiveColor = AppColors.textMuted.withValues(alpha: 0.6);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onDestinationSelected(context, index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Selection indicator dot
          AnimatedContainer(
            duration: duration,
            curve: curve,
            width: isSelected ? 16 : 0,
            height: 3,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          // Animated icon with scale
          TweenAnimationBuilder<double>(
            tween: Tween(end: isSelected ? 1.15 : 1.0),
            duration: duration,
            curve: curve,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(isSelected),
                size: 20,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: duration,
            curve: curve,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? activeColor : inactiveColor,
              decoration: TextDecoration.none,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreButton(
      BuildContext context, AppLocalizations l10n, double navBarHeight) {
    const buttonSize = 56.0;
    const duration = Duration(milliseconds: 280);
    const curve = Curves.easeOutCubic;

    return GestureDetector(
      onTap: () => _toggleExploreMode(context, navBarHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: _isExploreMode ? 1.1 : 1.0),
            duration: duration,
            curve: curve,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: AnimatedContainer(
              duration: duration,
              curve: curve,
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isExploreMode
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _isExploreMode ? null : AppColors.bgCardLight,
                boxShadow: _isExploreMode
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.globe,
                  key: ValueKey(_isExploreMode),
                  size: 26,
                  color: _isExploreMode ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: duration,
            curve: curve,
            style: TextStyle(
              fontSize: 10,
              fontWeight: _isExploreMode ? FontWeight.w600 : FontWeight.w400,
              color: _isExploreMode
                  ? AppColors.primaryLight
                  : AppColors.textMuted.withValues(alpha: 0.6),
              decoration: TextDecoration.none,
            ),
            child: Text(l10n.navExplore),
          ),
        ],
      ),
    );
  }
}

class _NavTabData {
  final IconData icon;
  final String label;
  final int index;
  const _NavTabData(this.icon, this.label, this.index);
}

class _ClampingScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
