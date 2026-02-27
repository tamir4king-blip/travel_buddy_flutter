import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/providers/achievements_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/quests_provider.dart';
import 'package:travel_buddy_mobile/shared/widgets/directional_icon.dart';
import 'package:travel_buddy_mobile/shared/widgets/visual_extras.dart';

class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final quests = ref.watch(questsProvider);
    final achievements = ref.watch(achievementsProvider);

    final completedQuests = quests.completedCount;
    final totalQuests = quests.allQuests.length;
    final streak = quests.currentStreak;

    final activeSkills = quests.skillLevels.values.where((lv) => lv > 0).length;
    final totalXp = quests.skillXp.values.fold<int>(0, (sum, xp) => sum + xp);

    final unlocked = achievements.totalUnlocked;
    final total = achievements.totalAchievements;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.activityLog,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quests card
                  _LogCard(
                    title: l10n.navQuests,
                    subtitle: '$completedQuests completed \u00b7 ${streak}d streak',
                    icon: LucideIcons.compass,
                    color: AppColors.accent,
                    progress: totalQuests > 0 ? completedQuests / totalQuests : 0,
                    onTap: () => context.go('/quests'),
                  ),
                  const SizedBox(height: 14),

                  // Skills card
                  _LogCard(
                    title: l10n.navSkills,
                    subtitle: '$activeSkills active \u00b7 $totalXp XP',
                    icon: LucideIcons.sparkles,
                    color: AppColors.purple,
                    progress: activeSkills / 44,
                    onTap: () => context.go('/skills'),
                  ),
                  const SizedBox(height: 14),

                  // Achievements card
                  _LogCard(
                    title: l10n.navAchievements,
                    subtitle: '$unlocked of $total unlocked',
                    icon: LucideIcons.award,
                    color: AppColors.primary,
                    progress: total > 0 ? unlocked / total : 0,
                    onTap: () => context.go('/achievements'),
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

class _LogCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double progress;
  final VoidCallback? onTap;

  const _LogCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
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
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: color.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
