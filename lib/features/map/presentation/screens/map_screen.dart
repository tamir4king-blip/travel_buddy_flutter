import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/presentation/map_view.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/achievement_marker.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/geolocation_provider.dart';

const _mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final PlatformMapController _mapController;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = createMapController(token: _mapboxToken);
    _mapController.onMarkerClick = _onMarkerClick;

    // Kick off a one-shot location fetch so we have a position to center on
    Future.microtask(() {
      final geo = ref.read(geolocationProvider);
      if (!geo.hasLocation) {
        ref.read(geolocationProvider.notifier).getCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMarkerClick(String achievementId) {
    final achievements = ref.read(achievementsProvider);
    final achievement = achievements.allAchievements
        .where((a) => a.id == achievementId)
        .firstOrNull;
    if (achievement != null && mounted) {
      _showAchievementSheet(context, achievement);
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
    if (!_mapController.isInitialized) return;

    final geo = ref.read(geolocationProvider);
    final achievements = ref.read(achievementsProvider);

    final locationAchievements = achievements.allAchievements
        .where((a) => a.latitude != null && a.longitude != null)
        .toList();

    _mapController.setMarkers(locationAchievements);

    if (geo.hasLocation) {
      _mapController.setUserLocation(geo.latitude!, geo.longitude!);
    }

    // Fly to user on first ready
    if (!_mapReady && geo.hasLocation) {
      _mapReady = true;
      _mapController.flyTo(geo.latitude!, geo.longitude!, 5000);
    }
  }

  void _showAchievementSheet(BuildContext context, Achievement achievement) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final geo = ref.read(geolocationProvider);
    final achievementsNotifier = ref.read(achievementsProvider.notifier);

    final distance = geo.hasLocation && achievement.latitude != null
        ? geo.distanceTo(achievement.latitude!, achievement.longitude!)
        : double.infinity;
    final inRange = achievement.claimRadius != null && distance <= achievement.claimRadius!;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        achievement.isUnlocked ? LucideIcons.check : LucideIcons.trophy,
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
                            RegistryL10n.achievementTitle(locale, achievement.id, achievement.title),
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
                  RegistryL10n.achievementDescription(locale, achievement.id, achievement.description),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                          ? () {
                              achievementsNotifier.claimAchievement(
                                achievement.id,
                                userLat: geo.latitude,
                                userLng: geo.longitude,
                              );
                              Navigator.of(context).pop();
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
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final geo = ref.watch(geolocationProvider);
    final achievements = ref.watch(achievementsProvider);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    // Update map entities whenever state changes
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateMapState());

    final locationAchievements = achievements.allAchievements
        .where((a) => a.latitude != null && a.longitude != null)
        .toList();

    final nearby = locationAchievements.where((a) {
      if (a.claimRadius == null || !geo.hasLocation) return false;
      return geo.distanceTo(a.latitude!, a.longitude!) <= a.claimRadius!;
    }).toList();

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Platform map (Cesium on web, FlutterMap on mobile)
          Positioned.fill(
            child: PlatformMapViewWidget(controller: _mapController),
          ),

          // Top search bar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Text(
                        l10n.searchAchievements,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Center on Me FAB
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: _centerOnUser,
              backgroundColor: AppColors.bgCard,
              child: const Icon(LucideIcons.crosshair, color: AppColors.primary),
            ),
          ),

          // Live tracking indicator
          if (geo.isLiveTracking)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 72),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            ),

          // Nearby achievements drawer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.nearbyAchievements,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          geo.hasLocation ? l10n.locationOn : l10n.locationOff,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!geo.hasLocation)
                      Text(
                        l10n.enableLocationToSee,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      )
                    else if (nearby.isEmpty)
                      Text(
                        l10n.noAchievementsInRange,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      )
                    else
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: nearby.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final achievement = nearby[index];
                            final dist = geo.distanceTo(
                              achievement.latitude!,
                              achievement.longitude!,
                            );
                            return GestureDetector(
                              onTap: () => _showAchievementSheet(context, achievement),
                              child: Container(
                                width: 220,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bgCardLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            RegistryL10n.achievementTitle(locale, achievement.id, achievement.title),
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${dist.round()}m',
                                          style: const TextStyle(
                                            color: AppColors.success,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      RegistryL10n.achievementDescription(locale, achievement.id, achievement.description),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      height: 28,
                                      child: ElevatedButton(
                                        onPressed: achievement.isUnlocked
                                            ? null
                                            : () {
                                                ref.read(achievementsProvider.notifier).claimAchievement(
                                                      achievement.id,
                                                      userLat: geo.latitude,
                                                      userLng: geo.longitude,
                                                    );
                                              },
                                        child: Text(achievement.isUnlocked ? l10n.unlocked : l10n.claim),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
