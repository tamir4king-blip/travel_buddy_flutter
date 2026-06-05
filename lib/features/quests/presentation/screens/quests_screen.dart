import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/models/quest.dart';
import 'package:travel_buddy_mobile/shared/providers/quest_chain_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

enum _QuestTab { active, claim, available, completed }

class _QuestsScreenState extends ConsumerState<QuestsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  _QuestTab _tab = _QuestTab.active;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final chainState = ref.watch(questChainProvider);

    final active = chainState.activeQuests;
    final claimable = chainState.claimableQuests;
    final available = chainState.availableQuests;
    final completed = chainState.completedQuests;

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.primary,
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText(
                      text: l10n.quests,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      gradient: AppGradients.gradientPrimary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${active.length} active  •  ${completed.length} completed',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ── Tabs ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _QuestTabs(
                  selected: _tab,
                  activeCount: active.length,
                  claimCount: claimable.length,
                  availableCount: available.length,
                  completedCount: completed.length,
                  onChanged: (t) => setState(() => _tab = t),
                ),
              ),
              const SizedBox(height: 12),
              // ── Content ──
              Expanded(
                child: _buildTabContent(active, claimable, available, completed),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    List<Quest> active,
    List<Quest> claimable,
    List<Quest> available,
    List<Quest> completed,
  ) {
    final quests = switch (_tab) {
      _QuestTab.active => active,
      _QuestTab.claim => claimable,
      _QuestTab.available => available,
      _QuestTab.completed => completed,
    };

    if (quests.isEmpty) {
      return _buildEmpty();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: quests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final quest = quests[index];
        return _QuestChainCard(
          quest: quest,
          onTap: () => _showQuestDetail(quest),
        )
            .animate()
            .fadeIn(duration: 350.ms, delay: (index * 70).ms)
            .slideY(begin: 0.04);
      },
    );
  }

  Widget _buildEmpty() {
    final msg = switch (_tab) {
      _QuestTab.active => 'No active quests.\nStart one from the Available tab!',
      _QuestTab.claim => 'No quests ready to claim.\nComplete an active quest first!',
      _QuestTab.available => 'No quests available right now.',
      _QuestTab.completed => 'No completed quests yet.\nStart your first quest!',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.scroll, size: 48,
                color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestDetail(Quest quest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuestDetailSheet(
        quest: quest,
        onStart: () {
          ref.read(questChainProvider.notifier).startQuest(quest.id);
          Navigator.of(context).pop();
          setState(() => _tab = _QuestTab.active);
        },
        onAbandon: () {
          ref.read(questChainProvider.notifier).abandonQuest(quest.id);
          Navigator.of(context).pop();
        },
        onClaim: () {
          ref.read(questChainProvider.notifier).claimQuest(quest.id);
          Navigator.of(context).pop();
          setState(() => _tab = _QuestTab.completed);
        },
      ),
    );
  }
}

// ─── Tab bar ─────────────────────────────────────────────────────────────────

class _QuestTabs extends StatelessWidget {
  final _QuestTab selected;
  final int activeCount;
  final int claimCount;
  final int availableCount;
  final int completedCount;
  final ValueChanged<_QuestTab> onChanged;

  const _QuestTabs({
    required this.selected,
    required this.activeCount,
    required this.claimCount,
    required this.availableCount,
    required this.completedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tab('Active', activeCount, _QuestTab.active),
          _tab('Claim', claimCount, _QuestTab.claim, highlight: claimCount > 0),
          _tab('Available', availableCount, _QuestTab.available),
          _tab('Done', completedCount, _QuestTab.completed),
        ],
      ),
    );
  }

  Widget _tab(String label, int count, _QuestTab tab, {bool highlight = false}) {
    final isSelected = selected == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: highlight && !isSelected
                      ? AppColors.gold
                      : isSelected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: highlight
                        ? AppColors.gold.withValues(alpha: 0.2)
                        : isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.bgCardLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: highlight
                          ? AppColors.gold
                          : isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quest chain card ────────────────────────────────────────────────────────

class _QuestChainCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onTap;

  const _QuestChainCard({required this.quest, required this.onTap});

  static Color _rarityColor(QuestRarity r) => switch (r) {
        QuestRarity.common => const Color(0xFF6B7280),
        QuestRarity.rare => const Color(0xFF3B82F6),
        QuestRarity.epic => const Color(0xFF8B5CF6),
        QuestRarity.legendary => const Color(0xFFF59E0B),
      };

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(quest.rarity);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    Widget card = ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: quest.isClaimed
                ? AppColors.success.withValues(alpha: 0.3)
                : quest.isClaimable
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + title + rarity
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(quest.icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quest.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 14),
            // Progress row
            Row(
              children: [
                // Rarity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    quest.rarity.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // XP badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.xpGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${quest.xpReward} XP',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.xpGreen,
                    ),
                  ),
                ),
                const Spacer(),
                // Step counter
                Text(
                  '${quest.completedStepCount}/${quest.totalSteps}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: quest.isClaimed
                        ? AppColors.success
                        : quest.isClaimable
                            ? AppColors.gold
                            : color,
                  ),
                ),
                if (quest.isClaimed) ...[
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.success),
                ] else if (quest.isClaimable) ...[
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.gift, size: 16, color: AppColors.gold),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Step progress dots
            _StepProgressDots(
              total: quest.totalSteps,
              completed: quest.completedStepCount,
              color: quest.isClaimed
                  ? AppColors.success
                  : quest.isClaimable
                      ? AppColors.gold
                      : color,
            ),
          ],
        ),
      ),
    );

    if (quest.rarity == QuestRarity.legendary) {
      card = GlowContainer(
        glowColor: color,
        borderRadius: 16,
        child: card,
      );
    }

    return card;
  }
}

