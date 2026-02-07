import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/l10n/registry_l10n.dart';
import 'package:travel_buddy/shared/providers/achievements_provider.dart';
import 'package:travel_buddy/shared/providers/geolocation_provider.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geo = ref.watch(geolocationProvider);
    final geoNotifier = ref.read(geolocationProvider.notifier);
    final achievements = ref.watch(achievementsProvider);
    final achievementsNotifier = ref.read(achievementsProvider.notifier);

    final nearby = achievements.allAchievements.where((a) {
      if (a.latitude == null || a.longitude == null || a.claimRadius == null) {
        return false;
      }
      if (!geo.hasLocation) return false;
      return geo.distanceTo(a.latitude!, a.longitude!) <= a.claimRadius!;
    }).toList();

    final l10n = AppLocalizations.of(context)!;

    // TODO: Integrate MapLibre GL when MAPTILER_KEY is configured
    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder
          Container(
            color: AppColors.bgDark,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.map,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.mapView,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.configureMapTiler,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: geo.isTracking ? null : geoNotifier.getCurrentLocation,
                    icon: const Icon(LucideIcons.navigation, size: 18),
                    label: Text(geo.isTracking ? l10n.locating : l10n.centerOnMe),
                  ),
                  if (geo.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      geo.error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Top bar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
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
                  ],
                ),
              ),
            ),
          ),

          // FAB for location
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: geoNotifier.getCurrentLocation,
              backgroundColor: AppColors.bgCard,
              child: const Icon(LucideIcons.crosshair, color: AppColors.primary),
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
                            return Container(
                              width: 220,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.bgCardLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    RegistryL10n.achievementTitle(Localizations.localeOf(context), achievement.id, achievement.title),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    RegistryL10n.achievementDescription(Localizations.localeOf(context), achievement.id, achievement.description),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    height: 28,
                                    child: ElevatedButton(
                                      onPressed: achievement.isUnlocked
                                          ? null
                                          : () => achievementsNotifier
                                              .claimAchievement(achievement.id),
                                      child: Text(achievement.isUnlocked ? l10n.unlocked : l10n.claim),
                                    ),
                                  ),
                                ],
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
