import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/shared/providers/achievements_provider.dart';
import 'package:travel_buddy/shared/providers/geolocation_provider.dart';
import 'package:travel_buddy/shared/providers/nearby_achievements_provider.dart';

class GpsSpoofScreen extends ConsumerStatefulWidget {
  const GpsSpoofScreen({super.key});

  @override
  ConsumerState<GpsSpoofScreen> createState() => _GpsSpoofScreenState();
}

class _GpsSpoofScreenState extends ConsumerState<GpsSpoofScreen> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _syncControllers(GeolocationState geo) {
    final latStr = geo.latitude?.toStringAsFixed(6) ?? '';
    final lngStr = geo.longitude?.toStringAsFixed(6) ?? '';
    if (_latController.text != latStr) _latController.text = latStr;
    if (_lngController.text != lngStr) _lngController.text = lngStr;
  }

  @override
  Widget build(BuildContext context) {
    final geo = ref.watch(geolocationProvider);
    final achievements = ref.watch(achievementsProvider);
    final nearby = ref.watch(nearbyAchievementsProvider);

    // Sync text fields when spoofing location changes
    if (geo.isSpoofing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncControllers(geo);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Spoofing',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Toggle
          _SectionCard(
            child: SwitchListTile(
              title: const Text('Enable GPS Spoofing',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                geo.isSpoofing ? 'Spoofing active' : 'Using real GPS',
                style: TextStyle(
                  color: geo.isSpoofing
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
              ),
              value: geo.isSpoofing,
              activeColor: AppColors.success,
              onChanged: (enabled) {
                final notifier = ref.read(geolocationProvider.notifier);
                if (enabled) {
                  // Default to first achievement location
                  final first = achievementRegistry.first;
                  notifier.enableSpoof(first.latitude!, first.longitude!);
                } else {
                  notifier.disableSpoof();
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          if (geo.isSpoofing) ...[
            // Manual coordinates
            _SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Coordinates',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _lngController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.navigation,
                              color: AppColors.primary),
                          onPressed: () {
                            final lat =
                                double.tryParse(_latController.text);
                            final lng =
                                double.tryParse(_lngController.text);
                            if (lat != null && lng != null) {
                              ref
                                  .read(geolocationProvider.notifier)
                                  .updateSpoofedLocation(lat, lng);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status bar
            _SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(LucideIcons.radio,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Nearby: ${nearby.nearbyCount}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    Icon(LucideIcons.sparkles,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'New: ${nearby.newlyDiscovered.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick location buttons
            const Text('Quick Teleport',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            ...achievementRegistry.where((a) => a.latitude != null).map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _QuickLocationTile(
                  title: a.title,
                  subtitle:
                      '${a.latitude!.toStringAsFixed(4)}, ${a.longitude!.toStringAsFixed(4)}  •  ${a.claimRadius?.toInt() ?? 0}m radius',
                  distance: geo.hasLocation
                      ? geo.distanceTo(a.latitude!, a.longitude!)
                      : null,
                  isUnlocked: achievements.allAchievements
                      .where((x) => x.id == a.id)
                      .firstOrNull
                      ?.isUnlocked ?? false,
                  onTap: () {
                    ref
                        .read(geolocationProvider.notifier)
                        .updateSpoofedLocation(a.latitude!, a.longitude!);
                  },
                ),
              ),
            ),
          ] else ...[
            // Real GPS status
            _SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Real GPS Status',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      'Permission: ${geo.hasPermission ? "Granted" : "Not granted"}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      'Tracking: ${geo.isLiveTracking ? "Live" : "Off"}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    if (geo.hasLocation)
                      Text(
                        'Position: ${geo.latitude!.toStringAsFixed(6)}, ${geo.longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    if (geo.error != null)
                      Text(
                        'Error: ${geo.error}',
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickLocationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? distance;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _QuickLocationTile({
    required this.title,
    required this.subtitle,
    this.distance,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                isUnlocked ? LucideIcons.checkCircle : LucideIcons.mapPin,
                size: 18,
                color: isUnlocked ? AppColors.success : AppColors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              if (distance != null)
                Text(
                  distance! < 1000
                      ? '${distance!.toInt()}m'
                      : '${(distance! / 1000).toStringAsFixed(1)}km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: distance! < 300
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}
