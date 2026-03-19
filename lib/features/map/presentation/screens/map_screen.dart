import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/models/map_marker_item.dart';
import 'package:travel_buddy_mobile/features/map/presentation/map_view.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/achievement_marker.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/map_filter_bar.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/map_pin_popup.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_camera_provider.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_filter_provider.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/shared/models/skill_group.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/achievement_unlock_popup.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/skills_provider.dart';

const _mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  late final PlatformMapController _mapController;
  bool _mapReady = false;
  bool _mapInitialized = false;

  // Cached provider references — captured early so dispose() never touches ref
  late final StateController<CachedCameraState?> _cameraStateNotifier;

  // Detail sheet state
  Achievement? _selectedAchievement;
  SideQuest? _selectedQuest;
  SkillGroup? _selectedSkill;
  bool _showDetailSheet = false;

  // Animation controllers
  late AnimationController _sheetAnimController;
  late AnimationController _controlsFadeController;
  final DraggableScrollableController _sheetScrollController =
      DraggableScrollableController();

  // Long-press context menu
  bool _showLongPressMenu = false;

  // Pin popup state
  bool _showPopup = false;
  final ValueNotifier<Offset> _popupPosNotifier =
      ValueNotifier(Offset.zero);
  String _popupTitle = '';
  String _popupSubtitle = '';
  Color _popupColor = Colors.white;
  IconData _popupIcon = LucideIcons.mapPin;
  String _popupMarkerId = '';
  // Cached data for "View more"
  Achievement? _popupAchievement;
  SideQuest? _popupQuest;
  SkillGroup? _popupSkill;
  late AnimationController _popupAnimController;

  @override
  void initState() {
    super.initState();
    // Cache provider references before any async work — ref is safe here
    _cameraStateNotifier = ref.read(cachedCameraStateProvider.notifier);

    _mapController = createMapController(token: _mapboxToken);
    _mapController.onMarkerClick = _onMarkerClick;
    _mapController.onMapLongPress = _onMapLongPress;
    _mapController.onMapClick = (_,__) {
      _dismissPopup();
      _dismissDetailSheet();
    };
    _mapController.onCameraChanged = _onCameraChanged;

    _sheetAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _popupAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _controlsFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 0,
    );

    // Show system bars with transparent backgrounds so the map feels full-screen
    // but the status bar and navigation buttons remain visible.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgDark,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: true,
    ));

    // Kick off a one-shot location fetch so we have a position to center on
    Future.microtask(() {
      if (!mounted) return;
      final geo = ref.read(geolocationProvider);
      if (!geo.hasLocation) {
        ref.read(geolocationProvider.notifier).getCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    // Detach callbacks so async map operations don't call back into disposed state
    _mapController.onMarkerClick = null;
    _mapController.onMapLongPress = null;
    _mapController.onMapClick = null;
    _mapController.onCameraChanged = null;
    _mapController.onStateChanged = null;

    // Restore default system UI with opaque nav bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.bgDark,
      systemNavigationBarContrastEnforced: true,
    ));
    // Save camera state using cached notifier — no ref access needed
    _saveCameraState();
    _sheetAnimController.dispose();
    _sheetScrollController.dispose();
    _controlsFadeController.dispose();
    _popupAnimController.dispose();
    _popupPosNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _saveCameraState() async {
    try {
      final state = await _mapController.getCameraState();
      if (state != null) {
        _cameraStateNotifier.state = CachedCameraState(
          latitude: state.lat,
          longitude: state.lng,
          zoom: state.zoom,
        );
      }
    } catch (_) {
      // Map controller may already be disposed — safe to ignore
    }
  }

  void _onMapReady() {
    if (!mounted) return;
    setState(() => _mapInitialized = true);
    _controlsFadeController.forward();

    _mapReady = true;
  }

  void _onMarkerClick(String markerId, MapMarkerType type) {
    if (!mounted) return;
    _dismissLongPressMenu();

    // Same pin tapped again — dismiss popup
    if (_showPopup && _popupMarkerId == markerId) {
      _dismissPopup();
      return;
    }

    switch (type) {
      case MapMarkerType.achievement:
        final achievements = ref.read(achievementsProvider);
        final achievement = achievements.allAchievements
            .where((a) => a.id == markerId)
            .firstOrNull;
        if (achievement != null) {
          _showPinPopup(
            markerId: markerId,
            lat: achievement.latitude!,
            lng: achievement.longitude!,
            title: achievement.title,
            subtitle: achievement.collectionId ?? '',
            color: AchievementMarker.tierColor(achievement.tier),
            icon: LucideIcons.trophy,
            achievement: achievement,
          );
        }
      case MapMarkerType.quest:
        final quests = ref.read(questsProvider);
        final quest = quests.allQuests
            .where((q) => q.id == markerId)
            .firstOrNull;
        if (quest != null) {
          _showPinPopup(
            markerId: markerId,
            lat: quest.latitude!,
            lng: quest.longitude!,
            title: quest.title,
            subtitle: quest.category,
            color: QuestMarkerItem(quest: quest).pinColor,
            icon: LucideIcons.swords,
            quest: quest,
          );
        }
      case MapMarkerType.skill:
        final skills = ref.read(skillsProvider);
        final skill = skills.getSkillById(markerId);
        if (skill != null) {
          _showPinPopup(
            markerId: markerId,
            lat: skill.latitude!,
            lng: skill.longitude!,
            title: skill.name,
            subtitle: skill.description,
            color: SkillMarkerItem(skill: skill).pinColor,
            icon: LucideIcons.sparkles,
            skill: skill,
          );
        }
    }
  }

  Future<void> _showPinPopup({
    required String markerId,
    required double lat,
    required double lng,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    Achievement? achievement,
    SideQuest? quest,
    SkillGroup? skill,
  }) async {
    // If another popup is showing, dismiss it instantly first
    if (_showPopup) {
      _popupAnimController.value = 0;
    }

    final pos = await _mapController.pixelForCoordinate(lat, lng);
    if (pos == null || !mounted) return;

    _popupPosNotifier.value = Offset(pos.x, pos.y);
    _popupTitle = title;
    _popupSubtitle = subtitle;
    _popupColor = color;
    _popupIcon = icon;
    _popupMarkerId = markerId;
    _popupAchievement = achievement;
    _popupQuest = quest;
    _popupSkill = skill;

    setState(() => _showPopup = true);
    _popupAnimController.forward(from: 0);
  }

  void _dismissPopup() {
    if (!_showPopup) return;
    if (_radiusVisible) {
      _mapController.clearRadiusCircle();
      _radiusVisible = false;
    }
    _popupAnimController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _showPopup = false;
        _popupMarkerId = '';
        _popupAchievement = null;
        _popupQuest = null;
        _popupSkill = null;
      });
    });
  }

  void _popupViewMore() {
    final achievement = _popupAchievement;
    final quest = _popupQuest;
    final skill = _popupSkill;
    if (_radiusVisible) {
      _mapController.clearRadiusCircle();
      _radiusVisible = false;
    }
    // Quick dismiss without waiting for animation
    _popupAnimController.value = 0;
    setState(() {
      _showPopup = false;
      _popupMarkerId = '';
      _popupAchievement = null;
      _popupQuest = null;
      _popupSkill = null;
    });
    _openDetailSheet(achievement: achievement, quest: quest, skill: skill);
  }

  bool _radiusVisible = false;

  void _popupShowRadius() {
    final achievement = _popupAchievement;
    if (achievement == null || achievement.claimRadius == null) return;
    if (achievement.latitude == null || achievement.longitude == null) return;

    // Toggle: if radius is already showing, clear it
    if (_radiusVisible) {
      _mapController.clearRadiusCircle();
      _radiusVisible = false;
      return;
    }

    _radiusVisible = true;
    _mapController.showRadiusCircle(
      achievement.latitude!,
      achievement.longitude!,
      achievement.claimRadius!,
      _popupColor,
    );
  }

  void _onCameraChanged() {
    // Dismiss popup instantly when user pans/zooms — avoids expensive
    // pixelForCoordinate calls on every frame which cause severe lag.
    if (_showPopup) {
      if (_radiusVisible) {
        _mapController.clearRadiusCircle();
        _radiusVisible = false;
      }
      _popupAnimController.value = 0;
      setState(() {
        _showPopup = false;
        _popupMarkerId = '';
        _popupAchievement = null;
        _popupQuest = null;
        _popupSkill = null;
      });
    }
  }

  void _openDetailSheet(
      {Achievement? achievement, SideQuest? quest, SkillGroup? skill}) {
    setState(() {
      _selectedAchievement = achievement;
      _selectedQuest = quest;
      _selectedSkill = skill;
      _showDetailSheet = true;
    });
    _sheetAnimController.forward(from: 0);
  }

  void _dismissDetailSheet() {
    if (!_showDetailSheet) return;
    _sheetAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedAchievement = null;
          _selectedQuest = null;
          _selectedSkill = null;
          _showDetailSheet = false;
        });
      }
    });
  }

  void _onMapLongPress(double lat, double lng) {
    if (!mounted) return;
    _dismissPopup();
    _dismissDetailSheet();
    HapticFeedback.mediumImpact();
    setState(() {
      _showLongPressMenu = true;
    });
  }

  void _dismissLongPressMenu() {
    if (_showLongPressMenu) {
      setState(() => _showLongPressMenu = false);
    }
  }

  void _exitMap() {
    _saveCameraState();
    ref.read(mapImmersiveProvider.notifier).state = false;
    context.go('/');
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    final q = query.trim().toLowerCase();

    // Search across all markers for a match
    final achievements = ref.read(achievementsProvider);
    final quests = ref.read(questsProvider);
    final skills = ref.read(skillsProvider);

    // Try achievements
    for (final a in achievements.allAchievements) {
      if (a.latitude != null &&
          a.longitude != null &&
          a.title.toLowerCase().contains(q)) {
        _mapController.flyTo(a.latitude!, a.longitude!, 2000);
        return;
      }
    }
    // Try quests
    for (final quest in quests.allQuests) {
      if (quest.latitude != null &&
          quest.longitude != null &&
          quest.title.toLowerCase().contains(q)) {
        _mapController.flyTo(quest.latitude!, quest.longitude!, 2000);
        return;
      }
    }
    // Try skills
    for (final s in skills.allSkills) {
      if (s.latitude != null &&
          s.longitude != null &&
          s.name.toLowerCase().contains(q)) {
        _mapController.flyTo(s.latitude!, s.longitude!, 2000);
        return;
      }
    }
  }

  void _centerOnUser() {
    final geo = ref.read(geolocationProvider);
    if (geo.hasLocation) {
      _mapController.flyTo(geo.latitude!, geo.longitude!, 2000);
    } else {
      ref.read(geolocationProvider.notifier).getCurrentLocation();
    }
  }

  void _updateMapState() {
    if (!mounted || !_mapController.isInitialized) return;

    final geo = ref.read(geolocationProvider);
    final achievements = ref.read(achievementsProvider);
    final quests = ref.read(questsProvider);
    final skills = ref.read(skillsProvider);
    final filter = ref.read(mapFilterProvider);

    final markers = <MapMarkerItem>[];

    if (filter.showAchievements) {
      for (final a in achievements.allAchievements) {
        if (a.latitude != null && a.longitude != null) {
          if (filter.selectedAchievementCollections.isNotEmpty &&
              !filter.selectedAchievementCollections.contains(a.collectionId)) {
            continue;
          }
          markers.add(AchievementMarkerItem(achievement: a));
        }
      }
    }

    if (filter.showQuests) {
      for (final q in quests.allQuests) {
        if (q.latitude != null && q.longitude != null) {
          if (filter.selectedQuestCategories.isNotEmpty &&
              !filter.selectedQuestCategories.contains(q.category)) {
            continue;
          }
          markers.add(QuestMarkerItem(quest: q));
        }
      }
    }

    if (filter.showSkills) {
      for (final s in skills.allSkills) {
        if (s.latitude != null && s.longitude != null) {
          if (filter.selectedSkillIds.isNotEmpty && !filter.selectedSkillIds.contains(s.id)) {
            continue;
          }
          markers.add(SkillMarkerItem(skill: s));
        }
      }
    }

    _mapController.setMarkers(markers);

    if (geo.hasLocation) {
      _mapController.setUserLocation(geo.latitude!, geo.longitude!);
    }

    if (!_mapReady && geo.hasLocation) {
      _mapReady = true;
      final cached = ref.read(cachedCameraStateProvider);
      if (cached == null) {
        _mapController.flyTo(geo.latitude!, geo.longitude!, 5000);
      }
    }
  }


  // ── Inline detail sheet content builders ──

  Widget _buildSheetContent(ScrollController sc) {
    if (_selectedAchievement != null) {
      return _buildAchievementContent(sc);
    } else if (_selectedQuest != null) {
      return _buildQuestContent(sc);
    } else if (_selectedSkill != null) {
      return _buildSkillContent(sc);
    }
    return const SizedBox.shrink();
  }

  Widget _buildAchievementContent(ScrollController sc) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final geo = ref.read(geolocationProvider);
    final achievementsNotifier = ref.read(achievementsProvider.notifier);
    final achievement = _selectedAchievement!;

    final distance = geo.hasLocation && achievement.latitude != null
        ? geo.distanceTo(achievement.latitude!, achievement.longitude!)
        : double.infinity;
    final inRange =
        achievement.claimRadius != null && distance <= achievement.claimRadius!;

    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AchievementMarker.tierColor(achievement.tier),
              ),
              child: Icon(
                achievement.isUnlocked
                    ? LucideIcons.check
                    : LucideIcons.trophy,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RegistryL10n.achievementTitle(
                        locale, achievement.id, achievement.title),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+${achievement.xpReward} XP',
                    style: const TextStyle(
                      color: AppColors.xpGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          RegistryL10n.achievementDescription(
              locale, achievement.id, achievement.description),
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        if (distance != double.infinity)
          Text(
            distance < 1000
                ? '${distance.round()}m ${l10n.distanceAway}'
                : '${(distance / 1000).toStringAsFixed(1)}km ${l10n.distanceAway}',
            style: TextStyle(
              color: inRange ? AppColors.success : AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 16),
        if (!achievement.isUnlocked)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: inRange
                  ? () async {
                      final claimed = await achievementsNotifier.claimAchievement(
                        achievement.id,
                        userLat: geo.latitude,
                        userLng: geo.longitude,
                      );
                      _dismissDetailSheet();
                      if (claimed && context.mounted) {
                        await AchievementUnlockPopup.show(
                            context, achievement);
                      }
                    }
                  : null,
              child: Text(inRange ? l10n.claim : l10n.getCloser),
            ),
          )
        else
          Center(
            child: Text(
              l10n.unlocked,
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestContent(ScrollController sc) {
    final quest = _selectedQuest!;
    final difficultyLabel = switch (quest.difficulty) {
      QuestDifficulty.easy => 'Easy',
      QuestDifficulty.medium => 'Medium',
      QuestDifficulty.hard => 'Hard',
      QuestDifficulty.legendary => 'Legendary',
    };
    final difficultyColor = switch (quest.difficulty) {
      QuestDifficulty.easy => AppColors.success,
      QuestDifficulty.medium => AppColors.accent,
      QuestDifficulty.hard => const Color(0xFFF97316),
      QuestDifficulty.legendary => const Color(0xFF9333EA),
    };

    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: difficultyColor,
              ),
              child: const Icon(
                LucideIcons.swords,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: difficultyColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          difficultyLabel,
                          style: TextStyle(
                            color: difficultyColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${quest.xpReward} XP',
                        style: const TextStyle(
                          color: AppColors.xpGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          quest.description,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(LucideIcons.tag, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              quest.category,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (quest.isCompleted)
          Center(
            child: Text(
              AppLocalizations.of(context)!.unlocked,
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillContent(ScrollController sc) {
    final locale = Localizations.localeOf(context);
    final skill = _selectedSkill!;
    final questsState = ref.read(questsProvider);
    final level = questsState.skillLevels[skill.id] ?? 0;

    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SkillMarkerItem.parseHexColor(skill.gradientStart),
              ),
              child: Center(
                child: Text(
                  skill.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RegistryL10n.skillName(locale, skill.id, skill.name),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppLocalizations.of(context)!.level} $level / ${skill.maxLevel}',
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          RegistryL10n.skillDescription(
              locale, skill.id, skill.description),
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final geo = ref.watch(geolocationProvider);
    ref.watch(achievementsProvider);
    ref.watch(questsProvider);
    ref.watch(skillsProvider);
    ref.watch(mapFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    // Listen for camera commands from AppShell (explore button taps)
    ref.listen(mapCameraCommandProvider, (prev, next) {
      if (next == null || !_mapController.isInitialized) return;
      switch (next) {
        case CenterOnUserCommand():
          final g = ref.read(geolocationProvider);
          if (g.hasLocation) {
            _mapController.animateCamera(
                g.latitude!, g.longitude!, 14.0,
                durationMs: 1200);
          }
          ref.read(isGlobeViewProvider.notifier).state = false;
        case ZoomToGlobeCommand():
          _mapController.animateCamera(20.0, 0.0, 2.0, durationMs: 1200);
          ref.read(isGlobeViewProvider.notifier).state = true;
      }
      Future.microtask(
          () => ref.read(mapCameraCommandProvider.notifier).state = null);
    });

    // Update map entities whenever state changes
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateMapState());

    return PopScope(
      canPop: !_showDetailSheet,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismissDetailSheet();
      },
      child: Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          children: [
            // Platform map (fills safe area)
            Positioned.fill(
              child: PlatformMapViewWidget(
                controller: _mapController,
                onMapReady: _onMapReady,
              ),
            ),

            // Loading shimmer overlay
            if (!_mapInitialized)
              Positioned.fill(
                child: _MapLoadingShimmer(),
              ),

            // Top bar: close button + search bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _controlsFadeController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      _MapControlButton(
                        icon: LucideIcons.x,
                        onTap: _exitMap,
                        tooltip: l10n.mapCloseMap,
                        size: 40,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MapSearchBar(
                          onSearch: _onSearchSubmitted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Left side: map controls (compass, location, zoom)
            Positioned(
              left: 16,
              bottom: 50,
              child: FadeTransition(
                opacity: _controlsFadeController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapControlButton(
                      icon: LucideIcons.compass,
                      onTap: () => _mapController.resetCompass(),
                      tooltip: l10n.mapResetCompass,
                    ),
                    const SizedBox(height: 10),
                    _MapControlButton(
                      icon: LucideIcons.crosshair,
                      onTap: _centerOnUser,
                      tooltip: l10n.mapMyLocation,
                      highlighted: true,
                    ),
                    const SizedBox(height: 10),
                    _MapControlButton(
                      icon: LucideIcons.plus,
                      onTap: () => _mapController.zoomIn(),
                      tooltip: l10n.mapZoomIn,
                    ),
                    const SizedBox(height: 10),
                    _MapControlButton(
                      icon: LucideIcons.minus,
                      onTap: () => _mapController.zoomOut(),
                      tooltip: l10n.mapZoomOut,
                    ),
                  ],
                ),
              ),
            ),

            // Right side: filter bubbles (bottom-right)
            Positioned(
              right: 16,
              bottom: 50,
              child: FadeTransition(
                opacity: _controlsFadeController,
                child: const MapFilterBar(),
              ),
            ),

            // Live tracking indicator
            if (geo.isLiveTracking)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 100),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fadeIn(duration: 800.ms)
                              .fadeOut(duration: 800.ms),
                          const SizedBox(width: 6),
                          Text(
                            l10n.trackingActive,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // Pin popup (appears above tapped pin)
            if (_showPopup)
              ValueListenableBuilder<Offset>(
                valueListenable: _popupPosNotifier,
                builder: (context, screenPos, _) {
                  return MapPinPopup(
                    title: _popupTitle,
                    subtitle: _popupSubtitle,
                    color: _popupColor,
                    icon: _popupIcon,
                    screenPosition: screenPos,
                    animation: _popupAnimController,
                    onViewMore: _popupViewMore,
                    onShowRadius: _popupAchievement?.claimRadius != null
                        ? _popupShowRadius
                        : null,
                    onDismiss: _dismissPopup,
                  );
                },
              ),

            // Bottom sheet — always present as a peek handle, expands when detail is loaded
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _sheetAnimController,
                builder: (context, child) {
                  final value = CurvedAnimation(
                    parent: _sheetAnimController,
                    curve: Curves.easeOutCubic,
                  ).value;
                  // Peek height for the "waiting" handle strip
                  const peekHeight = 28.0;
                  // Expanded sheet height: 40% of screen
                  final screenHeight = MediaQuery.of(context).size.height;
                  final expandedHeight = screenHeight * 0.85;
                  final currentHeight = peekHeight + (expandedHeight - peekHeight) * value;
                  return SizedBox(
                    height: currentHeight,
                    child: child,
                  );
                },
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    if (_showDetailSheet && notification.extent <= 0.06) {
                      _dismissDetailSheet();
                    }
                    return false;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag handle — always visible
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Content — only when detail sheet is active
                        if (_showDetailSheet)
                          Expanded(
                            child: DraggableScrollableSheet(
                              controller: _sheetScrollController,
                              initialChildSize: 1.0,
                              minChildSize: 0.05,
                              maxChildSize: 1.0,
                              builder: (context, scrollController) =>
                                  _buildSheetContent(scrollController),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Long-press context menu
            if (_showLongPressMenu)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildLongPressMenu(l10n),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLongPressMenu(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LongPressMenuItem(
            icon: LucideIcons.swords,
            label: l10n.mapStartQuestHere,
            color: AppColors.accent,
            onTap: () {
              _dismissLongPressMenu();
              // TODO: Navigate to quest creation with lat/lng
            },
          ),
          Divider(
            height: 1,
            color: AppColors.textMuted.withValues(alpha: 0.15),
            indent: 52,
          ),
          _LongPressMenuItem(
            icon: LucideIcons.mapPin,
            label: l10n.mapLogVisit,
            color: AppColors.primary,
            onTap: () {
              _dismissLongPressMenu();
              // TODO: Navigate to log visit with lat/lng
            },
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.3, end: 0, duration: 250.ms, curve: Curves.easeOutCubic);
  }
}

// ── Supporting Widgets ──

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool highlighted;
  final double size;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.highlighted = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.bgCard.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: highlighted
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.textMuted.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: size * 0.45,
          color: highlighted ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _LongPressMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LongPressMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search bar for finding map markers by name.
class _MapSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;

  const _MapSearchBar({required this.onSearch});

  @override
  State<_MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<_MapSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hasFocus
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.textMuted.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            LucideIcons.search,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                hintText: 'Search pins...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                widget.onSearch(value);
                _focusNode.unfocus();
              },
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Loading shimmer shown while the map widget initializes.
class _MapLoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgCard,
              ),
              child: const Icon(
                LucideIcons.globe,
                size: 32,
                color: AppColors.primary,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 1200.ms)
                .fade(begin: 0.5, end: 1.0, duration: 1200.ms),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.searchAchievements ??
                  'Loading map...',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
