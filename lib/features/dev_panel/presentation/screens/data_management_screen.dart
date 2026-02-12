import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/shared/providers/achievements_provider.dart';
import 'package:travel_buddy/shared/providers/persistence_provider.dart';
import 'package:travel_buddy/shared/providers/quests_provider.dart';
import 'package:travel_buddy/shared/providers/user_profile_provider.dart';

class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final achievements = ref.watch(achievementsProvider);
    final quests = ref.watch(questsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Management',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // State summary
          _Card(
            title: 'State Summary',
            icon: LucideIcons.barChart3,
            child: Column(
              children: [
                _InfoRow('Level', '${user.level}'),
                _InfoRow('Total XP', '${user.totalXp}'),
                _InfoRow('Achievements',
                    '${achievements.totalUnlocked}/${achievements.totalAchievements}'),
                _InfoRow('Quests',
                    '${quests.completedCount}/${quests.allQuests.length}'),
                _InfoRow('Streak', '${quests.currentStreak} days'),
                _InfoRow(
                    'Collections', '${achievements.completedCollections.length}'),
                _InfoRow('Skill types', '${quests.skillXp.length}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Clear categories
          _Card(
            title: 'Clear Data by Category',
            icon: LucideIcons.trash2,
            child: Column(
              children: [
                _ClearButton(
                  label: 'Clear Achievements',
                  onPressed: () async {
                    final persistence = ref.read(persistenceServiceProvider);
                    await persistence.saveUnlockedAchievements([]);
                    await persistence.saveCompletedCollections({});
                    // Force reload by locking all
                    ref.read(achievementsProvider.notifier).lockAll();
                  },
                ),
                _ClearButton(
                  label: 'Clear Quests',
                  onPressed: () async {
                    final persistence = ref.read(persistenceServiceProvider);
                    await persistence.saveCompletedQuests({});
                    await persistence.saveSkillXp({});
                    await persistence.saveStreakData(0, null);
                    ref.read(questsProvider.notifier).resetAllQuests();
                  },
                ),
                _ClearButton(
                  label: 'Clear Quest Photos',
                  onPressed: () async {
                    final persistence = ref.read(persistenceServiceProvider);
                    await persistence.saveQuestPhotos({});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Danger zone
          _Card(
            title: 'Danger Zone',
            icon: LucideIcons.alertTriangle,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear ALL Data?'),
                          content: const Text(
                              'This will permanently delete all app data including profile, achievements, quests, and preferences. This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final persistence =
                                    ref.read(persistenceServiceProvider);
                                await persistence.clearAll();
                                ref
                                    .read(achievementsProvider.notifier)
                                    .lockAll();
                                ref
                                    .read(questsProvider.notifier)
                                    .resetAllQuests();
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Text('Delete Everything',
                                  style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('Clear All Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Card({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ClearButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}
