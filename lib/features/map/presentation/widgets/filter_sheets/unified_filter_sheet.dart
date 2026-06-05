import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/area_colors.dart';
import 'package:travel_buddy_mobile/features/map/providers/map_filter_provider.dart';
import 'package:travel_buddy_mobile/shared/data/collection_registry.dart';
import 'package:travel_buddy_mobile/shared/data/quest_registry.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';

const _categoryIcons = <String, String>{
  'adventure': '\u{1F3D4}\uFE0F',
  'camping': '\u26FA',
  'cooking': '\u{1F468}\u200D\u{1F373}',
  'cultural': '\u{1F3DB}\uFE0F',
  'extreme': '\u{1FA82}',
  'fishing': '\u{1F3A3}',
  'food-drink': '\u{1F35C}',
  'hiking': '\u{1F97E}',
  'nightlife': '\u{1F389}',
  'photography': '\u{1F4F8}',
  'shopping': '\u{1F6CD}\uFE0F',
  'skiing': '\u26F7\uFE0F',
  'social': '\u{1F91D}',
  'transportation': '\u{1F682}',
  'urban': '\u{1F3D9}\uFE0F',
  'water-sports': '\u{1F3C4}',
  'wellness': '\u{1F9D8}',
  'wildlife': '\u{1F98B}',
};

const _rarities = [
  ('common', 'Common', Color(0xFF22C55E)),
  ('rare', 'Rare', Color(0xFF3B82F6)),
  ('epic', 'Epic', Color(0xFF9333EA)),
  ('legendary', 'Legendary', Color(0xFFEAB308)),
];

/// Achievement collections that represent individual countries. Used by
/// the "Countries" quick filter to toggle them as a group.
const _kCountryCollectionIds = <String>[
  'europe',
  'africa',
  'asia',
  'americas',
  'south-america',
  'oceania',
];

/// Toggle a whole group of achievement collections at once — if all are
/// selected, remove them; otherwise add all of them.
void _toggleCollectionGroup(
  MapFilterNotifier notifier,
  MapFilterState filter,
  List<String> ids,
) {
  final current = Set<String>.from(filter.selectedAchievementCollections);
  final allIn = ids.every(current.contains);
  if (allIn) {
    current.removeAll(ids);
  } else {
    current.addAll(ids);
  }
  notifier.setAchievementCollections(current);
}

/// Unified filter sheet showing all map filter categories in one scrollable view.
class UnifiedFilterSheet extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const UnifiedFilterSheet({super.key, this.onClose});

  @override
  ConsumerState<UnifiedFilterSheet> createState() => _UnifiedFilterSheetState();
}

