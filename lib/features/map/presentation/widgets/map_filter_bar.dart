import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_filter_provider.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';

class MapFilterBar extends ConsumerWidget {
  const MapFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _MapFilterChip(
            icon: LucideIcons.trophy,
            label: l10n.mapFilterAchievements,
            selected: filter.showAchievements,
            color: AppColors.gold,
            onTap: () => ref.read(mapFilterProvider.notifier).toggleAchievements(),
          ),
          const SizedBox(width: 8),
          _MapFilterChip(
            icon: LucideIcons.swords,
            label: l10n.mapFilterQuests,
            selected: filter.showQuests,
            color: AppColors.success,
            onTap: () => ref.read(mapFilterProvider.notifier).toggleQuests(),
          ),
          const SizedBox(width: 8),
          _MapFilterChip(
            icon: LucideIcons.sparkles,
            label: l10n.mapFilterSkills,
            selected: filter.showSkills,
            color: AppColors.info,
            onTap: () => ref.read(mapFilterProvider.notifier).toggleSkills(),
          ),
        ],
      ),
    );
  }
}

class _MapFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _MapFilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : AppColors.bgCardLight.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.8)
                : AppColors.bgCardLight.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
