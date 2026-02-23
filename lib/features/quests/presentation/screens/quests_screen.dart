import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/l10n/registry_l10n.dart';
import 'package:travel_buddy_mobile/shared/data/quest_categories.dart';
import 'package:travel_buddy_mobile/shared/data/skill_registry.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  /// Currently selected super-category filter (null = all).
  String? _superCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final state = ref.watch(questsProvider);
    final notifier = ref.read(questsProvider.notifier);

    // Apply super-category filter
    List<SideQuest> filtered;
    if (_superCategoryFilter != null) {
      final sc = getSuperCategoryById(_superCategoryFilter!);
      if (sc != null) {
        filtered = state.allQuests
            .where((q) => sc.questCategories.contains(q.category))
            .toList();
      } else {
        filtered = state.allQuests;
      }
    } else {
      filtered = state.allQuests;
    }

    // Sort: unlocked quests first, then locked quests
    final sorted = List<SideQuest>.from(filtered)..sort((a, b) {
      final aUnlocked = a.isUnlocked(
        skillLevels: state.skillLevels,
        allQuests: state.allQuests,
      );
      final bUnlocked = b.isUnlocked(
        skillLevels: state.skillLevels,
        allQuests: state.allQuests,
      );
      if (aUnlocked && !bUnlocked) return -1;
      if (!aUnlocked && bUnlocked) return 1;
      return 0;
    });

    // Group quests by super-category for section display
    final grouped = _groupQuestsBySuperCategory(sorted);

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.primary,
          child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientText(
                    text: l10n.sideQuests,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    gradient: AppGradients.gradientPrimary,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AnimatedCounter(
                        value: state.completedCount,
                        style: TextStyle(color: AppColors.textSecondary),
                        suffix: ' ${locale.languageCode == 'he' ? 'משימות' : (state.completedCount == 1 ? 'quest' : 'quests')}',
                      ),
                      Text(
                        '  \u2022  ${l10n.dayStreak(state.currentStreak)}',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Super-category filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryChip(
                          label: l10n.categoryAll,
                          icon: LucideIcons.layoutGrid,
                          isSelected: _superCategoryFilter == null,
                          onTap: () => setState(() => _superCategoryFilter = null),
                        ),
                        ...questSuperCategories.map((sc) => _CategoryChip(
                          label: sc.label(locale),
                          icon: sc.icon,
                          isSelected: _superCategoryFilter == sc.id,
                          color: sc.color,
                          onTap: () => setState(() {
                            _superCategoryFilter =
                                _superCategoryFilter == sc.id ? null : sc.id;
                          }),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Build grouped sections when showing all, or flat list when filtered
          if (_superCategoryFilter == null)
            ...grouped.entries.expand((entry) => [
              SliverToBoxAdapter(
                child: _SectionHeader(
                  superCategory: entry.key,
                  questCount: entry.value.length,
                  locale: locale,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: entry.value.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildQuestCard(
                    context, entry.value[index], state, notifier, l10n, index,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ])
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildQuestCard(
                  context, sorted[index], state, notifier, l10n, index,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      ),
      ),
    );
  }

  Widget _buildQuestCard(
    BuildContext context,
    SideQuest quest,
    QuestsState state,
    QuestsNotifier notifier,
    AppLocalizations l10n,
    int index,
  ) {
    final isLocked = !quest.isUnlocked(
      skillLevels: state.skillLevels,
      allQuests: state.allQuests,
    );
    final requirementText = isLocked
        ? _buildRequirementText(quest, state.allQuests, l10n)
        : null;
    return _QuestCard(
      quest: quest,
      isLocked: isLocked,
      requirementText: requirementText,
      onComplete: () => notifier.completeQuest(quest.id),
      onDetails: () => _showQuestDetails(
          context, quest, notifier, isLocked, requirementText),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: (index * 80).clamp(0, 800)))
        .slideY(begin: 0.05);
  }

  /// Group quests by their super-category, maintaining order.
  Map<QuestSuperCategory, List<SideQuest>> _groupQuestsBySuperCategory(
    List<SideQuest> quests,
  ) {
    final result = <QuestSuperCategory, List<SideQuest>>{};
    // Initialize in defined order
    for (final sc in questSuperCategories) {
      result[sc] = [];
    }
    for (final quest in quests) {
      final sc = getSuperCategoryForQuest(quest.category);
      if (sc != null) {
        result[sc]!.add(quest);
      }
    }
    // Remove empty groups
    result.removeWhere((_, v) => v.isEmpty);
    return result;
  }

  String _buildRequirementText(
    SideQuest quest,
    List<SideQuest> allQuests,
    AppLocalizations l10n,
  ) {
    final parts = <String>[];
    if (quest.requiredSkillType != null && quest.requiredSkillLevel != null) {
      final skillName = quest.requiredSkillType!;
      final capitalName = skillName[0].toUpperCase() + skillName.substring(1);
      parts.add('$capitalName ${l10n.lvN(quest.requiredSkillLevel!)}');
    }
    for (final reqId in quest.requiredQuestIds) {
      final reqQuest = allQuests.where((q) => q.id == reqId).firstOrNull;
      if (reqQuest != null && !reqQuest.isCompleted) {
        final locale = Localizations.localeOf(context);
        parts.add(RegistryL10n.questTitle(locale, reqQuest.id, reqQuest.title));
      }
    }
    return parts.join(' + ');
  }

  void _showQuestDetails(
    BuildContext context,
    SideQuest quest,
    QuestsNotifier notifier,
    bool isLocked,
    String? requirementText,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuestDetailSheet(
        quest: quest,
        isLocked: isLocked,
        requirementText: requirementText,
        onComplete: () {
          Navigator.of(context).pop();
          notifier.completeQuest(quest.id);
        },
        onViewSkill: () {
          Navigator.of(context).pop();
          context.go('/skills');
        },
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final QuestSuperCategory superCategory;
  final int questCount;
  final Locale locale;

  const _SectionHeader({
    required this.superCategory,
    required this.questCount,
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
              '$questCount',
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

// ─── Quest Card ───────────────────────────────────────────────────────────────

class _QuestCard extends StatelessWidget {
  final SideQuest quest;
  final bool isLocked;
  final String? requirementText;
  final VoidCallback onComplete;
  final VoidCallback onDetails;

  const _QuestCard({
    required this.quest,
    this.isLocked = false,
    this.requirementText,
    required this.onComplete,
    required this.onDetails,
  });

  Color get _difficultyColor => switch (quest.difficulty) {
        QuestDifficulty.easy => AppColors.success,
        QuestDifficulty.medium => AppColors.warning,
        QuestDifficulty.hard => AppColors.error,
        QuestDifficulty.legendary => AppColors.platinum,
      };

  String _difficultyLabel(AppLocalizations l10n) => switch (quest.difficulty) {
        QuestDifficulty.easy => l10n.difficultyEasy,
        QuestDifficulty.medium => l10n.difficultyMedium,
        QuestDifficulty.hard => l10n.difficultyHard,
        QuestDifficulty.legendary => l10n.difficultyLegendary,
      };

  IconData get _categoryIcon {
    final sc = getSuperCategoryForQuest(quest.category);
    return sc?.icon ?? LucideIcons.compass;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final canComplete = !isLocked &&
        (!quest.isCompleted ||
            (quest.isRepeatable &&
                quest.completionCount < quest.maxCompletions));
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isLegendary = quest.difficulty == QuestDifficulty.legendary;

    // Find linked skill
    final linkedSkill = getSkillById(quest.skillType);
    final superCat = getSuperCategoryForQuest(quest.category);

    Widget cardContent = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? AppColors.textMuted.withValues(alpha: 0.15)
                          : (superCat?.color ?? AppColors.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isLocked ? LucideIcons.lock : _categoryIcon,
                      color: isLocked
                          ? AppColors.textMuted
                          : (superCat?.color ?? AppColors.primary),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          RegistryL10n.questTitle(
                              locale, quest.id, quest.title),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          RegistryL10n.questDescription(
                              locale, quest.id, quest.description),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isRtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _difficultyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _difficultyLabel(l10n),
                      style: TextStyle(
                        color: _difficultyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.xpGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${quest.xpReward} XP',
                      style: const TextStyle(
                        color: AppColors.xpGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Show linked skill badge
                  if (linkedSkill != null && !isLocked) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(linkedSkill.icon,
                              style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            RegistryL10n.skillName(
                                locale, linkedSkill.id, linkedSkill.name),
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (quest.isRepeatable && !isLocked) ...[
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.repeat,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${quest.completionCount}/${quest.maxCompletions}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  if (isLocked && requirementText != null)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.lock,
                                size: 10, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                l10n.requires(requirementText!),
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (quest.isCompleted && !canComplete)
                    const Icon(LucideIcons.checkCircle,
                        size: 20, color: AppColors.success)
                  else if (!isLocked)
                    GestureDetector(
                      onTap: canComplete ? onComplete : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: canComplete
                              ? AppColors.primary
                              : AppColors.bgCardLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          quest.isCompleted ? l10n.repeat : l10n.start,
                          style: TextStyle(
                            color: canComplete
                                ? Colors.white
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );

    if (isLocked) {
      cardContent = ShimmerOverlay(child: Opacity(opacity: 0.6, child: cardContent));
    } else if (isLegendary) {
      cardContent = GlowContainer(
        glowColor: AppColors.platinum,
        borderRadius: 14,
        child: cardContent,
      );
    }

    return ScaleTap(
      onTap: onDetails,
      child: cardContent,
    );
  }
}

// ─── Quest Detail Sheet ───────────────────────────────────────────────────────

class _QuestDetailSheet extends StatelessWidget {
  final SideQuest quest;
  final bool isLocked;
  final String? requirementText;
  final VoidCallback onComplete;
  final VoidCallback onViewSkill;

  const _QuestDetailSheet({
    required this.quest,
    this.isLocked = false,
    this.requirementText,
    required this.onComplete,
    required this.onViewSkill,
  });

  String _verificationLabel(AppLocalizations l10n) =>
      switch (quest.verification) {
        VerificationMethod.photo => l10n.verificationPhoto,
        VerificationMethod.location => l10n.verificationLocation,
        VerificationMethod.timeBased => l10n.verificationTime,
        VerificationMethod.manual => l10n.verificationManual,
      };

  IconData get _verificationIcon => switch (quest.verification) {
        VerificationMethod.photo => LucideIcons.camera,
        VerificationMethod.location => LucideIcons.mapPin,
        VerificationMethod.timeBased => LucideIcons.clock,
        VerificationMethod.manual => LucideIcons.check,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final canComplete = !isLocked &&
        (!quest.isCompleted ||
            (quest.isRepeatable &&
                quest.completionCount < quest.maxCompletions));

    // Find linked skill
    final linkedSkill = getSkillById(quest.skillType);
    final superCat = getSuperCategoryForQuest(quest.category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 16),
          Row(
            children: [
              if (isLocked) ...[
                const Icon(LucideIcons.lock,
                    size: 20, color: AppColors.warning),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  RegistryL10n.questTitle(locale, quest.id, quest.title),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            RegistryL10n.questDescription(locale, quest.id, quest.description),
            style:
                const TextStyle(color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DetailPill(
                icon: LucideIcons.sparkles,
                label: '+${quest.xpReward} XP',
              ),
              _DetailPill(
                icon: _verificationIcon,
                label: _verificationLabel(l10n),
              ),
              if (superCat != null)
                _DetailPill(
                  icon: superCat.icon,
                  label: superCat.label(locale),
                ),
              if (quest.isRepeatable)
                _DetailPill(
                  icon: LucideIcons.repeat,
                  label:
                      '${quest.completionCount}/${quest.maxCompletions}',
                ),
              if (isLocked && requirementText != null)
                _DetailPill(
                  icon: LucideIcons.lock,
                  label: l10n.requires(requirementText!),
                ),
            ],
          ),
          // Linked skill section
          if (linkedSkill != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onViewSkill,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCardLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(linkedSkill.icon,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            RegistryL10n.skillName(
                                locale, linkedSkill.id, linkedSkill.name),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            locale.languageCode == 'he'
                                ? 'משפר כישור זה'
                                : 'Levels up this skill',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? LucideIcons.chevronLeft
                          : LucideIcons.chevronRight,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: isLocked
                ? ElevatedButton(
                    onPressed: null,
                    child: Text(l10n.locked),
                  )
                : ElevatedButton(
                    onPressed: canComplete ? onComplete : null,
                    child: Text(
                      quest.isCompleted
                          ? l10n.completeAgain
                          : l10n.completeQuest,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
