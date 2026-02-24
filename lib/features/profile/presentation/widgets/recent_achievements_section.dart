import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travel_buddy_mobile/l10n/app_localizations.dart';
import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';

class RecentAchievementsSection extends StatelessWidget {
  final List<Achievement> unlockedAchievements;

  const RecentAchievementsSection({
    super.key,
    required this.unlockedAchievements,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (unlockedAchievements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          l10n.noAchievementsYet,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Sort by unlockedAt descending, take first 5
    final sorted = [...unlockedAchievements]
      ..sort((a, b) {
        final aDate = a.unlockedAt ?? DateTime(2000);
        final bDate = b.unlockedAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
    final recent = sorted.take(5).toList();

    return Column(
      children: [
        for (int i = 0; i < recent.length; i++)
          _AchievementCard(achievement: recent[i])
              .animate(delay: (i * 60).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.05),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  Color get _tierColor => switch (achievement.tier) {
        AchievementTier.bronze => AppColors.bronze,
        AchievementTier.silver => AppColors.silver,
        AchievementTier.gold => AppColors.gold,
        AchievementTier.platinum => AppColors.platinum,
      };

  @override
  Widget build(BuildContext context) {
    final relativeDate = _formatRelativeDate(context, achievement.unlockedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _tierColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _tierColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              relativeDate,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}
