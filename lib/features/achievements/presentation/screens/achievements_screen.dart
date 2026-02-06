import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/shared/models/achievement.dart';
import 'package:travel_buddy/shared/providers/achievements_provider.dart';
import 'package:travel_buddy/features/achievements/presentation/widgets/retroactive_claim_modal.dart';
import 'package:travel_buddy/features/achievements/presentation/widgets/master_achievements_section.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static const _collections = <_CollectionFilter>[
    _CollectionFilter(id: null, label: 'All', color: AppColors.primary),
    _CollectionFilter(id: 'cities', label: 'Cities', color: AppColors.primary),
    _CollectionFilter(id: 'nature', label: 'Nature', color: AppColors.xpGreen),
    _CollectionFilter(id: 'food-drink', label: 'Food & Drink', color: AppColors.warning),
    _CollectionFilter(id: 'culture', label: 'Culture', color: AppColors.error),
    _CollectionFilter(id: 'photography', label: 'Photo', color: AppColors.info),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsProvider);
    final notifier = ref.read(achievementsProvider.notifier);
    final filtered = state.filteredAchievements;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.totalUnlocked} of ${state.totalAchievements} unlocked',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    children: [
                      _TierChip(
                        label: 'All',
                        color: AppColors.primary,
                        isSelected: state.filterTier == null,
                        onTap: () => notifier.setTierFilter(null),
                      ),
                      _TierChip(
                        label: 'Bronze',
                        color: AppColors.bronze,
                        isSelected: state.filterTier == AchievementTier.bronze,
                        onTap: () => notifier.setTierFilter(AchievementTier.bronze),
                      ),
                      _TierChip(
                        label: 'Silver',
                        color: AppColors.silver,
                        isSelected: state.filterTier == AchievementTier.silver,
                        onTap: () => notifier.setTierFilter(AchievementTier.silver),
                      ),
                      _TierChip(
                        label: 'Gold',
                        color: AppColors.gold,
                        isSelected: state.filterTier == AchievementTier.gold,
                        onTap: () => notifier.setTierFilter(AchievementTier.gold),
                      ),
                      _TierChip(
                        label: 'Platinum',
                        color: AppColors.platinum,
                        isSelected: state.filterTier == AchievementTier.platinum,
                        onTap: () => notifier.setTierFilter(AchievementTier.platinum),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _collections.map((collection) {
                        final isSelected = state.filterCollection == collection.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _CollectionChip(
                            label: collection.label,
                            color: collection.color,
                            isSelected: isSelected,
                            onTap: () => notifier.setCollectionFilter(collection.id),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search
                  TextField(
                    onChanged: notifier.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search achievements...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      filled: true,
                      fillColor: AppColors.bgCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Master Achievements Section
          const SliverToBoxAdapter(
            child: MasterAchievementsSection(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
          // Regular Achievements Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(LucideIcons.trophy, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Regular Achievements',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 12),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final achievement = filtered[index];
                return _AchievementTile(
                  achievement: achievement,
                  onClaim: () async {
                    final result = await RetroactiveClaimModal.show(
                      context,
                      achievement,
                    );
                    // result is null for quick claim, RetroactiveClaimData for retroactive
                    if (result == null) {
                      // Quick claim (no retroactive data)
                      notifier.claimAchievement(achievement.id);
                    } else {
                      // Retroactive claim with date/notes/photos
                      notifier.claimAchievement(
                        achievement.id,
                        retroactiveData: result,
                      );
                    }
                  },
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (index * 60).ms)
                    .slideX(begin: 0.05);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TierChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onClaim;

  const _AchievementTile({required this.achievement, required this.onClaim});

  Color get _tierColor => switch (achievement.tier) {
        AchievementTier.bronze => AppColors.bronze,
        AchievementTier.silver => AppColors.silver,
        AchievementTier.gold => AppColors.gold,
        AchievementTier.platinum => AppColors.platinum,
      };

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: achievement.isUnlocked ? null : onClaim,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: achievement.isUnlocked
              ? Border.all(color: _tierColor.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked
                        ? _tierColor.withValues(alpha: 0.2)
                        : AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    achievement.isUnlocked ? LucideIcons.trophy : LucideIcons.lock,
                    color: achievement.isUnlocked ? _tierColor : AppColors.textMuted,
                    size: 22,
                  ),
                ),
                // Retroactive indicator
                if (achievement.isUnlocked && achievement.isRetroactive)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: achievement.isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  // Show visit date for retroactive claims
                  if (achievement.isUnlocked && achievement.visitDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            achievement.isRetroactive
                                ? LucideIcons.clock
                                : LucideIcons.calendarCheck,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(achievement.visitDate),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          if (achievement.notes != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              LucideIcons.messageSquare,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ],
                          if (achievement.photos.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(
                              LucideIcons.image,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${achievement.photos.length}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (!achievement.isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Claim',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _tierColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${achievement.xpReward} XP',
                  style: TextStyle(
                    color: _tierColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CollectionFilter {
  final String? id;
  final String label;
  final Color color;

  const _CollectionFilter({
    required this.id,
    required this.label,
    required this.color,
  });
}

class _CollectionChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CollectionChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.3),
    );
  }
}
