import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/data/quest_categories.dart';
import 'package:travel_buddy_mobile/shared/models/skill_group.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/skills_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

enum _ViewMode { categories, allSkills }

class _SkillsScreenState extends ConsumerState<SkillsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Selected super-category (null = landing page).
  QuestSuperCategory? _selectedCategory;
  _ViewMode _viewMode = _ViewMode.categories;
  int _gridColumns = 1;

  void _selectCategory(QuestSuperCategory sc) {
    setState(() => _selectedCategory = sc);
  }

  void _goBack() {
    setState(() => _selectedCategory = null);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final skillsState = ref.watch(skillsProvider);
    final questsState = ref.watch(questsProvider);

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.primaryLight,
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_selectedCategory != null) ...[
                      GestureDetector(
                        onTap: _goBack,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
                          ),
                          child: const Icon(LucideIcons.arrowLeft, size: 20, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCategory != null
                                ? _selectedCategory!.label(locale)
                                : l10n.navSkills,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          GradientText(
                            text: l10n.nSkills(skillsState.allSkills.length),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            gradient: AppGradients.gradientCool,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ── View mode & grid toolbar ──
              if (_selectedCategory == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // View mode toggle
                      _ToolbarToggle(
                        options: const ['Categories', 'All Skills'],
                        selectedIndex: _viewMode.index,
                        onChanged: (i) => setState(() {
                          _viewMode = _ViewMode.values[i];
                        }),
                      ),
                      const Spacer(),
                      // Grid columns (only when showing all skills or inside a category)
                      if (_viewMode == _ViewMode.allSkills)
                        _GridColumnPicker(
                          columns: _gridColumns,
                          onChanged: (c) => setState(() => _gridColumns = c),
                        ),
                    ],
                  ),
                ),
              if (_selectedCategory != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _GridColumnPicker(
                        columns: _gridColumns,
                        onChanged: (c) => setState(() => _gridColumns = c),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // ── Content ──
              Expanded(
                child: _selectedCategory != null
                    ? _buildCategorySkills(skillsState, questsState, locale)
                    : _viewMode == _ViewMode.categories
                        ? _SkillsLandingPage(
                            skillsState: skillsState,
                            questsState: questsState,
                            locale: locale,
                            onCategorySelected: _selectCategory,
                          )
                        : _buildAllSkills(skillsState, questsState, locale),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySkills(
    SkillsState skillsState,
    QuestsState questsState,
    Locale locale,
  ) {
    final sc = _selectedCategory!;
    var skills = skillsState.allSkills
        .where((s) => s.categories.any(
            (cat) => sc.questCategories.contains(cat)))
        .toList();

    // Sort by XP (highest first), then alphabetical
    skills.sort((a, b) {
      final xpA = questsState.skillXp[a.id] ?? 0;
      final xpB = questsState.skillXp[b.id] ?? 0;
      if (xpA != xpB) return xpB.compareTo(xpA);
      return a.name.compareTo(b.name);
    });

    return _buildSkillsGrid(skills, questsState, locale);
  }

  Widget _buildAllSkills(
    SkillsState skillsState,
    QuestsState questsState,
    Locale locale,
  ) {
    final skills = List<SkillGroup>.from(skillsState.allSkills);
    skills.sort((a, b) {
      final xpA = questsState.skillXp[a.id] ?? 0;
      final xpB = questsState.skillXp[b.id] ?? 0;
      if (xpA != xpB) return xpB.compareTo(xpA);
      return a.name.compareTo(b.name);
    });
    return _buildSkillsGrid(skills, questsState, locale);
  }

  Widget _buildSkillsGrid(
    List<SkillGroup> skills,
    QuestsState questsState,
    Locale locale,
  ) {
    if (_gridColumns == 1) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: skills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final skill = skills[index];
                final xp = questsState.skillXp[skill.id] ?? 0;
                final level = _levelForSkill(skill, xp);
                final progress = _progressForSkill(skill, xp);
                return _SkillListItem(
                  skill: skill,
                  xp: xp,
                  level: level,
                  progress: progress,
                  locale: locale,
                  onTap: () => context.push('/skills/${skill.id}'),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: Duration(milliseconds: (index * 60).clamp(0, 600)))
                    .slideY(begin: 0.05);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
    }

    // Grid layout for 2 or 3 columns
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridColumns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: _gridColumns == 2 ? 0.85 : 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              childCount: skills.length,
              (context, index) {
                final skill = skills[index];
                final xp = questsState.skillXp[skill.id] ?? 0;
                final level = _levelForSkill(skill, xp);
                final progress = _progressForSkill(skill, xp);
                return _SkillGridItem(
                  skill: skill,
                  xp: xp,
                  level: level,
                  progress: progress,
                  locale: locale,
                  onTap: () => context.push('/skills/${skill.id}'),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: Duration(milliseconds: (index * 40).clamp(0, 400)))
                    .scale(begin: const Offset(0.95, 0.95));
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  int _levelForSkill(SkillGroup skill, int xp) {
    final level = (xp / skill.xpPerLevel).floor() + 1;
    return level.clamp(1, skill.maxLevel);
  }

  double _progressForSkill(SkillGroup skill, int xp) {
    if (skill.xpPerLevel == 0) return 0;
    return (xp % skill.xpPerLevel) / skill.xpPerLevel;
  }

}

// ─── Skills Landing Page ──────────────────────────────────────────────────────

class _SkillsLandingPage extends StatelessWidget {
  final SkillsState skillsState;
  final QuestsState questsState;
  final Locale locale;
  final ValueChanged<QuestSuperCategory> onCategorySelected;

  const _SkillsLandingPage({
    required this.skillsState,
    required this.questsState,
    required this.locale,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: questSuperCategories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sc = questSuperCategories[index];
        final skills = skillsState.allSkills
            .where((s) => s.categories.any(
                (cat) => sc.questCategories.contains(cat)))
            .toList();
        final totalXp = skills.fold<int>(
            0, (sum, s) => sum + (questsState.skillXp[s.id] ?? 0));

        return _CategoryCard(
          superCategory: sc,
          skillCount: skills.length,
          totalXp: totalXp,
          locale: locale,
          onTap: () => onCategorySelected(sc),
          index: index,
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final QuestSuperCategory superCategory;
  final int skillCount;
  final int totalXp;
  final Locale locale;
  final VoidCallback onTap;
  final int index;

  const _CategoryCard({
    required this.superCategory,
    required this.skillCount,
    required this.totalXp,
    required this.locale,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.bgCard,
          border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: superCategory.color.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: superCategory.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    superCategory.icon,
                    size: 24,
                    color: superCategory.color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name + stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      superCategory.label(locale),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.nSkills(skillCount)}  •  $totalXp XP',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Chevron
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 60).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05);
  }
}

// ─── Skill List Item ──────────────────────────────────────────────────────────

class _SkillListItem extends StatelessWidget {
  final SkillGroup skill;
  final int xp;
  final int level;
  final double progress;
  final Locale locale;
  final VoidCallback onTap;

  const _SkillListItem({
    required this.skill,
    required this.xp,
    required this.level,
    required this.progress,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gradientStart = _parseColor(skill.gradientStart);
    final gradientEnd = _parseColor(skill.gradientEnd);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            GlowContainer(
              glowColor: gradientStart,
              borderRadius: 12,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(skill.icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          RegistryL10n.skillName(locale, skill.id, skill.name),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      GlowContainer(
                        glowColor: gradientStart,
                        borderRadius: 8,
                        pulse: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: gradientStart.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.lvN(level),
                            style: TextStyle(
                              color: gradientStart,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    RegistryL10n.skillDescription(
                        locale, skill.id, skill.description),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 6,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final fillWidth = constraints.maxWidth * progress;
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.bgCardLight.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 700),
                                    curve: Curves.easeOutCubic,
                                    width: fillWidth,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [gradientStart, gradientEnd],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: fillWidth > 0
                                          ? [
                                              BoxShadow(
                                                color: gradientStart.withValues(alpha: 0.4),
                                                blurRadius: 6,
                                                spreadRadius: -1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedCounter(
                        value: xp,
                        suffix: ' XP',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isRtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  static Color _parseColor(String hex) {
    final value = hex.replaceAll('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

// ─── Skill Grid Item (compact card for 2-3 column layouts) ───────────────────

class _SkillGridItem extends StatelessWidget {
  final SkillGroup skill;
  final int xp;
  final int level;
  final double progress;
  final Locale locale;
  final VoidCallback onTap;

  const _SkillGridItem({
    required this.skill,
    required this.xp,
    required this.level,
    required this.progress,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gradientStart = _parseColor(skill.gradientStart);
    final gradientEnd = _parseColor(skill.gradientEnd);

    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.bgCardLight.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            GlowContainer(
              glowColor: gradientStart,
              borderRadius: 14,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(skill.icon, style: const TextStyle(fontSize: 20)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              RegistryL10n.skillName(locale, skill.id, skill.name),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: gradientStart.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.lvN(level),
                style: TextStyle(
                  color: gradientStart,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            SizedBox(
              height: 5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fillWidth = constraints.maxWidth * progress;
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgCardLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        width: fillWidth,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [gradientStart, gradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            // XP
            Text(
              '$xp XP',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _parseColor(String hex) {
    final value = hex.replaceAll('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

// ─── Toolbar Widgets ─────────────────────────────────────────────────────────

class _ToolbarToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ToolbarToggle({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.bgCard : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: selected
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)]
                    : null,
              ),
              child: Text(
                options[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GridColumnPicker extends StatelessWidget {
  final int columns;
  final ValueChanged<int> onChanged;

  const _GridColumnPicker({
    required this.columns,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _gridButton(1, LucideIcons.alignJustify),
          _gridButton(2, LucideIcons.layoutGrid),
          _gridButton(3, LucideIcons.grid),
        ],
      ),
    );
  }

  Widget _gridButton(int cols, IconData icon) {
    final selected = columns == cols;
    return GestureDetector(
      onTap: () => onChanged(cols),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? AppColors.bgCard : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}

