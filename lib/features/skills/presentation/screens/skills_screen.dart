import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/data/quest_categories.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
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

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  /// Filter by super-category ID (null = all).
  String? _filterSuperCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final skillsState = ref.watch(skillsProvider);
    final questsState = ref.watch(questsProvider);

    // Filter skills by super-category
    var skills = skillsState.allSkills;
    if (_filterSuperCategory != null) {
      final sc = getSuperCategoryById(_filterSuperCategory!);
      if (sc != null) {
        skills = skills
            .where((s) => s.categories.any(
                (cat) => sc.questCategories.contains(cat)))
            .toList();
      }
    }

    // Sort by XP (highest first), then alphabetical
    skills = List.of(skills)..sort((a, b) {
      final xpA = questsState.skillXp[a.id] ?? 0;
      final xpB = questsState.skillXp[b.id] ?? 0;
      if (xpA != xpB) return xpB.compareTo(xpA);
      return a.name.compareTo(b.name);
    });

    // Group by super-category when showing all
    final grouped = _filterSuperCategory == null
        ? _groupSkillsBySuperCategory(skills, questsState)
        : null;

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.primaryLight,
          child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navSkills,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    GradientText(
                      text: l10n.nSkills(skills.length),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      gradient: AppGradients.gradientCool,
                    ),
                    const SizedBox(height: 20),
                    // Super-category filter chips (same as quests)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CategoryChip(
                            label: l10n.categoryAll,
                            icon: LucideIcons.layoutGrid,
                            isSelected: _filterSuperCategory == null,
                            onTap: () => setState(() => _filterSuperCategory = null),
                          ),
                          ...questSuperCategories.map((sc) => _CategoryChip(
                            label: sc.label(locale),
                            icon: sc.icon,
                            isSelected: _filterSuperCategory == sc.id,
                            color: sc.color,
                            onTap: () => setState(() {
                              _filterSuperCategory =
                                  _filterSuperCategory == sc.id ? null : sc.id;
                            }),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // Show grouped view or flat list
            if (grouped != null)
              ...grouped.entries.expand((entry) => [
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    superCategory: entry.key,
                    skillCount: entry.value.length,
                    locale: locale,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: entry.value.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final skill = entry.value[index];
                      final xp = questsState.skillXp[skill.id] ?? 0;
                      final level = _levelForSkill(skill, xp);
                      final progress = _progressForSkill(skill, xp);
                      return _SkillListItem(
                        skill: skill,
                        xp: xp,
                        level: level,
                        progress: progress,
                        locale: locale,
                        onTap: () => _showSkillDetail(
                            context, skill, xp, level, progress),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: Duration(milliseconds: (index * 60).clamp(0, 600)))
                          .slideY(begin: 0.05);
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ])
            else
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
                      onTap: () => _showSkillDetail(context, skill, xp, level, progress),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: (index * 60).clamp(0, 600)))
                        .slideY(begin: 0.05);
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        ),
      ),
    );
  }

  /// Group skills by their super-category, maintaining order.
  Map<QuestSuperCategory, List<SkillGroup>> _groupSkillsBySuperCategory(
    List<SkillGroup> skills,
    QuestsState questsState,
  ) {
    final result = <QuestSuperCategory, List<SkillGroup>>{};
    for (final sc in questSuperCategories) {
      result[sc] = [];
    }
    for (final skill in skills) {
      final sc = getSuperCategoryForSkill(skill.categories);
      if (sc != null) {
        result[sc]!.add(skill);
      }
    }
    result.removeWhere((_, v) => v.isEmpty);
    return result;
  }

  int _levelForSkill(SkillGroup skill, int xp) {
    final level = (xp / skill.xpPerLevel).floor() + 1;
    return level.clamp(1, skill.maxLevel);
  }

  double _progressForSkill(SkillGroup skill, int xp) {
    if (skill.xpPerLevel == 0) return 0;
    return (xp % skill.xpPerLevel) / skill.xpPerLevel;
  }

  void _showSkillDetail(
    BuildContext context,
    SkillGroup skill,
    int xp,
    int level,
    double progress,
  ) {
    final questsState = ref.read(questsProvider);
    final relatedQuests = questsState.allQuests
        .where((q) => q.skillType == skill.id)
        .toList();
    final completedQuests = relatedQuests.where((q) => q.isCompleted).length;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SkillDetailSheet(
        skill: skill,
        xp: xp,
        level: level,
        progress: progress,
        completedQuests: completedQuests,
        totalQuests: relatedQuests.length,
        relatedQuestsList: relatedQuests,
        onViewQuests: () {
          Navigator.of(context).pop();
          context.go('/quests');
        },
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final QuestSuperCategory superCategory;
  final int skillCount;
  final Locale locale;

  const _SectionHeader({
    required this.superCategory,
    required this.skillCount,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: superCategory.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              superCategory.icon,
              size: 18,
              color: superCategory.color,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            superCategory.label(locale),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: superCategory.color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: superCategory.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$skillCount',
              style: TextStyle(
                color: superCategory.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ScaleTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      chipColor.withValues(alpha: 0.25),
                      chipColor.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: isSelected ? null : AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? chipColor.withValues(alpha: 0.5)
                  : AppColors.bgCardLight.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? chipColor : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? chipColor : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

// ─── Skill Detail Sheet ───────────────────────────────────────────────────────

class _SkillDetailSheet extends StatelessWidget {
  final SkillGroup skill;
  final int xp;
  final int level;
  final double progress;
  final int completedQuests;
  final int totalQuests;
  final List<SideQuest> relatedQuestsList;
  final VoidCallback onViewQuests;

  const _SkillDetailSheet({
    required this.skill,
    required this.xp,
    required this.level,
    required this.progress,
    required this.completedQuests,
    required this.totalQuests,
    required this.relatedQuestsList,
    required this.onViewQuests,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final gradientStart = _parseColor(skill.gradientStart);
    final gradientEnd = _parseColor(skill.gradientEnd);
    final xpInLevel = xp % skill.xpPerLevel;
    final xpToNext = skill.xpPerLevel - xpInLevel;
    final superCat = getSuperCategoryForSkill(skill.categories);

    // Show up to 3 related quests preview
    final previewQuests = relatedQuestsList.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GlowContainer(
            glowColor: gradientStart,
            borderRadius: 20,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientStart, gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradientStart.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(skill.icon, style: const TextStyle(fontSize: 32)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            RegistryL10n.skillName(locale, skill.id, skill.name),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.lvN(level),
                style: TextStyle(
                  color: gradientStart,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (superCat != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: superCat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(superCat.icon, size: 12, color: superCat.color),
                      const SizedBox(width: 4),
                      Text(
                        superCat.label(locale),
                        style: TextStyle(
                          color: superCat.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 10,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fillWidth = constraints.maxWidth * progress;
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCardLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(5),
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
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: fillWidth > 0
                            ? [
                                BoxShadow(
                                  color: gradientStart.withValues(alpha: 0.4),
                                  blurRadius: 8,
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedCounter(
                value: xpInLevel,
                suffix: ' / ${skill.xpPerLevel} XP',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
              Text(
                l10n.xpNeeded(xpToNext),
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Related quests header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.compass, size: 18,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      l10n.relatedQuests,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.completedOfTotal(completedQuests, totalQuests),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                // Show quest previews
                if (previewQuests.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...previewQuests.map((q) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          q.isCompleted
                              ? LucideIcons.checkCircle
                              : LucideIcons.circle,
                          size: 14,
                          color: q.isCompleted
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            RegistryL10n.questTitle(locale, q.id, q.title),
                            style: TextStyle(
                              fontSize: 12,
                              color: q.isCompleted
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: q.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '+${q.xpReward} XP',
                          style: const TextStyle(
                            color: AppColors.xpGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (relatedQuestsList.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        locale.languageCode == 'he'
                            ? '+${relatedQuestsList.length - 3} משימות נוספות'
                            : '+${relatedQuestsList.length - 3} more quests',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewQuests,
              child: Text(l10n.viewQuests),
            ),
          ),
        ],
      ),
    );
  }

  static Color _parseColor(String hex) {
    final value = hex.replaceAll('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}
