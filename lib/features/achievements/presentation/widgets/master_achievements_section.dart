import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/shared/models/master_achievement.dart';
import 'package:travel_buddy/shared/providers/master_achievements_provider.dart';

class MasterAchievementsSection extends ConsumerWidget {
  const MasterAchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(masterAchievementsProvider);
    final notifier = ref.read(masterAchievementsProvider.notifier);
    final filtered = state.filteredMasterAchievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.3),
                      AppColors.warning.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.crown,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Master Achievements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${state.totalUnlocked} of ${state.totalMasterAchievements} mastered',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05),

        const SizedBox(height: 16),

        // Tier filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _MasterTierChip(
                label: 'All',
                color: AppColors.primary,
                isSelected: state.filterTier == null,
                onTap: () => notifier.setTierFilter(null),
              ),
              const SizedBox(width: 8),
              _MasterTierChip(
                label: 'Elite',
                color: _tierColor(MasterTier.elite),
                icon: '💎',
                isSelected: state.filterTier == MasterTier.elite,
                onTap: () => notifier.setTierFilter(MasterTier.elite),
              ),
              const SizedBox(width: 8),
              _MasterTierChip(
                label: 'Legendary',
                color: _tierColor(MasterTier.legendary),
                icon: '🏅',
                isSelected: state.filterTier == MasterTier.legendary,
                onTap: () => notifier.setTierFilter(MasterTier.legendary),
              ),
              const SizedBox(width: 8),
              _MasterTierChip(
                label: 'Mythic',
                color: _tierColor(MasterTier.mythic),
                icon: '👑',
                isSelected: state.filterTier == MasterTier.mythic,
                onTap: () => notifier.setTierFilter(MasterTier.mythic),
              ),
            ],
          ),
        ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

        const SizedBox(height: 16),

        // Master achievements list
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final master = filtered[index];
              return _MasterAchievementCard(
                masterAchievement: master,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  static Color _tierColor(MasterTier tier) {
    return switch (tier) {
      MasterTier.elite => const Color(0xFF3B82F6),
      MasterTier.legendary => const Color(0xFFF59E0B),
      MasterTier.mythic => const Color(0xFFA855F7),
    };
  }
}

class _MasterTierChip extends StatelessWidget {
  final String label;
  final Color color;
  final String? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MasterTierChip({
    required this.label,
    required this.color,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterAchievementCard extends StatelessWidget {
  final MasterAchievement masterAchievement;
  final int index;

  const _MasterAchievementCard({
    required this.masterAchievement,
    required this.index,
  });

  Color get _tierColor => switch (masterAchievement.tier) {
        MasterTier.elite => const Color(0xFF3B82F6),
        MasterTier.legendary => const Color(0xFFF59E0B),
        MasterTier.mythic => const Color(0xFFA855F7),
      };

  String get _tierLabel => switch (masterAchievement.tier) {
        MasterTier.elite => 'ELITE',
        MasterTier.legendary => 'LEGENDARY',
        MasterTier.mythic => 'MYTHIC',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: masterAchievement.isUnlocked
            ? Border.all(color: _tierColor.withValues(alpha: 0.6), width: 2)
            : null,
        boxShadow: masterAchievement.isUnlocked
            ? [
                BoxShadow(
                  color: _tierColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and tier
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: masterAchievement.isUnlocked
                      ? _tierColor.withValues(alpha: 0.2)
                      : AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    masterAchievement.icon,
                    style: TextStyle(
                      fontSize: 22,
                      color: masterAchievement.isUnlocked
                          ? null
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _tierColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _tierLabel,
                  style: TextStyle(
                    color: _tierColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            masterAchievement.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: masterAchievement.isUnlocked
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Description
          Text(
            masterAchievement.description,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Progress or XP
          if (!masterAchievement.isUnlocked) ...[
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: masterAchievement.progress,
                backgroundColor: AppColors.bgCardLight,
                valueColor: AlwaysStoppedAnimation(_tierColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(masterAchievement.progress * 100).round()}% complete',
              style: TextStyle(
                color: _tierColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            // Unlocked badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 12,
                    color: _tierColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${masterAchievement.xpReward} XP',
                    style: TextStyle(
                      color: _tierColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: (index * 80).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }
}