// ─── Step progress dots ──────────────────────────────────────────────────────

class _StepProgressDots extends StatelessWidget {
  final int total;
  final int completed;
  final Color color;

  const _StepProgressDots({
    required this.total,
    required this.completed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final done = i < completed;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: done ? color : AppColors.bgCardLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Quest detail sheet ──────────────────────────────────────────────────────

class _QuestDetailSheet extends StatelessWidget {
  final Quest quest;
  final VoidCallback onStart;
  final VoidCallback onAbandon;
  final VoidCallback onClaim;

  const _QuestDetailSheet({
    required this.quest,
    required this.onStart,
    required this.onAbandon,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final color = _QuestChainCard._rarityColor(quest.rarity);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              // Icon + title
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(quest.icon, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                quest.rarity.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${quest.xpReward} XP',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.xpGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                quest.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // Progress bar
              _StepProgressDots(
                total: quest.totalSteps,
                completed: quest.completedStepCount,
                color: quest.isClaimed
                    ? AppColors.success
                    : quest.isClaimable
                        ? AppColors.gold
                        : color,
              ),
              const SizedBox(height: 6),
              Text(
                '${quest.completedStepCount} of ${quest.totalSteps} steps completed',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              // ── Steps list ──
              const Text(
                'Steps',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(quest.steps.length, (i) {
                final step = quest.steps[i];
                final isActive = !step.isCompleted &&
                    (i == 0 || quest.steps[i - 1].isCompleted);
                return _StepTile(
                  step: step,
                  index: i,
                  isActive: isActive,
                  isLast: i == quest.steps.length - 1,
                  color: color,
                );
              }),
              const SizedBox(height: 24),
              // ── Action button ──
              if (!quest.isStarted && !quest.isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: const Text('Start Quest'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              if (quest.isStarted && !quest.isCompleted) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAbandon,
                    icon: Icon(LucideIcons.x, size: 16, color: AppColors.error),
                    label: Text('Abandon Quest',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
              // Ready to claim — show claim button
              if (quest.isClaimable)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onClaim,
                    icon: const Icon(LucideIcons.gift, size: 18),
                    label: Text('Claim +${quest.xpReward} XP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              // Already claimed
              if (quest.isClaimed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.checkCircle2, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'Completed!',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Step tile ───────────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  final QuestStep step;
  final int index;
  final bool isActive;
  final bool isLast;
  final Color color;

  const _StepTile({
    required this.step,
    required this.index,
    required this.isActive,
    required this.isLast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Circle indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCompleted
                        ? AppColors.success
                        : isActive
                            ? color
                            : AppColors.bgCardLight,
                    border: Border.all(
                      color: step.isCompleted
                          ? AppColors.success
                          : isActive
                              ? color
                              : AppColors.bgCardLight.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: step.isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                  ),
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.isCompleted
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.bgCardLight.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        step.type == QuestStepType.activity
                            ? LucideIcons.compass
                            : LucideIcons.trophy,
                        size: 14,
                        color: step.isCompleted
                            ? AppColors.success
                            : isActive
                                ? color
                                : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: step.isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration: step.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (step.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (step.type == QuestStepType.activity
                              ? AppColors.primary
                              : AppColors.gold)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      step.type == QuestStepType.activity ? 'Activity' : 'Achievement',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: step.type == QuestStepType.activity
                            ? AppColors.primary
                            : AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
