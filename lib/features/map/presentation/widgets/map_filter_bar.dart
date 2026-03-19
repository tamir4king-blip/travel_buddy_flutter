import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_filter_provider.dart';
import 'package:travel_buddy_mobile/shared/data/collection_registry.dart';
import 'package:travel_buddy_mobile/shared/data/quest_registry.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';

/// Right-side vertical filter panel with circle toggles.
/// Subfilters expand horizontally (right-to-left) as scrollable pill rows.
/// All categories can be expanded simultaneously.
class MapFilterBar extends ConsumerStatefulWidget {
  const MapFilterBar({super.key});

  @override
  ConsumerState<MapFilterBar> createState() => _MapFilterBarState();
}

class _MapFilterBarState extends ConsumerState<MapFilterBar>
    with TickerProviderStateMixin {
  final Set<_FilterCategory> _expandedCategories = {};

  // One animation controller per category
  late final Map<_FilterCategory, AnimationController> _animControllers;

  @override
  void initState() {
    super.initState();
    _animControllers = {
      for (final cat in _FilterCategory.values)
        cat: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _animControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleFilter(_FilterCategory category) {
    final notifier = ref.read(mapFilterProvider.notifier);
    switch (category) {
      case _FilterCategory.achievements:
        notifier.toggleAchievements();
      case _FilterCategory.quests:
        notifier.toggleQuests();
      case _FilterCategory.skills:
        notifier.toggleSkills();
    }
    // Collapse subfilters if we just disabled this category
    final filter = ref.read(mapFilterProvider);
    final stillActive = switch (category) {
      _FilterCategory.achievements => filter.showAchievements,
      _FilterCategory.quests => filter.showQuests,
      _FilterCategory.skills => filter.showSkills,
    };
    if (!stillActive && _expandedCategories.contains(category)) {
      _collapseCategory(category);
    }
    HapticFeedback.selectionClick();
  }

  void _toggleExpand(_FilterCategory category) {
    if (_expandedCategories.contains(category)) {
      _collapseCategory(category);
    } else {
      setState(() => _expandedCategories.add(category));
      _animControllers[category]!.forward(from: 0);
    }
    HapticFeedback.selectionClick();
  }

  void _collapseCategory(_FilterCategory category) {
    _animControllers[category]!.reverse().then((_) {
      if (mounted) setState(() => _expandedCategories.remove(category));
    });
  }

  void _onSubfilterTap(_FilterCategory category, String id) {
    final notifier = ref.read(mapFilterProvider.notifier);
    switch (category) {
      case _FilterCategory.achievements:
        notifier.toggleAchievementCollection(id);
      case _FilterCategory.quests:
        notifier.toggleQuestCategory(id);
      case _FilterCategory.skills:
        notifier.toggleSkillId(id);
    }
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(mapFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Achievements row
        _FilterRow(
          category: _FilterCategory.achievements,
          label: l10n.navAchievements,
          icon: LucideIcons.trophy,
          color: AppColors.gold,
          active: filter.showAchievements,
          expanded: _expandedCategories.contains(_FilterCategory.achievements),
          animController: _animControllers[_FilterCategory.achievements]!,
          onToggle: () => _toggleFilter(_FilterCategory.achievements),
          onArrowTap: filter.showAchievements
              ? () => _toggleExpand(_FilterCategory.achievements)
              : null,
          subfilterItems: collectionRegistry
              .map((c) => _SubfilterItem(
                    id: c.id,
                    label: '${c.icon} ${c.name}',
                    selected:
                        filter.selectedAchievementCollections.contains(c.id),
                  ))
              .toList(),
          onSubfilterTap: (id) =>
              _onSubfilterTap(_FilterCategory.achievements, id),
        ),
        const SizedBox(height: 10),

        // Quests row
        _FilterRow(
          category: _FilterCategory.quests,
          label: l10n.navQuests,
          icon: LucideIcons.swords,
          color: AppColors.success,
          active: filter.showQuests,
          expanded: _expandedCategories.contains(_FilterCategory.quests),
          animController: _animControllers[_FilterCategory.quests]!,
          onToggle: () => _toggleFilter(_FilterCategory.quests),
          onArrowTap: filter.showQuests
              ? () => _toggleExpand(_FilterCategory.quests)
              : null,
          subfilterItems: getAllCategories()
              .map((cat) => _SubfilterItem(
                    id: cat,
                    label:
                        '${_questCategoryIcons[cat] ?? "📍"} ${cat.replaceAll("-", " ").capitalize()}',
                    selected: filter.selectedQuestCategories.contains(cat),
                  ))
              .toList(),
          onSubfilterTap: (id) =>
              _onSubfilterTap(_FilterCategory.quests, id),
        ),
        const SizedBox(height: 10),

        // Skills row
        _FilterRow(
          category: _FilterCategory.skills,
          label: l10n.navSkills,
          icon: LucideIcons.sparkles,
          color: AppColors.info,
          active: filter.showSkills,
          expanded: _expandedCategories.contains(_FilterCategory.skills),
          animController: _animControllers[_FilterCategory.skills]!,
          onToggle: () => _toggleFilter(_FilterCategory.skills),
          onArrowTap: filter.showSkills
              ? () => _toggleExpand(_FilterCategory.skills)
              : null,
          subfilterItems: skillRegistry
              .map((s) => _SubfilterItem(
                    id: s.id,
                    label: '${s.icon} ${s.name}',
                    selected: filter.selectedSkillIds.contains(s.id),
                  ))
              .toList(),
          onSubfilterTap: (id) =>
              _onSubfilterTap(_FilterCategory.skills, id),
        ),
      ],
    );
  }
}

// ── Types ──

enum _FilterCategory { achievements, quests, skills }

const _questCategoryIcons = <String, String>{
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

// ── Filter row: bubble on right, horizontal pill slider expanding left ──

class _FilterRow extends StatelessWidget {
  final _FilterCategory category;
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final bool expanded;
  final AnimationController animController;
  final VoidCallback onToggle;
  final VoidCallback? onArrowTap;
  final List<_SubfilterItem> subfilterItems;
  final ValueChanged<String> onSubfilterTap;

  const _FilterRow({
    required this.category,
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.expanded,
    required this.animController,
    required this.onToggle,
    this.onArrowTap,
    required this.subfilterItems,
    required this.onSubfilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final curvedAnim = CurvedAnimation(
      parent: animController,
      curve: Curves.easeOutCubic,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Horizontal subfilter pills — expand left from the bubble
        if (expanded)
          AnimatedBuilder(
            animation: curvedAnim,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: curvedAnim.value,
                  child: Opacity(
                    opacity: curvedAnim.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 100,
              ),
              margin: const EdgeInsets.only(right: 8),
              height: 34,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // scrolls from right to left
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < subfilterItems.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      _SubfilterChip(
                        item: subfilterItems[i],
                        color: color,
                        onTap: () => onSubfilterTap(subfilterItems[i].id),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

        // Arrow — points left when collapsed, right when expanded
        if (onArrowTap != null)
          GestureDetector(
            onTap: onArrowTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: AnimatedRotation(
                turns: expanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 18,
                  color: color,
                ),
              ),
            ),
          ),

        // Bubble with label
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: active ? color : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? color : AppColors.bgCard,
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
                  size: 20,
                  color: active ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Subfilter data ──

class _SubfilterItem {
  final String id;
  final String label;
  final bool selected;
  const _SubfilterItem({
    required this.id,
    required this.label,
    required this.selected,
  });
}

// ── Compact subfilter chip for horizontal row ──

class _SubfilterChip extends StatelessWidget {
  final _SubfilterItem item;
  final Color color;
  final VoidCallback onTap;

  const _SubfilterChip({
    required this.item,
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
          color: item.selected ? color : AppColors.bgCard,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          item.label,
          style: TextStyle(
            color: item.selected ? Colors.white : AppColors.textPrimary,
            fontSize: 11,
            fontWeight: item.selected ? FontWeight.w700 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

extension _StringCap on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
