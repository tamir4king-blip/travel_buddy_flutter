import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_filter_provider.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/shared/data/collection_registry.dart';
import 'package:travel_buddy_mobile/shared/data/quest_registry.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';

class MapFilterBar extends ConsumerWidget {
  const MapFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main filter chips
        SingleChildScrollView(
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
        ),
        // Subfilter slider - animated
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _buildSubfilterRow(context, ref, filter),
        ),
      ],
    );
  }

  Widget _buildSubfilterRow(BuildContext context, WidgetRef ref, MapFilterState filter) {
    if (filter.showAchievements && !filter.showQuests && !filter.showSkills) {
      return _AchievementSubfilters(
        selectedCollection: filter.selectedAchievementCollection,
        onSelect: (id) => ref.read(mapFilterProvider.notifier).selectAchievementCollection(id),
      );
    }
    if (filter.showQuests && !filter.showAchievements && !filter.showSkills) {
      return _QuestSubfilters(
        selectedCategory: filter.selectedQuestCategory,
        onSelect: (cat) => ref.read(mapFilterProvider.notifier).selectQuestCategory(cat),
      );
    }
    if (filter.showSkills && !filter.showAchievements && !filter.showQuests) {
      return _SkillSubfilters(
        selectedSkillId: filter.selectedSkillId,
        onSelect: (id) => ref.read(mapFilterProvider.notifier).selectSkillId(id),
      );
    }
    // Multiple or no filters active - no subfilter row
    return const SizedBox.shrink();
  }
}

// ── Achievement Subfilters (by collection) ──

class _AchievementSubfilters extends StatelessWidget {
  final String? selectedCollection;
  final ValueChanged<String> onSelect;

  const _AchievementSubfilters({
    required this.selectedCollection,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: collectionRegistry.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final collection = collectionRegistry[index];
            final isSelected = selectedCollection == collection.id;
            return _SubfilterChip(
              label: '${collection.icon} ${collection.name}',
              selected: isSelected,
              color: AppColors.gold,
              onTap: () => onSelect(collection.id),
            );
          },
        ),
      ),
    );
  }
}

// ── Quest Subfilters (by category) ──

class _QuestSubfilters extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String> onSelect;

  const _QuestSubfilters({
    required this.selectedCategory,
    required this.onSelect,
  });

  static const _categoryIcons = <String, String>{
    'adventure': '🏔️',
    'camping': '⛺',
    'cooking': '👨‍🍳',
    'cultural': '🏛️',
    'extreme': '🪂',
    'fishing': '🎣',
    'food-drink': '🍜',
    'hiking': '🥾',
    'nightlife': '🎉',
    'photography': '📸',
    'shopping': '🛍️',
    'skiing': '⛷️',
    'social': '🤝',
    'transportation': '🚂',
    'urban': '🏙️',
    'water-sports': '🏄',
    'wellness': '🧘',
    'wildlife': '🦋',
  };

  @override
  Widget build(BuildContext context) {
    final categories = getAllCategories();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = selectedCategory == cat;
            final icon = _categoryIcons[cat] ?? '📍';
            final displayName = cat.replaceAll('-', ' ');
            final capitalized = displayName[0].toUpperCase() + displayName.substring(1);
            return _SubfilterChip(
              label: '$icon $capitalized',
              selected: isSelected,
              color: AppColors.success,
              onTap: () => onSelect(cat),
            );
          },
        ),
      ),
    );
  }
}

// ── Skill Subfilters (by individual skill) ──

class _SkillSubfilters extends StatelessWidget {
  final String? selectedSkillId;
  final ValueChanged<String> onSelect;

  const _SkillSubfilters({
    required this.selectedSkillId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: skillRegistry.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final skill = skillRegistry[index];
            final isSelected = selectedSkillId == skill.id;
            return _SubfilterChip(
              label: '${skill.icon} ${skill.name}',
              selected: isSelected,
              color: AppColors.info,
              onTap: () => onSelect(skill.id),
            );
          },
        ),
      ),
    );
  }
}

// ── Shared Widgets ──

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
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

class _SubfilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SubfilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.22)
              : AppColors.bgCard.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.7)
                : AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
