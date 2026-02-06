import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/shared/models/side_quest.dart';
import 'package:travel_buddy/shared/models/skill_group.dart';
import 'package:travel_buddy/shared/providers/quests_provider.dart';
import 'package:travel_buddy/shared/providers/skills_provider.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  String? _activeSkillId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questsProvider);
    final notifier = ref.read(questsProvider.notifier);
    final skillsState = ref.watch(skillsProvider);

    final activeSkill = _activeSkillId == null || skillsState.allSkills.isEmpty
        ? null
        : skillsState.allSkills.firstWhere(
            (s) => s.id == _activeSkillId,
            orElse: () => skillsState.allSkills.first,
          );

    final filtered = state.filteredQuests.where((quest) {
      if (activeSkill == null) return true;
      return activeSkill.categories.contains(quest.category);
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Side Quests',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      if (_activeSkillId != null)
                        TextButton.icon(
                          onPressed: () => setState(() => _activeSkillId = null),
                          icon: const Icon(LucideIcons.x, size: 16),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.completedCount} completed  •  ${state.currentStreak} day streak',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Skills',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: skillsState.allSkills.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final skill = skillsState.allSkills[index];
                        final skillXp = state.skillXp[skill.id] ?? 0;
                        final level = _levelForSkill(skill, skillXp);
                        final progress = _progressForSkill(skill, skillXp);
                        final isActive = _activeSkillId == skill.id;
                        return _SkillCard(
                          skill: skill,
                          level: level,
                          progress: progress,
                          isActive: isActive,
                          onTap: () => setState(() => _activeSkillId = skill.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryChip(
                          label: 'All', icon: LucideIcons.layoutGrid,
                          isSelected: state.filterCategory == null,
                          onTap: () => notifier.setCategoryFilter(null),
                        ),
                        _CategoryChip(
                          label: 'Hiking', icon: LucideIcons.mountain,
                          isSelected: state.filterCategory == 'hiking',
                          onTap: () => notifier.setCategoryFilter('hiking'),
                        ),
                        _CategoryChip(
                          label: 'Food', icon: LucideIcons.utensils,
                          isSelected: state.filterCategory == 'cooking',
                          onTap: () => notifier.setCategoryFilter('cooking'),
                        ),
                        _CategoryChip(
                          label: 'Photo', icon: LucideIcons.camera,
                          isSelected: state.filterCategory == 'photography',
                          onTap: () => notifier.setCategoryFilter('photography'),
                        ),
                        _CategoryChip(
                          label: 'Culture', icon: LucideIcons.landmark,
                          isSelected: state.filterCategory == 'culture',
                          onTap: () => notifier.setCategoryFilter('culture'),
                        ),
                        _CategoryChip(
                          label: 'Water', icon: LucideIcons.waves,
                          isSelected: state.filterCategory == 'water_sports',
                          onTap: () => notifier.setCategoryFilter('water_sports'),
                        ),
                        _CategoryChip(
                          label: 'Fishing', icon: LucideIcons.fish,
                          isSelected: state.filterCategory == 'fishing',
                          onTap: () => notifier.setCategoryFilter('fishing'),
                        ),
                        _CategoryChip(
                          label: 'Camping', icon: LucideIcons.tent,
                          isSelected: state.filterCategory == 'camping',
                          onTap: () => notifier.setCategoryFilter('camping'),
                        ),
                        _CategoryChip(
                          label: 'Extreme', icon: LucideIcons.zap,
                          isSelected: state.filterCategory == 'extreme_sports',
                          onTap: () => notifier.setCategoryFilter('extreme_sports'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final quest = filtered[index];
                return _QuestCard(
                  quest: quest,
                  onComplete: () => notifier.completeQuest(quest.id),
                  onDetails: () => _showQuestDetails(context, quest, notifier),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (index * 80).ms)
                    .slideY(begin: 0.05);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
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

  void _showQuestDetails(
    BuildContext context,
    SideQuest quest,
    QuestsNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuestDetailSheet(
        quest: quest,
        onComplete: () {
          Navigator.of(context).pop();
          notifier.completeQuest(quest.id);
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
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final SideQuest quest;
  final VoidCallback onComplete;
  final VoidCallback onDetails;

  const _QuestCard({
    required this.quest,
    required this.onComplete,
    required this.onDetails,
  });

  Color get _difficultyColor => switch (quest.difficulty) {
        QuestDifficulty.easy => AppColors.success,
        QuestDifficulty.medium => AppColors.warning,
        QuestDifficulty.hard => AppColors.error,
        QuestDifficulty.legendary => AppColors.platinum,
      };

  String get _difficultyLabel => switch (quest.difficulty) {
        QuestDifficulty.easy => 'Easy',
        QuestDifficulty.medium => 'Medium',
        QuestDifficulty.hard => 'Hard',
        QuestDifficulty.legendary => 'Legendary',
      };

  IconData get _categoryIcon => switch (quest.category) {
        'hiking' => LucideIcons.mountain,
        'fishing' => LucideIcons.fish,
        'cooking' => LucideIcons.chefHat,
        'photography' => LucideIcons.camera,
        'culture' => LucideIcons.landmark,
        'water_sports' => LucideIcons.waves,
        'extreme_sports' => LucideIcons.zap,
        'camping' => LucideIcons.tent,
        _ => LucideIcons.compass,
      };

  @override
  Widget build(BuildContext context) {
    final canComplete = !quest.isCompleted ||
        (quest.isRepeatable && quest.completionCount < quest.maxCompletions);

    return GestureDetector(
      onTap: onDetails,
      child: Container(
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
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_categoryIcon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quest.description,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _difficultyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _difficultyLabel,
                    style: TextStyle(
                      color: _difficultyColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                if (quest.isRepeatable) ...[
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Icon(LucideIcons.repeat, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${quest.completionCount}/${quest.maxCompletions}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                if (quest.isCompleted && !canComplete)
                  const Icon(LucideIcons.checkCircle, size: 20, color: AppColors.success)
                else
                  GestureDetector(
                  onTap: canComplete ? onComplete : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                        color: canComplete ? AppColors.primary : AppColors.bgCardLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        quest.isCompleted ? 'Repeat' : 'Start',
                        style: TextStyle(
                          color: canComplete ? Colors.white : AppColors.textMuted,
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
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final SkillGroup skill;
  final int level;
  final double progress;
  final bool isActive;
  final VoidCallback onTap;

  const _SkillCard({
    required this.skill,
    required this.level,
    required this.progress,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        _parseColor(skill.gradientStart),
        _parseColor(skill.gradientEnd),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: isActive ? Border.all(color: Colors.white, width: 1.4) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(skill.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              skill.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              'Lv $level',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final value = hex.replaceAll('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}

class _QuestDetailSheet extends StatelessWidget {
  final SideQuest quest;
  final VoidCallback onComplete;

  const _QuestDetailSheet({
    required this.quest,
    required this.onComplete,
  });

  String get _verificationLabel => switch (quest.verification) {
        VerificationMethod.photo => 'Photo proof',
        VerificationMethod.location => 'Location check',
        VerificationMethod.timeBased => 'Time based',
        VerificationMethod.manual => 'Manual',
      };

  IconData get _verificationIcon => switch (quest.verification) {
        VerificationMethod.photo => LucideIcons.camera,
        VerificationMethod.location => LucideIcons.mapPin,
        VerificationMethod.timeBased => LucideIcons.clock,
        VerificationMethod.manual => LucideIcons.check,
      };

  @override
  Widget build(BuildContext context) {
    final canComplete = !quest.isCompleted ||
        (quest.isRepeatable && quest.completionCount < quest.maxCompletions);
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
          Text(
            quest.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            quest.description,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.3),
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
                label: _verificationLabel,
              ),
              if (quest.isRepeatable)
                _DetailPill(
                  icon: LucideIcons.repeat,
                  label: '${quest.completionCount}/${quest.maxCompletions}',
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canComplete ? onComplete : null,
              child: Text(
                quest.isCompleted ? 'Complete Again' : 'Complete Quest',
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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