class _UnifiedFilterSheetState extends ConsumerState<UnifiedFilterSheet> {
  // The advanced sheet now opens directly from the bubble column's
  // "Advanced settings" entry, so the detailed sections expand by default.
  bool _advancedExpanded = true;
  bool _achievementsExpanded = false;
  bool _activitiesExpanded = false;
  bool _questsExpanded = false;
  bool _groupsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(mapFilterProvider);
    final notifier = ref.read(mapFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header: title + Reset all + X close ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 10, 4),
          child: Row(
            children: [
              const Icon(LucideIcons.slidersHorizontal,
                  size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              const Text(
                'Map Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (filter.hasActiveFilters)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    notifier.resetAll();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Reset all',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onClose?.call();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgCardLight.withValues(alpha: 0.5),
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Quick filters: 2-column grid (advanced sheet keeps the
        // common toggles handy alongside the detailed sections below). ──
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
          child: _QuickFilterGrid(
            rows: [
              _QuickFilterRowData(
                icon: LucideIcons.unlock,
                label: 'Only unlocked',
                color: AppColors.success,
                active: filter.showOnlyUnlocked,
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleShowOnlyUnlocked();
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.flag,
                label: 'Countries',
                color: AppColors.gold,
                active: _kCountryCollectionIds
                    .every(filter.selectedAchievementCollections.contains),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _toggleCollectionGroup(
                      notifier, filter, _kCountryCollectionIds);
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.globe,
                label: 'Continents',
                color: AppColors.gold,
                active: filter.selectedAchievementCollections
                    .contains('continents'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('continents');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.trees,
                label: 'National parks',
                color: AppColors.success,
                active: filter.selectedAchievementCollections
                    .contains('national-parks'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('national-parks');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.church,
                label: 'Holy sites',
                color: const Color(0xFFB07A2E),
                active: filter.selectedAchievementCollections
                    .contains('holy-sites'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('holy-sites');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.waves,
                label: 'Seas',
                color: const Color(0xFF0277BD),
                active: filter.selectedAchievementCollections
                    .contains('seas'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('seas');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.droplet,
                label: 'Lakes',
                color: const Color(0xFF1E88E5),
                active: filter.selectedAchievementCollections
                    .contains('lakes'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('lakes');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.snowflake,
                label: 'Glaciers & Ice',
                color: const Color(0xFF80DEEA),
                active: filter.selectedAchievementCollections
                    .contains('glaciers'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('glaciers');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.sun,
                label: 'Deserts',
                color: const Color(0xFFE6A85C),
                active: filter.selectedAchievementCollections
                    .contains('deserts'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleAchievementCollection('deserts');
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.scroll,
                label: 'Quests',
                color: const Color(0xFF9333EA),
                active: filter.showQuestChains,
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleQuestChains();
                },
              ),
              _QuickFilterRowData(
                icon: LucideIcons.sparkles,
                label: 'Skills',
                color: AppColors.info,
                active: filter.showSkills,
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.toggleSkills();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 2),
        _sectionDivider(),

        // ── "Advanced filters" disclosure ──
        // Collapsed by default — the quick filter column above covers the
        // common cases. Tap to reveal the detailed Achievements /
        // Activities / Quests sections.
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _advancedExpanded = !_advancedExpanded);
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                Icon(LucideIcons.slidersHorizontal,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Advanced filters',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _advancedExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_advancedExpanded) ...[
        // ── Achievements Section ──
        _SectionHeader(
          icon: LucideIcons.trophy,
          label: 'Achievements',
          color: AppColors.gold,
          visible: filter.showAchievements,
          filterCount: filter.selectedAchievementCollections.length,
          onToggleVisibility: () {
            HapticFeedback.selectionClick();
            notifier.toggleAchievements();
          },
          onClear: filter.selectedAchievementCollections.isNotEmpty
              ? () {
                  HapticFeedback.selectionClick();
                  notifier.clearAchievementFilters();
                }
              : null,
          expanded: _achievementsExpanded,
          onToggleExpanded: () {
            HapticFeedback.selectionClick();
            setState(() => _achievementsExpanded = !_achievementsExpanded);
          },
        ),
        if (_achievementsExpanded && filter.showAchievements)
          _AchievementFilterGroups(
            selected: filter.selectedAchievementCollections,
            onToggle: (id) {
              HapticFeedback.selectionClick();
              notifier.toggleAchievementCollection(id);
            },
          ),

        // Per-collection "Display groups" toggles — collapsible, one row
        // per collection that has at least one unlocked polygon-backed
        // member. Each enabled collection draws every member polygon
        // individually (no merging/hulling).
        if (_achievementsExpanded && filter.showAchievements)
          _UnlockedAreaCollectionToggles(
            selected: filter.unlockedAreaCollections,
            expanded: _groupsExpanded,
            onToggleExpanded: () {
              HapticFeedback.selectionClick();
              setState(() => _groupsExpanded = !_groupsExpanded);
            },
            onToggle: (id) {
              HapticFeedback.selectionClick();
              notifier.toggleUnlockedAreaCollection(id);
            },
            onClearAll: filter.unlockedAreaCollections.isNotEmpty
                ? () {
                    HapticFeedback.selectionClick();
                    notifier.clearUnlockedAreaCollections();
                  }
                : null,
          ),

        _sectionDivider(),

        // ── Activities Section ──
        _SectionHeader(
          icon: LucideIcons.swords,
          label: 'Activities',
          color: AppColors.success,
          visible: filter.showQuests,
          filterCount: filter.selectedQuestCategories.length,
          onToggleVisibility: () {
            HapticFeedback.selectionClick();
            notifier.toggleQuests();
          },
          onClear: filter.selectedQuestCategories.isNotEmpty
              ? () {
                  HapticFeedback.selectionClick();
                  notifier.clearActivityFilters();
                }
              : null,
          expanded: _activitiesExpanded,
          onToggleExpanded: () {
            HapticFeedback.selectionClick();
            setState(() => _activitiesExpanded = !_activitiesExpanded);
          },
        ),
        if (_activitiesExpanded && filter.showQuests) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
          _ChipGrid(
            items: getAllCategories().map((cat) {
              final icon = _categoryIcons[cat] ?? '\u{1F4CD}';
              final label = cat.replaceAll('-', ' ');
              return _ChipData(
                id: cat,
                label: '$icon ${label[0].toUpperCase()}${label.substring(1)}',
                selected: filter.selectedQuestCategories.contains(cat),
              );
            }).toList(),
            color: AppColors.success,
            onTap: (id) {
              HapticFeedback.selectionClick();
              notifier.toggleQuestCategory(id);
            },
          ),
          // Skills merged into Activities — only shown when Activities is
          // expanded AND skills are visible.
          if (filter.showSkills) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkles,
                      size: 12, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (filter.selectedSkillIds.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${filter.selectedSkillIds.length}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _ChipGrid(
              items: skillRegistry
                  .map((s) => _ChipData(
                        id: s.id,
                        label: '${s.icon} ${s.name}',
                        selected: filter.selectedSkillIds.contains(s.id),
                      ))
                  .toList(),
              color: AppColors.info,
              onTap: (id) {
                HapticFeedback.selectionClick();
                notifier.toggleSkillId(id);
              },
            ),
          ],
        ],

        _sectionDivider(),

        // ── Quests Section ──
        _SectionHeader(
          icon: LucideIcons.scroll,
          label: 'Quests',
          color: const Color(0xFF9333EA),
          visible: filter.showQuestChains,
          filterCount: filter.selectedQuestChainRarities.length,
          onToggleVisibility: () {
            HapticFeedback.selectionClick();
            notifier.toggleQuestChains();
          },
          onClear: filter.selectedQuestChainRarities.isNotEmpty
              ? () {
                  HapticFeedback.selectionClick();
                  notifier.clearQuestFilters();
                }
              : null,
          expanded: _questsExpanded,
          onToggleExpanded: () {
            HapticFeedback.selectionClick();
            setState(() => _questsExpanded = !_questsExpanded);
          },
        ),
        if (_questsExpanded && filter.showQuestChains)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: _rarities.map((r) {
                final (id, label, color) = r;
                final isSelected =
                    filter.selectedQuestChainRarities.contains(id);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: id != 'legendary' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        notifier.toggleQuestChainRarity(id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : AppColors.bgCardLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? color.withValues(alpha: 0.5)
                                : AppColors.textMuted.withValues(alpha: 0.15),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: -2,
                                    right: -10,
                                    child: Icon(LucideIcons.check,
                                        size: 10, color: color),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? color
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ], // end of _advancedExpanded block

        const SizedBox(height: 8),
      ],
    );
  }

  static Widget _sectionDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Divider(
          color: AppColors.textMuted.withValues(alpha: 0.12),
          height: 1,
        ),
      );
}

// ── Shared Components ──

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool visible;
  final int filterCount;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onClear;
  /// When non-null, renders an expand/collapse chevron. Tap the whole
  /// header row to toggle expansion.
  final bool? expanded;
  final VoidCallback? onToggleExpanded;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
    required this.visible,
    required this.filterCount,
    required this.onToggleVisibility,
    this.onClear,
    this.expanded,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleExpanded,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: visible ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            if (filterCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$filterCount',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: onToggleVisibility,
              child: _VisibilityDot(visible: visible, color: color),
            ),
            if (expanded != null) ...[
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: expanded! ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickFilterRowData {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _QuickFilterRowData({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });
}

/// 2-column grid of compact quick-filter checkbox rows. Used at the top
/// of the advanced filter sheet so the common toggles stay reachable
/// alongside the deeper sections.
class _QuickFilterGrid extends StatelessWidget {
  final List<_QuickFilterRowData> rows;
  const _QuickFilterGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    final pairs = <List<_QuickFilterRowData>>[];
    for (var i = 0; i < rows.length; i += 2) {
      pairs.add(rows.sublist(i, (i + 2).clamp(0, rows.length)));
    }
    return Column(
      children: pairs.map((pair) {
        return Row(
          children: [
            Expanded(child: _QuickFilterRow(data: pair[0])),
            const SizedBox(width: 8),
            Expanded(
              child: pair.length > 1
                  ? _QuickFilterRow(data: pair[1])
                  : const SizedBox.shrink(),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Compact one-line row used inside [_QuickFilterGrid]. Left checkbox
/// shows state + toggles on tap. Tap anywhere on the row to toggle.
class _QuickFilterRow extends StatelessWidget {
  final _QuickFilterRowData data;

  const _QuickFilterRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final active = data.active;
    return GestureDetector(
      onTap: data.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: active ? data.color : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: active
                      ? data.color
                      : AppColors.textMuted.withValues(alpha: 0.5),
                  width: 1.4,
                ),
              ),
              child: active
                  ? const Icon(LucideIcons.check,
                      size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Icon(data.icon,
                size: 14,
                color: active ? data.color : AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityDot extends StatelessWidget {
  final bool visible;
  final Color color;

  const _VisibilityDot({required this.visible, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: visible
            ? color.withValues(alpha: 0.15)
            : AppColors.bgCardLight,
        border: Border.all(
          color: visible
              ? color.withValues(alpha: 0.4)
              : AppColors.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Icon(
        visible ? LucideIcons.eye : LucideIcons.eyeOff,
        size: 13,
        color: visible ? color : AppColors.textMuted,
      ),
    );
  }
}

class _ChipData {
  final String id;
  final String label;
  final bool selected;
  const _ChipData(
      {required this.id, required this.label, required this.selected});
}

class _ChipGrid extends StatelessWidget {
  final List<_ChipData> items;
  final Color color;
  final ValueChanged<String> onTap;

  const _ChipGrid({
    required this.items,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items.map((item) {
          return GestureDetector(
            onTap: () => onTap(item.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: item.selected
                    ? color.withValues(alpha: 0.15)
                    : AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.selected
                      ? color.withValues(alpha: 0.4)
                      : AppColors.textMuted.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.selected) ...[
                    Icon(LucideIcons.check, size: 11, color: color),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          item.selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          item.selected ? color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Organizes the ~17 achievement collections into four expandable groups:
/// Local, Themed, Countries, Global. Each group header shows its name,
/// icon, and how many filters are currently active inside it.
class _AchievementFilterGroups extends StatefulWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _AchievementFilterGroups({
    required this.selected,
    required this.onToggle,
  });

  @override
  State<_AchievementFilterGroups> createState() =>
      _AchievementFilterGroupsState();
}

class _AchievementFilterGroupsState extends State<_AchievementFilterGroups> {
  String? _expanded; // group id currently expanded

  static const _groups = <_FilterGroup>[
    _FilterGroup(
      id: 'local',
      label: 'Local',
      icon: LucideIcons.landmark,
      collectionIds: ['landmarks', 'beaches', 'parks', 'culture'],
    ),
    _FilterGroup(
      id: 'themed',
      label: 'Themed',
      icon: LucideIcons.star,
      collectionIds: [
        'national-parks', 'ski-resorts', 'capitals',
        'ancient-sites', 'holy-sites', 'seas', 'lakes', 'mountains',
        'volcanoes', 'glaciers', 'deserts', 'tourist-destinations',
      ],
    ),
    _FilterGroup(
      id: 'countries',
      label: 'Countries',
      icon: LucideIcons.flag,
      collectionIds: [
        'europe', 'asia', 'africa', 'americas', 'south-america', 'oceania',
      ],
    ),
    _FilterGroup(
      id: 'global',
      label: 'Global',
      icon: LucideIcons.globe,
      collectionIds: ['continents', 'zones'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final group in _groups) ...[
            _buildGroup(group),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildGroup(_FilterGroup group) {
    final isExpanded = _expanded == group.id;
    final activeCount =
        group.collectionIds.where(widget.selected.contains).length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = isExpanded ? null : group.id);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: activeCount > 0
                    ? AppColors.gold.withValues(alpha: 0.10)
                    : AppColors.bgCardLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(10),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(10),
                ),
                border: Border.all(
                  color: activeCount > 0
                      ? AppColors.gold.withValues(alpha: 0.3)
                      : AppColors.bgCardLight.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(group.icon,
                      size: 14,
                      color: activeCount > 0
                          ? AppColors.gold
                          : AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (activeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$activeCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          // Collapsible body
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 160),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: AppColors.bgCardLight.withValues(alpha: 0.25),
                border: Border.all(
                  color: AppColors.bgCardLight.withValues(alpha: 0.4),
                ),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: group.collectionIds.map((id) {
                  final info = getCollectionInfo(id);
                  if (info == null) return const SizedBox.shrink();
                  final selected = widget.selected.contains(id);
                  return GestureDetector(
                    onTap: () => widget.onToggle(id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.gold.withValues(alpha: 0.5)
                              : AppColors.textMuted.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected) ...[
                            Icon(LucideIcons.check,
                                size: 11, color: AppColors.gold),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${info.icon} ${info.name}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.gold
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _FilterGroup {
  final String id;
  final String label;
  final IconData icon;
  final List<String> collectionIds;
  const _FilterGroup({
    required this.id,
    required this.label,
    required this.icon,
    required this.collectionIds,
  });
}

/// Per-collection "Display groups" toggles. Only collections that have at
/// least one unlocked polygon-backed achievement are shown, so the list
/// stays meaningful. Collapsible via a chevron on the header row.
class _UnlockedAreaCollectionToggles extends ConsumerWidget {
  final Set<String> selected;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final void Function(String collectionId) onToggle;
  final VoidCallback? onClearAll;

  const _UnlockedAreaCollectionToggles({
    required this.selected,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onToggle,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);

    final counts = <String, int>{};
    for (final a in achievements.allAchievements) {
      if (!a.isUnlocked) continue;
      if (!a.hasPolygon) continue;
      final cid = a.collectionId;
      if (cid == null) continue;
      counts[cid] = (counts[cid] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const SizedBox.shrink();
    }

    final collections = collectionRegistry
        .where((c) => counts.containsKey(c.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggleExpanded,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Icon(LucideIcons.layers,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Display groups',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (selected.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${selected.length}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (onClearAll != null) ...[
                  GestureDetector(
                    onTap: onClearAll,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (!expanded) const SizedBox(height: 4),
          if (expanded) const SizedBox(height: 8),
          if (expanded)
            Column(
            children: collections.map((c) {
              final isOn = selected.contains(c.id);
              final count = counts[c.id] ?? 0;
              final accent = colorForCollection(c.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => onToggle(c.id),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOn
                          ? accent.withValues(alpha: 0.14)
                          : AppColors.bgCardLight.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOn
                            ? accent.withValues(alpha: 0.5)
                            : AppColors.bgCardLight.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: isOn ? 0.9 : 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(c.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isOn ? FontWeight.w700 : FontWeight.w600,
                              color: isOn
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: isOn,
                          onChanged: (_) => onToggle(c.id),
                          activeThumbColor: accent,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


