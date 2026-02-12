import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/l10n/registry_l10n.dart';
import 'package:travel_buddy/shared/models/skill_group.dart';
import 'package:travel_buddy/shared/providers/quests_provider.dart';
import 'package:travel_buddy/shared/providers/skills_provider.dart';
import 'package:travel_buddy/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy/shared/widgets/visual_extras.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  String? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final skillsState = ref.watch(skillsProvider);
    final questsState = ref.watch(questsProvider);

    // Filter skills by category
    var skills = skillsState.allSkills;
    if (_filterCategory != null) {
      skills = skills
          .where((s) => s.categories.contains(_filterCategory))
          .toList();
    }

    // Sort by XP (highest first), then alphabetical
    skills = List.of(skills)..sort((a, b) {
      final xpA = questsState.skillXp[a.id] ?? 0;
      final xpB = questsState.skillXp[b.id] ?? 0;
      if (xpA != xpB) return xpB.compareTo(xpA);
      return a.name.compareTo(b.name);
    });

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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CategoryChip(
                            label: l10n.categoryAll,
                            icon: LucideIcons.layoutGrid,
                            isSelected: _filterCategory == null,
                            onTap: () => setState(() => _filterCategory = null),
                          ),
                          _CategoryChip(
                            label: l10n.categoryHiking,
                            icon: LucideIcons.mountain,
                            isSelected: _filterCategory == 'hiking',
                            onTap: () => setState(() => _filterCategory = 'hiking'),
                          ),
                          _CategoryChip(
                            label: l10n.categoryFood,
                            icon: LucideIcons.utensils,
                            isSelected: _filterCategory == 'cooking',
                            onTap: () => setState(() => _filterCategory = 'cooking'),
                          ),
                          _CategoryChip(
                            label: l10n.categoryWater,
                            icon: LucideIcons.waves,
                            isSelected: _filterCategory == 'water-sports',
                            onTap: () => setState(() => _filterCategory = 'water-sports'),
                          ),
                          _CategoryChip(
                            label: l10n.categoryPhoto,
                            icon: LucideIcons.camera,
                            isSelected: _filterCategory == 'photography',
                            onTap: () => setState(() => _filterCategory = 'photography'),
                          ),
                          _CategoryChip(
                            label: l10n.categoryCulture,
                            icon: LucideIcons.landmark,
                            isSelected: _filterCategory == 'cultural',
                            onTap: () => setState(() => _filterCategory = 'cultural'),
                          ),
                          _CategoryChip(
                            label: l10n.categoryExtreme,
                            icon: LucideIcons.zap,
                            isSelected: _filterCategory == 'extreme',
                            onTap: () => setState(() => _filterCategory = 'extreme'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
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
                      .fadeIn(duration: 400.ms, delay: (index * 60).ms)
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
        onViewQuests: () {
          Navigator.of(context).pop();
          context.go('/quests');
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.primary.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: isSelected ? null : AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.bgCardLight.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? AppColors.primaryLight : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
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

class _SkillDetailSheet extends StatelessWidget {
  final SkillGroup skill;
  final int xp;
  final int level;
  final double progress;
  final int completedQuests;
  final int totalQuests;
  final VoidCallback onViewQuests;

  const _SkillDetailSheet({
    required this.skill,
    required this.xp,
    required this.level,
    required this.progress,
    required this.completedQuests,
    required this.totalQuests,
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
          Text(
            l10n.lvN(level),
            style: TextStyle(
              color: gradientStart,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
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
