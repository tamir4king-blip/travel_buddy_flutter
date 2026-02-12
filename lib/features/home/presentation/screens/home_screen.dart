import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/shared/models/user_profile.dart';
import 'package:travel_buddy/shared/providers/achievements_provider.dart';
import 'package:travel_buddy/shared/providers/quests_provider.dart';
import 'package:travel_buddy/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy/shared/widgets/directional_icon.dart';
import 'package:travel_buddy/shared/widgets/xp_progress_bar.dart';
import 'package:travel_buddy/shared/widgets/responsive_layout.dart';
import 'package:travel_buddy/shared/widgets/visual_extras.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userProfileProvider);
    final achievements = ref.watch(achievementsProvider);
    final quests = ref.watch(questsProvider);

    final gridCols = ResponsiveLayout.gridColumns(context, mobile: 2, tablet: 3, desktop: 4);
    final isComplete = achievements.completedCollections;

    return SafeArea(
      child: ResponsiveLayout(
        child: AnimatedBackground(
          accentColor: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GradientText(
                        text: l10n.welcomeBack,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        gradient: AppGradients.gradientWarm,
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                      const SizedBox(height: 4),
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
                      const SizedBox(height: 22),

                      _XpCard(user: user),
                      const SizedBox(height: 24),

                      _QuickStatsRow(
                        achievementCount: achievements.totalUnlocked,
                        questCount: quests.completedCount,
                        streak: quests.currentStreak,
                      ),
                      const SizedBox(height: 28),

                      Text(
                        l10n.nearbyAdventures,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _AdventureCard(
                        title: l10n.exploreYourCity,
                        subtitle: l10n.achievementsToUnlock(achievements.totalAchievements - achievements.totalUnlocked),
                        icon: LucideIcons.mapPin,
                        color: AppColors.primary,
                        onTap: () => context.go('/map'),
                      ),
                      const SizedBox(height: 12),
                      _AdventureCard(
                        title: l10n.dailyQuestAvailable,
                        subtitle: l10n.takePhotoAtLandmark,
                        icon: LucideIcons.camera,
                        color: AppColors.accent,
                        onTap: () => context.go('/quests'),
                      ),
                      const SizedBox(height: 28),

                      Text(
                        l10n.yourCollections,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.count(
                  crossAxisCount: gridCols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _CollectionCard(
                      title: l10n.collectionBeaches,
                      emoji: '\u{1F3D6}',
                      progress: _countByCollection(achievements, 'beaches'),
                      total: _totalByCollection(achievements, 'beaches'),
                      icon: LucideIcons.waves,
                      color: const Color(0xFF38BDF8),
                      isComplete: isComplete.contains('beaches'),
                      onTap: () => context.go('/achievements'),
                    ),
                    _CollectionCard(
                      title: l10n.collectionLandmarks,
                      emoji: '\u{1F3DB}',
                      progress: _countByCollection(achievements, 'landmarks'),
                      total: _totalByCollection(achievements, 'landmarks'),
                      icon: LucideIcons.landmark,
                      color: AppColors.accent,
                      isComplete: isComplete.contains('landmarks'),
                      onTap: () => context.go('/achievements'),
                    ),
                    _CollectionCard(
                      title: l10n.collectionParks,
                      emoji: '\u{1F33F}',
                      progress: _countByCollection(achievements, 'parks'),
                      total: _totalByCollection(achievements, 'parks'),
                      icon: LucideIcons.trees,
                      color: AppColors.xpGreen,
                      isComplete: isComplete.contains('parks'),
                      onTap: () => context.go('/achievements'),
                    ),
                    _CollectionCard(
                      title: l10n.collectionCulture,
                      emoji: '\u{1F3AD}',
                      progress: _countByCollection(achievements, 'culture'),
                      total: _totalByCollection(achievements, 'culture'),
                      icon: LucideIcons.palette,
                      color: AppColors.error,
                      isComplete: isComplete.contains('culture'),
                      onTap: () => context.go('/achievements'),
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
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
    return count > 0 ? count : 1;
  }
}

class _XpCard extends StatelessWidget {
  final UserProfile user;

  const _XpCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final xpInLevel = user.totalXp % 200;
    final xpNeeded = 200 - xpInLevel;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F766E),  // teal-700
            Color(0xFF0D9488),  // teal-600
            Color(0xFF115E59),  // teal-800
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.levelN(user.level),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.zap, size: 14, color: AppColors.xpGlow),
                    const SizedBox(width: 4),
                    AnimatedCounter(
                      value: user.totalXp,
                      suffix: ' XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          XpProgressBar(current: xpInLevel, max: 200),
          const SizedBox(height: 10),
          Text(
            l10n.xpToNextLevel(xpNeeded),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: ScaleTap(
            child: _StatChip(
              label: l10n.achievements,
              value: achievementCount,
              icon: LucideIcons.award,
              color: AppColors.primary,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ScaleTap(
            child: _StatChip(
              label: l10n.quests,
              value: questCount,
              icon: LucideIcons.compass,
              color: AppColors.accent,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ScaleTap(
            child: _StatChip(
              label: l10n.streak,
              value: streak,
              displayValue: l10n.streakDays(streak),
              icon: LucideIcons.flame,
              color: AppColors.error,
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final String? displayValue;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    this.displayValue,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          if (displayValue != null)
            Text(
              displayValue!,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            )
          else
            AnimatedCounter(
              value: value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
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
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.10),
              AppColors.bgCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: color.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            DirectionalChevron(color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }
}

class _CollectionCard extends StatelessWidget {
  final String title;
  final String emoji;
  final int progress;
  final int total;
  final IconData icon;
  final Color color;
  final bool isComplete;
  final VoidCallback? onTap;

  const _CollectionCard({
    required this.title,
    required this.emoji,
    required this.progress,
    required this.total,
    required this.icon,
    required this.color,
    this.isComplete = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.06),
            AppColors.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isComplete
              ? color.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.1),
          width: isComplete ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              if (isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    l10n.complete,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / total,
                  backgroundColor: AppColors.bgCardLight.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$progress / $total',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );

    // Pulsing glow on incomplete collections
    if (!isComplete && progress > 0) {
      card = GlowContainer(
        glowColor: color,
        borderRadius: 18,
        child: card,
      );
    }

    return ScaleTap(
      onTap: onTap,
      child: card,
    );
  }
}
