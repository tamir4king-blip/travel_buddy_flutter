import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/core/utils/error_logger.dart';
import 'package:travel_buddy_mobile/features/achievements/presentation/widgets/achievement_detail_sheet.dart';
import 'package:travel_buddy_mobile/features/map/models/map_marker_item.dart';
import 'package:travel_buddy_mobile/features/map/presentation/map_view.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/achievement_marker.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/area_colors.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/map_filter_tab_bar.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/filter_sheets/bubble_quick_filters.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/filter_sheets/unified_filter_sheet.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/map_pin_popup.dart';
import 'package:travel_buddy_mobile/features/map/providers/current_country_provider.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_camera_provider.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_filter_provider.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/shared/models/skill_group.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/models/quest.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quest_chain_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/skills_provider.dart';
import 'package:travel_buddy_mobile/shared/utils/geo_utils.dart';

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

  // Memoized marker list to avoid redundant setMarkers calls
  List<MapMarkerItem>? _lastMarkers;
  double? _lastUserLat;
  double? _lastUserLng;

  // Memoized per-collection overlay state so we don't re-render every frame.
  String? _lastUnlockedAreasSignature;

  // Detail sheet state (achievements route to the canonical
  // AchievementDetailSheet — only quest/skill/chain use the inline sheet).
  SideQuest? _selectedQuest;
  SkillGroup? _selectedSkill;
  Quest? _selectedQuestChain;
  Color _selectedOutlineColor = Colors.white;
  bool _showDetailSheet = false;

  // Filter sheet state
  // _showFilterSheet → hovering bubble quick-filter column above the
  // filter button. _showAdvancedSheet → full advanced filter sheet
  // opened from the column's "Advanced settings" entry.
  bool _showFilterSheet = false;
  bool _showAdvancedSheet = false;

  // Animation controllers
  late AnimationController _sheetAnimController;
  late AnimationController _controlsFadeController;
  // Drives the top bar slide-up + height collapse when entering fullscreen.
  // value 0 = top bar visible, value 1 = top bar hidden (slid up off-screen).
  late AnimationController _immersiveController;

  // Long-press context menu (disabled — TODO: implement when needed)

  // Pin popup state
  bool _showPopup = false;
  String _popupTitle = '';
  String _popupSubtitle = '';
  Color _popupColor = Colors.white;
  Color _popupOutlineColor = Colors.white;
  IconData _popupIcon = LucideIcons.mapPin;
  String _popupMarkerId = '';
  // Cached data for "View more"
  Achievement? _popupAchievement;
  SideQuest? _popupQuest;
  SkillGroup? _popupSkill;
  Quest? _popupQuestChain;
  late AnimationController _popupAnimController;

  // Guard: when a marker tap fires, suppress the map-click dismiss
  // because Mapbox fires both annotation-tap and map-tap for the same touch.
  bool _markerTapConsumed = false;

  @override
  void initState() {
    super.initState();
    // Cache provider references before any async work — ref is safe here
    _cameraStateNotifier = ref.read(cachedCameraStateProvider.notifier);

    _mapController = createMapController(token: _mapboxToken);
    _mapController.onMarkerClick = _onMarkerClick;
    _mapController.onMapLongPress = null;
    _mapController.onMapClick = _onMapClick;
    _mapController.onCameraChanged = _onCameraChanged;

    _sheetAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _popupAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _controlsFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 0,
    );
    _immersiveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
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
    _controlsFadeController.dispose();
    _immersiveController.dispose();
    _popupAnimController.dispose();
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
    } catch (e, st) {
      // Map controller may already be disposed — safe to ignore
      logError(e, st, context: 'map.cacheCameraState');
    }
  }

  void _onMapReady() {
    if (!mounted) return;
    setState(() => _mapInitialized = true);
    _controlsFadeController.forward();

    _mapReady = true;
  }

  void _onMapClick(double lat, double lng) {
    // If a marker tap already handled this touch, skip
    if (_markerTapConsumed) return;
    _dismissPopup();
    _dismissDetailSheet();
    if (_showFilterSheet || _showAdvancedSheet) {
      setState(() {
        _showFilterSheet = false;
        _showAdvancedSheet = false;
      });
    }
  }

  void _onMarkerClick(String markerId, MapMarkerType type) {
    if (!mounted) return;
    _dismissLongPressMenu();

    // Prevent the map-click handler from also firing for this touch
    _markerTapConsumed = true;
    Future.microtask(() => _markerTapConsumed = false);

    // Same pin tapped again — toggle off with animation
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
          final tierColor = AchievementMarker.tierColor(achievement.tier);
          final collectionId = achievement.collectionId;
          _showPinPopup(
            markerId: markerId,
            lat: achievement.latitude!,
            lng: achievement.longitude!,
            title: achievement.title,
            subtitle: achievement.collectionId ?? '',
            color: tierColor,
            outlineColor:
                collectionId != null ? colorForCollection(collectionId) : tierColor,
            icon: LucideIcons.trophy,
            achievement: achievement,
          );
        }
      case MapMarkerType.quest:
        final questId = markerId.contains('@') ? markerId.split('@').first : markerId;
        final quests = ref.read(questsProvider);
        final quest = quests.allQuests
            .where((q) => q.id == questId)
            .firstOrNull;
        if (quest != null) {
          _showPinPopup(
            markerId: markerId,
            lat: quest.latitude!,
            lng: quest.longitude!,
            title: quest.title,
            subtitle: quest.category,
            color: QuestMarkerItem(quest: quest).pinColor,
            outlineColor: AppColors.error,
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
      case MapMarkerType.questChain:
        final chainId = markerId.replaceFirst('chain-', '');
        final chains = ref.read(questChainProvider);
        final chain = chains.allQuests
            .where((q) => q.id == chainId)
            .firstOrNull;
        if (chain != null) {
          // Look up the first step's activity location
          final quests = ref.read(questsProvider);
          final firstActivity = quests.allQuests
              .where((q) => q.id == chain.steps.first.targetId)
              .firstOrNull;
          if (firstActivity != null &&
              firstActivity.latitude != null &&
              firstActivity.longitude != null) {
            _showPinPopup(
              markerId: markerId,
              lat: firstActivity.latitude!,
              lng: firstActivity.longitude!,
              title: '${chain.icon} ${chain.title}',
              subtitle: '${chain.totalSteps} steps · ${chain.rarity.name}',
              color: QuestChainMarkerItem.rarityColor(chain.rarity),
              outlineColor: AppColors.error,
              icon: LucideIcons.scroll,
              questChain: chain,
            );
          }
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
    Color? outlineColor,
    Achievement? achievement,
    SideQuest? quest,
    SkillGroup? skill,
    Quest? questChain,
  }) async {
    // Clear any previous radius circle
    if (_radiusVisible) {
      _mapController.clearRadiusCircle();
      _radiusVisible = false;
    }

    // If another popup is showing, reset instantly (no reverse animation)
    if (_showPopup) {
      _popupAnimController.stop();
      _popupAnimController.value = 0;
    }

    if (!mounted) return;

    _popupTitle = title;
    _popupSubtitle = subtitle;
    _popupColor = color;
    _popupOutlineColor = outlineColor ?? color;
    _popupIcon = icon;
    _popupMarkerId = markerId;
    _popupAchievement = achievement;
    _popupQuest = quest;
    _popupSkill = skill;
    _popupQuestChain = questChain;

    // Mark the pin as selected — draws the black arrow above it
    _mapController.setSelectedMarker(markerId);

    setState(() => _showPopup = true);
    _popupAnimController.forward(from: 0);

    // Auto-show the area overlay (radius or polygon) whenever a pin with
    // a geofence is opened, so the user immediately sees its claim zone.
    if (achievement != null && achievement.hasGeofence) {
      _popupShowRadius();
    }
  }

  void _dismissPopup() {
    if (!_showPopup) return;
    if (_radiusVisible) {
      _mapController.clearRadiusCircle();
      _radiusVisible = false;
    }
    // Clear marker ID immediately to prevent re-trigger race conditions
    _popupMarkerId = '';
    _popupAchievement = null;
    _popupQuest = null;
    _popupSkill = null;
    _popupQuestChain = null;
    _mapController.setSelectedMarker(null);
    // Animate out, then remove from tree
    _popupAnimController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _showPopup = false);
    });
  }

  void _popupViewMore() {
    final achievement = _popupAchievement;
    final quest = _popupQuest;
    final skill = _popupSkill;
    final questChain = _popupQuestChain;
    final outlineColor = _popupOutlineColor;
    if (_radiusVisible) {
      _mapController.clearRadiusCircle();
      _radiusVisible = false;
    }
    // Achievements route to the canonical full-detail page so all options
    // (retroactive claim, photos, remarks, visit history, collection
    // progress, opening hours, etc.) match the main achievement page.
    // Quests / skills / chains continue to use the inline bottom sheet.
    if (achievement != null) {
      AchievementDetailSheet.show(
        context,
        achievement,
        outlineColor: outlineColor,
      );
    } else {
      _openDetailSheet(
        quest: quest,
        skill: skill,
        questChain: questChain,
        outlineColor: outlineColor,
      );
    }
    // Animate popup out in parallel, then remove it from the tree.
    _popupAnimController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _showPopup = false;
        _popupMarkerId = '';
        _popupAchievement = null;
        _popupQuest = null;
        _popupSkill = null;
        _popupQuestChain = null;
      });
    });
    _mapController.setSelectedMarker(null);
  }

  bool _radiusVisible = false;

  void _popupShowRadius() {
    final achievement = _popupAchievement;
    if (achievement == null || !achievement.hasGeofence) return;

    // Toggle: if radius is already showing, clear it
    if (_radiusVisible) {
      _mapController.clearRadiusCircle();
      _radiusVisible = false;
      return;
    }

    _radiusVisible = true;
    if (achievement.hasPolygon) {
      _mapController.showClaimPolygon(achievement.claimPolygon!, _popupColor);
    } else {
      _mapController.showRadiusCircle(
        achievement.latitude!,
        achievement.longitude!,
        achievement.claimRadius!,
        _popupColor,
      );
    }
  }

  void _onCameraChanged() {
    // Popup is fixed at the top of the screen (not anchored to the pin) and
    // the area overlay persists through pan/zoom, so nothing to do here.
    // Popup and overlay are dismissed only by the X button or when another
    // pin is selected.
  }

  void _openDetailSheet(
      {SideQuest? quest,
      SkillGroup? skill,
      Quest? questChain,
      Color? outlineColor}) {
    setState(() {
      _showFilterSheet = false;
      _showAdvancedSheet = false;
      _selectedQuest = quest;
      _selectedSkill = skill;
      _selectedQuestChain = questChain;
      _selectedOutlineColor = outlineColor ?? Colors.white;
      _showDetailSheet = true;
    });
    _sheetAnimController.forward(from: 0);
  }

  void _dismissDetailSheet() {
    if (!_showDetailSheet) return;
    _sheetAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedQuest = null;
          _selectedSkill = null;
          _selectedQuestChain = null;
          _showDetailSheet = false;
        });
      }
    });
  }

  Widget _buildBubbleQuickFilters(BuildContext context) {
    return BubbleQuickFilters(
      onClose: () => setState(() => _showFilterSheet = false),
      onOpenAdvanced: () {
        setState(() {
          _showFilterSheet = false;
          _showAdvancedSheet = true;
        });
      },
    );
  }

  Widget _buildAdvancedFilterSheet(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // absorb taps on the sheet
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: UnifiedFilterSheet(
            onClose: () =>
                setState(() => _showAdvancedSheet = false),
          ),
        ),
      ),
    );
  }

  void _dismissLongPressMenu() {
    // No-op: long-press menu disabled
  }

  void _exitMap() {
    _saveCameraState();
    context.go('/');
  }

  void _toggleImmersive() {
    final current = ref.read(mapImmersiveProvider);
    ref.read(mapImmersiveProvider.notifier).state = !current;
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
    // Try quest chains (fly to first step's activity location)
    final chains = ref.read(questChainProvider);
    for (final chain in chains.allQuests) {
      if (chain.title.toLowerCase().contains(q) && chain.steps.isNotEmpty) {
        final activity = quests.allQuests
            .where((a) => a.id == chain.steps.first.targetId)
            .firstOrNull;
        if (activity != null &&
            activity.latitude != null &&
            activity.longitude != null) {
          _mapController.flyTo(activity.latitude!, activity.longitude!, 2000);
          return;
        }
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
    final chains = ref.read(questChainProvider);
    final filter = ref.read(mapFilterProvider);
    final currentCountry = ref.read(currentCountryProvider);

    Achievement? findById(String id) {
      for (final a in achievements.allAchievements) {
        if (a.id == id) return a;
      }
      return null;
    }

    bool passesZone(double lat, double lng) {
      if (!filter.zoneFilterEnabled) return true;
      switch (filter.zoneMode) {
        case ZoneMode.radius:
          if (!geo.hasLocation) return true;
          final meters = haversineMeters(
              geo.latitude!, geo.longitude!, lat, lng);
          return meters <= filter.zoneRadiusKm * 1000;
        case ZoneMode.country:
          final selected = filter.zoneCountryAchievementId != null
              ? findById(filter.zoneCountryAchievementId!)
              : currentCountry;
          if (selected == null) return true;
          return isWithinClaimArea(lat, lng, selected);
        case ZoneMode.continent:
          final continent = filter.zoneContinentAchievementId != null
              ? findById(filter.zoneContinentAchievementId!)
              : null;
          if (continent == null) return true;
          return isWithinClaimArea(lat, lng, continent);
        case ZoneMode.unlimited:
          return true;
      }
    }

    final markers = <MapMarkerItem>[];

    if (filter.showAchievements) {
      for (final a in achievements.allAchievements) {
        if (a.latitude != null && a.longitude != null) {
          if (filter.showOnlyUnlocked && !a.isUnlocked) continue;
          if (filter.selectedAchievementCollections.isNotEmpty &&
              !filter.selectedAchievementCollections.contains(a.collectionId)) {
            continue;
          }
          if (!passesZone(a.latitude!, a.longitude!)) continue;
          markers.add(AchievementMarkerItem(achievement: a));
        }
      }
    }

    if (filter.showQuests) {
      for (final q in quests.allQuests) {
        if (filter.selectedQuestCategories.isNotEmpty &&
            !filter.selectedQuestCategories.contains(q.category)) {
          continue;
        }
        // Create a marker for every location (primary + additional)
        final allLocs = q.allLocations;
        for (var i = 0; i < allLocs.length; i++) {
          final loc = allLocs[i];
          if (!passesZone(loc.latitude, loc.longitude)) continue;
          final locQuest = q.copyWith(
              latitude: loc.latitude, longitude: loc.longitude);
          markers.add(QuestMarkerItem(quest: locQuest, locationIndex: i));
        }
      }
    }

    if (filter.showSkills) {
      for (final s in skills.allSkills) {
        if (s.latitude != null && s.longitude != null) {
          if (filter.selectedSkillIds.isNotEmpty && !filter.selectedSkillIds.contains(s.id)) {
            continue;
          }
          if (!passesZone(s.latitude!, s.longitude!)) continue;
          markers.add(SkillMarkerItem(skill: s));
        }
      }
    }

    if (filter.showQuestChains) {
      for (final chain in chains.allQuests) {
        if (chain.steps.isEmpty) continue;
        if (filter.selectedQuestChainRarities.isNotEmpty &&
            !filter.selectedQuestChainRarities.contains(chain.rarity.name)) {
          continue;
        }
        // Place quest chain marker at its first step's activity location
        final firstStepTarget = chain.steps.first.targetId;
        final activity = quests.allQuests
            .where((q) => q.id == firstStepTarget)
            .firstOrNull;
        if (activity != null &&
            activity.latitude != null &&
            activity.longitude != null) {
          if (!passesZone(activity.latitude!, activity.longitude!)) continue;
          markers.add(QuestChainMarkerItem(
            questChain: chain,
            latitude: activity.latitude!,
            longitude: activity.longitude!,
          ));
        }
      }
    }

    // Only push markers to the map if they actually changed
    if (!listEquals(_lastMarkers, markers)) {
      _lastMarkers = markers;
      _mapController.setMarkers(markers);
    }

    // "Show all unlocked areas" overlay — renders every unlocked polygon
    // persistently so the user can see their coverage while navigating.
    _updateUnlockedAreasOverlay(achievements, filter);

    // Only update user location if it changed
    if (geo.hasLocation) {
      if (_lastUserLat != geo.latitude || _lastUserLng != geo.longitude) {
        _lastUserLat = geo.latitude;
        _lastUserLng = geo.longitude;
        _mapController.setUserLocation(geo.latitude!, geo.longitude!);
      }
    }

    if (!_mapReady && geo.hasLocation) {
      _mapReady = true;
      final cached = ref.read(cachedCameraStateProvider);
      if (cached == null) {
        _mapController.flyTo(geo.latitude!, geo.longitude!, 5000);
      }
    }
  }

  /// Render or clear the per-collection unlocked-area overlay. Each enabled
  /// collection in [MapFilterState.unlockedAreaCollections] renders:
  ///   (a) every unlocked member polygon (hashed color per area), and
  ///   (b) a fixed convex-hull outline around ALL member polygons in the
  ///       collection. Each member polygon is drawn in its own color — no
  ///       merging, summing, or hulling into a single shape.
  /// Collections without polygon-backed unlocked members render nothing.
  Future<void> _updateUnlockedAreasOverlay(
      AchievementsState achievements, MapFilterState filter) async {
    final enabledCollections = filter.showAchievements
        ? filter.unlockedAreaCollections
        : const <String>{};

    if (enabledCollections.isEmpty) {
      if (_lastUnlockedAreasSignature != null) {
        _lastUnlockedAreasSignature = null;
        await _mapController.clearUnlockedAreasOverlay();
      }
      return;
    }

    final areas = <({List<List<double>> polygon, Color color})>[];
    final memberSig = StringBuffer();

    for (final a in achievements.allAchievements) {
      if (!a.isUnlocked) continue;
      if (!a.hasPolygon) continue;
      final cid = a.collectionId;
      if (cid == null || !enabledCollections.contains(cid)) continue;

      areas.add((polygon: a.claimPolygon!, color: colorForArea(a)));
      memberSig.write('${a.id};');
    }

    final memberSignature = memberSig.toString();
    if (memberSignature != _lastUnlockedAreasSignature) {
      _lastUnlockedAreasSignature = memberSignature;
      await _mapController.showUnlockedAreasOverlay(areas);
    }
  }


  // ── Inline detail sheet content builders ──

  Widget _buildSheetContentWithController(ScrollController controller) {
    if (_selectedQuest != null) {
      return _buildQuestContent(controller);
    } else if (_selectedSkill != null) {
      return _buildSkillContent(controller);
    } else if (_selectedQuestChain != null) {
      return _buildQuestChainContent(controller);
    }
    return const SizedBox.shrink();
  }

  Widget _buildQuestContent(ScrollController controller) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final quest = _selectedQuest!;
    final questsState = ref.read(questsProvider);
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
    final verificationLabel = switch (quest.verification) {
      VerificationMethod.photo => 'Photo',
      VerificationMethod.manual => 'Manual',
      VerificationMethod.location => 'Location',
      VerificationMethod.timeBased => 'Timed',
    };
    final verificationIcon = switch (quest.verification) {
      VerificationMethod.photo => LucideIcons.camera,
      VerificationMethod.manual => LucideIcons.checkSquare,
      VerificationMethod.location => LucideIcons.mapPin,
      VerificationMethod.timeBased => LucideIcons.timer,
    };

    // Check if quest is locked
    final isUnlocked = quest.isUnlocked(
      skillLevels: questsState.skillLevels,
      allQuests: questsState.allQuests,
    );

    // Find the skill this quest levels up
    final skill = ref.read(skillsProvider).getSkillById(quest.skillType);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        // Title row
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
                  Text(
                    quest.category,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Badges row
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _SheetBadge(
              label: difficultyLabel,
              color: difficultyColor,
              icon: LucideIcons.signal,
            ),
            _SheetBadge(
              label: '+${quest.xpReward} XP',
              color: AppColors.xpGreen,
              icon: LucideIcons.zap,
            ),
            _SheetBadge(
              label: verificationLabel,
              color: AppColors.textMuted,
              icon: verificationIcon,
            ),
            if (quest.isRepeatable)
              _SheetBadge(
                label: '${quest.completionCount}/${quest.maxCompletions}',
                color: AppColors.info,
                icon: LucideIcons.repeat,
              ),
            if (!isUnlocked)
              _SheetBadge(
                label: 'Locked',
                color: AppColors.error,
                icon: LucideIcons.lock,
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Description
        Text(
          quest.description,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),

        // Linked skill
        if (skill != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(skill.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        RegistryL10n.skillName(locale, skill.id, skill.name),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Lv ${questsState.skillLevels[skill.id] ?? 1} · Levels up this skill',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Requirements (if locked)
        if (!isUnlocked) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(LucideIcons.lock, size: 14, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                'Requirements',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (quest.requiredSkillType != null && quest.requiredSkillLevel != null)
            _RequirementRow(
              text: 'Reach level ${quest.requiredSkillLevel} in ${quest.requiredSkillType}',
              met: (questsState.skillLevels[quest.requiredSkillType] ?? 0) >= quest.requiredSkillLevel!,
            ),
          ...quest.requiredQuestIds.map((reqId) {
            final reqQuest = questsState.allQuests.where((q) => q.id == reqId).firstOrNull;
            return _RequirementRow(
              text: 'Complete "${reqQuest?.title ?? reqId}"',
              met: reqQuest?.isCompleted ?? false,
            );
          }),
        ],

        const SizedBox(height: 18),

        // Status
        if (quest.isCompleted)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.check, size: 18, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  quest.isRepeatable
                      ? '${l10n.unlocked} · ${quest.completionCount}/${quest.maxCompletions}'
                      : l10n.unlocked,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSkillContent(ScrollController controller) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final skill = _selectedSkill!;
    final questsState = ref.read(questsProvider);
    final level = questsState.skillLevels[skill.id] ?? 0;
    final xp = questsState.skillXp[skill.id] ?? 0;
    final xpForNext = skill.xpPerLevel;
    final xpInLevel = xp % xpForNext;
    final skillColor = SkillMarkerItem.parseHexColor(skill.gradientStart);

    // Count related activities
    final relatedQuests = questsState.allQuests
        .where((q) => q.skillType == skill.id)
        .toList();
    final completedCount = relatedQuests.where((q) => q.completionCount > 0).length;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        // Title row
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: skillColor,
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
                    '${l10n.level} $level / ${skill.maxLevel}',
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

        // XP progress bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: level >= skill.maxLevel
                      ? 1.0
                      : (xpForNext > 0 ? xpInLevel / xpForNext : 0),
                  minHeight: 6,
                  backgroundColor: skillColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(skillColor),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              level >= skill.maxLevel
                  ? 'MAX'
                  : '$xpInLevel / $xpForNext XP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Stats chips
        Row(
          children: [
            _SheetBadge(
              label: '${relatedQuests.length} activities',
              color: AppColors.accent,
              icon: LucideIcons.compass,
            ),
            const SizedBox(width: 6),
            _SheetBadge(
              label: '$completedCount done',
              color: AppColors.success,
              icon: LucideIcons.checkCircle,
            ),
            const SizedBox(width: 6),
            _SheetBadge(
              label: '$xp total XP',
              color: AppColors.xpGreen,
              icon: LucideIcons.zap,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Description
        Text(
          RegistryL10n.skillDescription(
              locale, skill.id, skill.description),
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuestChainContent(ScrollController controller) {
    final chain = _selectedQuestChain!;
    final rarityColor = QuestChainMarkerItem.rarityColor(chain.rarity);
    final chainNotifier = ref.read(questChainProvider.notifier);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rarityColor,
              ),
              child: Center(
                child: Text(
                  chain.icon,
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
                    chain.title,
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
                          color: rarityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          chain.rarity.name[0].toUpperCase() +
                              chain.rarity.name.substring(1),
                          style: TextStyle(
                            color: rarityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${chain.xpReward} XP',
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
          chain.description,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        // Step progress
        Text(
          '${chain.completedStepCount}/${chain.totalSteps} steps completed',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: chain.progress,
            backgroundColor: AppColors.textMuted.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(rarityColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
        // Steps list
        for (final step in chain.steps) ...[
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.isCompleted
                      ? AppColors.success
                      : AppColors.textMuted.withValues(alpha: 0.3),
                ),
                child: Icon(
                  step.isCompleted ? LucideIcons.check : LucideIcons.circle,
                  size: 14,
                  color: step.isCompleted ? Colors.white : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(
                    color: step.isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: step.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (step.type == QuestStepType.activity
                          ? AppColors.success
                          : AppColors.gold)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  step.type == QuestStepType.activity
                      ? 'Activity'
                      : 'Achievement',
                  style: TextStyle(
                    color: step.type == QuestStepType.activity
                        ? AppColors.success
                        : AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        if (chain.isClaimed)
          Center(
            child: Text(
              'Completed!',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          )
        else if (chain.isClaimable)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                chainNotifier.claimQuest(chain.id);
                _dismissDetailSheet();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
              ),
              child: Text('Claim +${chain.xpReward} XP'),
            ),
          )
        else if (!chain.isStarted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                chainNotifier.startQuest(chain.id);
                _dismissDetailSheet();
              },
              child: const Text('Start Quest'),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                chainNotifier.abandonQuest(chain.id);
                _dismissDetailSheet();
              },
              child: const Text('Abandon Quest'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final geo = ref.watch(geolocationProvider);
    ref.watch(achievementsProvider);
    ref.watch(questsProvider);
    ref.watch(skillsProvider);
    ref.watch(questChainProvider);
    ref.watch(mapFilterProvider);
    final isImmersive = ref.watch(mapImmersiveProvider);
    final showZoneSettings = ref.watch(mapZoneSettingsOpenProvider);
    final l10n = AppLocalizations.of(context)!;

    // Drive the slide-up animation from the immersive flag.
    if (isImmersive && _immersiveController.status != AnimationStatus.completed) {
      _immersiveController.forward();
    } else if (!isImmersive &&
        _immersiveController.status != AnimationStatus.dismissed) {
      _immersiveController.reverse();
    }

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
      canPop:
          !_showDetailSheet && !_showFilterSheet && !_showAdvancedSheet,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_showDetailSheet) {
          _dismissDetailSheet();
        } else if (_showAdvancedSheet) {
          setState(() => _showAdvancedSheet = false);
        } else if (_showFilterSheet) {
          setState(() => _showFilterSheet = false);
        }
      },
      child: Material(
      type: MaterialType.transparency,
      child: SafeArea(
        // In fullscreen mode, drop the top inset so the map extends under the
        // status bar (matches the behavior at the bottom, where the nav bar
        // is also hidden).
        top: !isImmersive,
        bottom: false,
        child: Column(
          children: [
            // Top bar: close button (with Exit label) + search bar + zone
            // banner. Sits above the map (not overlaying it) so the map's
            // top edge stops just below this bar. Animates up + collapses
            // when entering fullscreen instead of disappearing instantly.
            ClipRect(
              child: SizeTransition(
                sizeFactor: ReverseAnimation(CurvedAnimation(
                  parent: _immersiveController,
                  curve: Curves.easeOutCubic,
                )),
                axisAlignment: -1,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(0, -1),
                  ).animate(CurvedAnimation(
                    parent: _immersiveController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: FadeTransition(
                    opacity: _controlsFadeController,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MapExitButton(
                                onTap: _exitMap,
                                tooltip: l10n.mapCloseMap,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MapSearchBar(
                                  onSearch: _onSearchSubmitted,
                                ),
                              ),
                            ],
                          ),
                          const _ZoneStatusBanner(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Map area + overlays — fills the remaining space below the top bar
            Expanded(
              child: Stack(
                children: [
                  // Platform map (fills the area below the top bar)
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

            // Right side: map controls (location, zoom, fullscreen).
            // Bottom edge aligns with the filter button on the left so the
            // fullscreen toggle and the filter pill share one baseline.
            Positioned(
              right: 16,
              bottom: 40,
              child: FadeTransition(
                opacity: _controlsFadeController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const SizedBox(height: 10),
                    _MapControlButton(
                      icon: isImmersive
                          ? LucideIcons.minimize2
                          : LucideIcons.maximize2,
                      onTap: _toggleImmersive,
                      tooltip: isImmersive ? 'Show nav bar' : 'Fullscreen',
                    ),
                  ],
                ),
              ),
            ),

            // Zone settings popover — overlays the map (anchored just under
            // where the banner sits) so opening it does not push the top
            // bar's height. Toggled via the gear icon in _ZoneStatusBanner.
            if (showZoneSettings && !isImmersive)
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: _ZoneSettingsPopover(
                  onClose: () => ref
                      .read(mapZoneSettingsOpenProvider.notifier)
                      .state = false,
                ).animate().fadeIn(
                      duration: 160.ms,
                      curve: Curves.easeOut,
                    ).slideY(
                      begin: -0.06,
                      end: 0,
                      duration: 220.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),

            // Filter button (bottom-left, above nav bar). Bottom edge aligns
            // with the right-side control column so they share a baseline.
            Positioned(
              left: 16,
              bottom: 40,
              child: FadeTransition(
                opacity: _controlsFadeController,
                child: MapFilterButton(
                  onTap: () {
                    final wasOpen =
                        _showFilterSheet || _showAdvancedSheet;
                    if (!wasOpen && _showPopup) {
                      _dismissPopup();
                    }
                    setState(() {
                      if (wasOpen) {
                        _showFilterSheet = false;
                        _showAdvancedSheet = false;
                      } else {
                        _showFilterSheet = true;
                      }
                    });
                  },
                ),
              ),
            ),

            // Hovering bubble quick-filter column above the filter button.
            // First-tap surface — opens the advanced sheet via its
            // "Advanced settings" entry.
            if (_showFilterSheet)
              Positioned(
                left: 0,
                right: 0,
                bottom: 88,
                child: _buildBubbleQuickFilters(context)
                    .animate()
                    .fadeIn(duration: 160.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.12,
                      end: 0,
                      duration: 220.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),

            // Advanced filter sheet — opened from the bubble column.
            if (_showAdvancedSheet)
              Positioned(
                left: 0,
                right: 0,
                bottom: 88,
                child: _buildAdvancedFilterSheet(context)
                    .animate()
                    .fadeIn(duration: 180.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.12,
                      end: 0,
                      duration: 240.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .scaleXY(
                      begin: 0.96,
                      end: 1.0,
                      duration: 240.ms,
                      curve: Curves.easeOutCubic,
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

            // Pin popup — fixed at top of screen, slides down from above.
            // Persists through map pan/zoom; dismissed only via X button or
            // when another pin is selected.
            if (_showPopup)
              Builder(
                builder: (context) {
                  final ach = _popupAchievement;
                  return MapPinPopup(
                    title: _popupTitle,
                    subtitle: _popupSubtitle,
                    color: _popupColor,
                    outlineColor: _popupOutlineColor,
                    icon: _popupIcon,
                    animation: _popupAnimController,
                    onViewMore: _popupViewMore,
                    onDismiss: _dismissPopup,
                    xpReward: ach?.xpReward,
                    isUnlocked: ach?.isUnlocked ?? false,
                    visitCount: ach?.visitCount ?? 0,
                    isPendingClaim: ach?.isPendingClaim ?? false,
                  );
                },
              ),

            // Bottom sheet — draggable detail panel
            if (_showDetailSheet)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _sheetAnimController,
                  builder: (context, child) {
                    final value = CurvedAnimation(
                      parent: _sheetAnimController,
                      curve: Curves.easeOutCubic,
                    ).value;
                    if (value <= 0) return const SizedBox.shrink();
                    return Opacity(opacity: value, child: child);
                  },
                  child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      // Auto-dismiss when dragged below min extent
                      if (notification.extent <= notification.minExtent) {
                        _dismissDetailSheet();
                      }
                      return false;
                    },
                    child: DraggableScrollableSheet(
                      initialChildSize: 0.45,
                      minChildSize: 0.1,
                      maxChildSize: 0.85,
                      snap: true,
                      snapSizes: const [0.45, 0.85],
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                            border: Border(
                              top: BorderSide(
                                  color: _selectedOutlineColor, width: 2),
                              left: BorderSide(
                                  color: _selectedOutlineColor, width: 2),
                              right: BorderSide(
                                  color: _selectedOutlineColor, width: 2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedOutlineColor
                                    .withValues(alpha: 0.35),
                                blurRadius: 26,
                                spreadRadius: -2,
                                offset: const Offset(0, -4),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Drag handle — tinted to match the outline
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _dismissDetailSheet,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 40),
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _selectedOutlineColor
                                          .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              // Content — uses the DraggableScrollableSheet's controller
                              Expanded(
                                child: _buildSheetContentWithController(
                                    scrollController),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
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

/// Close-map button with an "Exit" label underneath so users understand
/// what the X does (leave the map screen).
class _MapExitButton extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;

  const _MapExitButton({required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return _MapControlButton(
      icon: LucideIcons.x,
      onTap: onTap,
      tooltip: tooltip,
      size: 40,
    );
  }
}

/// Search bar for finding map markers by name. Can be minimized to a single
/// search icon to give more of the map back to the user.
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
  bool _minimized = false;

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

  void _expand() {
    setState(() => _minimized = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _collapse() {
    _focusNode.unfocus();
    setState(() => _minimized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_minimized) {
      return Align(
        alignment: Alignment.centerRight,
        child: _MapControlButton(
          icon: LucideIcons.search,
          onTap: _expand,
          tooltip: 'Search',
          size: 40,
        ),
      );
    }

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
          // Minimize button — now on the LEFT (was on the right). Collapses
          // the bar back to a single search icon at the far right.
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _collapse();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
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
          const SizedBox(width: 8),
          Icon(
            LucideIcons.search,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Transparent banner shown under the search bar when the zone filter is
/// on. Displays the current zone label and a settings gear that opens
/// an inline popover (zone settings) directly below the banner.
class _ZoneStatusBanner extends ConsumerWidget {
  const _ZoneStatusBanner();

  Achievement? _findById(WidgetRef ref, String id) {
    final achievements = ref.read(achievementsProvider).allAchievements;
    for (final a in achievements) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapFilterProvider);
    if (!filter.zoneFilterEnabled) return const SizedBox.shrink();

    final settingsOpen = ref.watch(mapZoneSettingsOpenProvider);
    final currentCountry = ref.watch(currentCountryProvider);
    final selectedCountry = filter.zoneCountryAchievementId != null
        ? _findById(ref, filter.zoneCountryAchievementId!)
        : null;
    final selectedContinent = filter.zoneContinentAchievementId != null
        ? _findById(ref, filter.zoneContinentAchievementId!)
        : null;
    final String label = switch (filter.zoneMode) {
      ZoneMode.radius =>
        '${filter.zoneRadiusKm.toStringAsFixed(0)} km around you',
      ZoneMode.country =>
        (selectedCountry ?? currentCountry)?.title ?? 'your location',
      ZoneMode.continent =>
        selectedContinent?.title.replaceFirst('Visit ', '').replaceAll('!', '')
            ?? 'pick a continent',
      ZoneMode.unlimited => 'no limit',
    };

    void toggleSettings() {
      HapticFeedback.selectionClick();
      ref.read(mapZoneSettingsOpenProvider.notifier).state = !settingsOpen;
    }

    // White text with a primary-color glow outline. Sits just under the
    // search bar (small top margin) and never grows the top bar — the
    // settings popover renders separately as a map overlay.
    //
    // Layout: a Stack so the text is truly centered across the full width,
    // with the gear icon pinned to the right edge as an overlay. The pin
    // icon is inlined as a WidgetSpan so it stays glued to the text.
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Reserve symmetric horizontal space for the gear so the centered
          // text doesn't overlap it.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: RichText(
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.95),
                      blurRadius: 6,
                    ),
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.7),
                      blurRadius: 14,
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 3,
                    ),
                  ],
                ),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(LucideIcons.mapPin,
                          size: 14,
                          color: AppColors.primary.withValues(alpha: 0.95),
                          shadows: [
                            Shadow(
                              color: AppColors.primary.withValues(alpha: 0.7),
                              blurRadius: 8,
                            ),
                          ]),
                    ),
                  ),
                  const TextSpan(text: 'Showing pinpoints within: '),
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: AppColors.primary,
                          blurRadius: 10,
                        ),
                        Shadow(
                          color: AppColors.primary.withValues(alpha: 0.85),
                          blurRadius: 18,
                        ),
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.9),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
            onTap: toggleSettings,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                settingsOpen
                    ? LucideIcons.x
                    : LucideIcons.settings2,
                size: 18,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

/// Inline popover (NOT a modal sheet) anchored just below the zone
/// status banner. Mode toggle (country / continent / radius / unlimited)
/// + per-mode controls.
class _ZoneSettingsPopover extends ConsumerWidget {
  final VoidCallback onClose;
  const _ZoneSettingsPopover({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapFilterProvider);
    final notifier = ref.read(mapFilterProvider.notifier);
    final currentCountry = ref.watch(currentCountryProvider);
    final achievements = ref.watch(achievementsProvider).allAchievements;

    Achievement? findById(String id) {
      for (final a in achievements) {
        if (a.id == id) return a;
      }
      return null;
    }

    final selectedCountry = filter.zoneCountryAchievementId != null
        ? findById(filter.zoneCountryAchievementId!)
        : null;
    final selectedContinent = filter.zoneContinentAchievementId != null
        ? findById(filter.zoneContinentAchievementId!)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.settings2,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Zone settings',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(LucideIcons.x,
                      size: 14, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ZoneModeSegmented(
              selected: filter.zoneMode,
              onChanged: (m) {
                HapticFeedback.selectionClick();
                notifier.setZoneMode(m);
              },
            ),
            const SizedBox(height: 12),
            if (filter.zoneMode == ZoneMode.country)
              _CountryPicker(
                achievements: achievements,
                currentCountry: currentCountry,
                selected: selectedCountry,
                onPick: (id) => notifier.setZoneCountry(id),
              ),
            if (filter.zoneMode == ZoneMode.continent)
              _ContinentPicker(
                achievements: achievements,
                selected: selectedContinent,
                onPick: (id) => notifier.setZoneContinent(id),
              ),
            if (filter.zoneMode == ZoneMode.radius) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Radius',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${filter.zoneRadiusKm.toStringAsFixed(0)} km',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor:
                      AppColors.textMuted.withValues(alpha: 0.25),
                  thumbColor: AppColors.primary,
                  overlayColor:
                      AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: filter.zoneRadiusKm.clamp(10, 2000).toDouble(),
                  min: 10,
                  max: 2000,
                  divisions: 199,
                  onChanged: (v) =>
                      notifier.setZoneRadiusKm(v.roundToDouble()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('10 km',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                  Text('2000 km',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ),
    );
  }
}

/// Two-button segmented control — "By country" vs "By zone".
class _ZoneModeSegmented extends StatelessWidget {
  final ZoneMode selected;
  final ValueChanged<ZoneMode> onChanged;

  const _ZoneModeSegmented({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textMuted.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          _segment(
            icon: LucideIcons.flag,
            label: 'Country',
            active: selected == ZoneMode.country,
            onTap: () => onChanged(ZoneMode.country),
          ),
          _segment(
            icon: LucideIcons.globe,
            label: 'Continent',
            active: selected == ZoneMode.continent,
            onTap: () => onChanged(ZoneMode.continent),
          ),
          _segment(
            icon: LucideIcons.target,
            label: 'Zone',
            active: selected == ZoneMode.radius,
            onTap: () => onChanged(ZoneMode.radius),
          ),
          _segment(
            icon: LucideIcons.infinity,
            label: 'All',
            active: selected == ZoneMode.unlimited,
            onTap: () => onChanged(ZoneMode.unlimited),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 12,
                  color: active ? AppColors.primary : AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable selector that opens a search dialog for picking any
/// country achievement. Falls back to the user's current country when
/// none is explicitly chosen.
class _CountryPicker extends StatelessWidget {
  final List<Achievement> achievements;
  final Achievement? currentCountry;
  final Achievement? selected;
  final ValueChanged<String?> onPick;

  const _CountryPicker({
    required this.achievements,
    required this.currentCountry,
    required this.selected,
    required this.onPick,
  });

  static const _countryCollections = <String>{
    'europe', 'asia', 'africa', 'americas', 'south-america', 'oceania',
  };

  @override
  Widget build(BuildContext context) {
    final countries = achievements
        .where((a) => _countryCollections.contains(a.collectionId))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    final effective = selected ?? currentCountry;
    final label = effective?.title ??
        (currentCountry == null
            ? 'Waiting for your location…'
            : 'Pick a country');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await showDialog<String?>(
              context: context,
              builder: (_) => _CountrySearchDialog(
                countries: countries,
                hasSelection: selected != null,
              ),
            );
            if (picked == null) return;
            if (picked == '__clear__') {
              // Explicit clear — null out the selection AND any current
              // country so the picker truly shows nothing.
              onPick(null);
            } else if (picked == '') {
              // Use current country.
              onPick(null);
            } else {
              onPick(picked);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.textMuted.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.flag,
                    size: 13, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (selected != null) ...[
                  GestureDetector(
                    onTap: () => onPick(null),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(LucideIcons.x,
                          size: 13, color: AppColors.textMuted),
                    ),
                  ),
                ],
                Icon(LucideIcons.chevronDown,
                    size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        if (selected != null && currentCountry != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Current: ${currentCountry!.title}',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

/// Searchable country list dialog. Returns the selected achievement id,
/// or empty string to clear the override (use current country).
class _CountrySearchDialog extends StatefulWidget {
  final List<Achievement> countries;
  final bool hasSelection;
  const _CountrySearchDialog({
    required this.countries,
    this.hasSelection = false,
  });

  @override
  State<_CountrySearchDialog> createState() => _CountrySearchDialogState();
}

class _CountrySearchDialogState extends State<_CountrySearchDialog> {
  String _query = '';
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.countries
        : widget.countries
            .where((c) => c.title.toLowerCase().contains(query))
            .toList();
    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 380,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Icon(LucideIcons.flag,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pick a country',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(LucideIcons.x,
                          size: 16, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                autofocus: true,
                controller: _textController,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search countries…',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(LucideIcons.search,
                      size: 16, color: AppColors.textMuted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : GestureDetector(
                          onTap: () {
                            _textController.clear();
                            setState(() => _query = '');
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Icon(LucideIcons.x,
                              size: 14, color: AppColors.textMuted),
                        ),
                  filled: true,
                  fillColor:
                      AppColors.bgCardLight.withValues(alpha: 0.4),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(''),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(LucideIcons.crosshair,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Use my current country',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Clear selected country — pops a sentinel ('clear') so the
            // caller can null out the selection.
            if (widget.hasSelection)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop('__clear__'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(LucideIcons.eraser,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          'Clear selection',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const Divider(height: 1, color: Color(0x22FFFFFF)),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(c.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        c.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Inline 6-button continent picker. Tap one to set [selected]; selecting
/// a continent doesn't require also picking a country.
class _ContinentPicker extends StatelessWidget {
  final List<Achievement> achievements;
  final Achievement? selected;
  final ValueChanged<String?> onPick;

  const _ContinentPicker({
    required this.achievements,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final continents = achievements
        .where((a) => a.collectionId == 'continents')
        .toList();
    if (continents.isEmpty) {
      return const Text(
        'No continent data available',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: continents.map((c) {
        final isSelected = selected?.id == c.id;
        final shortName = c.title
            .replaceFirst('Visit ', '')
            .replaceAll('!', '');
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onPick(isSelected ? null : c.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.bgCardLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.textMuted.withValues(alpha: 0.2),
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(LucideIcons.check,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                ],
                Text(
                  shortName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Loading shimmer shown while the map widget initializes.
/// Compact badge used in map detail sheets.
class _SheetBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SheetBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Requirement row with check/empty circle.
class _RequirementRow extends StatelessWidget {
  final String text;
  final bool met;

  const _RequirementRow({required this.text, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? LucideIcons.checkCircle : LucideIcons.circle,
            size: 14,
            color: met ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: met ? AppColors.textSecondary : AppColors.textPrimary,
                fontSize: 13,
                decoration: met ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
