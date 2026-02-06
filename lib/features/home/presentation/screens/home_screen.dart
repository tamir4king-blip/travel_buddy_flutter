import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/shared/models/user_profile.dart';
import 'package:travel_buddy/shared/providers/achievements_provider.dart';
import 'package:travel_buddy/shared/providers/quests_provider.dart';
import 'package:travel_buddy/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy/shared/widgets/xp_progress_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final achievements = ref.watch(achievementsProvider);
    final quests = ref.watch(questsProvider);

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
                    'Welcome back,',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: 4),
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
                  const SizedBox(height: 20),

                  _XpCard(user: user),
                  const SizedBox(height: 24),

                  _QuickStatsRow(
                    achievementCount: achievements.totalUnlocked,
                    questCount: quests.completedCount,
                    streak: quests.currentStreak,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Nearby Adventures',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _AdventureCard(
                    title: 'Explore your city',
                    subtitle: '${achievements.totalAchievements - achievements.totalUnlocked} achievements to unlock',
                    icon: LucideIcons.mapPin,
                    color: AppColors.primary,
                    onTap: () => context.go('/map'),
                  ),
                  const SizedBox(height: 12),
                  _AdventureCard(
                    title: 'Daily Quest Available',
                    subtitle: 'Take a photo at a landmark',
                    icon: LucideIcons.camera,
                    color: AppColors.xpGreen,
                    onTap: () => context.go('/quests'),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Your Collections',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _CollectionCard(
                  title: 'Cities',
                  progress: _countByCollection(achievements, 'cities'),
                  total: _totalByCollection(achievements, 'cities'),
                  icon: LucideIcons.building2,
                  color: AppColors.primary,
                  onTap: () => context.go('/achievements'),
                ),
                _CollectionCard(
                  title: 'Nature',
                  progress: _countByCollection(achievements, 'nature'),
                  total: _totalByCollection(achievements, 'nature'),
                  icon: LucideIcons.trees,
                  color: AppColors.xpGreen,
                  onTap: () => context.go('/achievements'),
                ),
                _CollectionCard(
                  title: 'Food & Drink',
                  progress: _countByCollection(achievements, 'food-drink'),
                  total: _totalByCollection(achievements, 'food-drink'),
                  icon: LucideIcons.utensils,
                  color: AppColors.warning,
                  onTap: () => context.go('/achievements'),
                ),
                _CollectionCard(
                  title: 'Culture',
                  progress: _countByCollection(achievements, 'culture'),
                  total: _totalByCollection(achievements, 'culture'),
                  icon: LucideIcons.landmark,
                  color: AppColors.error,
                  onTap: () => context.go('/achievements'),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  int _countByCollection(AchievementsState state, String collectionId) {
    return state.unlockedAchievements
        .where((a) => a.collectionId == collectionId)
        .length;
  }

  int _totalByCollection(AchievementsState state, String collectionId) {
    final count = state.allAchievements
        .where((a) => a.collectionId == collectionId)
        .length;
    return count > 0 ? count : 1; // Avoid division by zero
  }
}

class _XpCard extends StatelessWidget {
  final UserProfile user;

  const _XpCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final xpInLevel = user.totalXp % 200;
    final xpNeeded = 200 - xpInLevel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${user.level}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${user.totalXp} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          XpProgressBar(current: xpInLevel, max: 200),
          const SizedBox(height: 8),
          Text(
            '$xpNeeded XP to next level',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _QuickStatsRow extends StatelessWidget {
  final int achievementCount;
  final int questCount;
  final int streak;

  const _QuickStatsRow({
    required this.achievementCount,
    required this.questCount,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(label: 'Achievements', value: '$achievementCount', icon: LucideIcons.award)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(label: 'Quests', value: '$questCount', icon: LucideIcons.compass)
              .animate(delay: 100.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(label: 'Streak', value: '${streak}d', icon: LucideIcons.flame)
              .animate(delay: 200.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AdventureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _AdventureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }
}

class _CollectionCard extends StatelessWidget {
  final String title;
  final int progress;
  final int total;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CollectionCard({
    required this.title,
    required this.progress,
    required this.total,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / total,
                    backgroundColor: AppColors.bgCardLight,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$progress / $total',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
