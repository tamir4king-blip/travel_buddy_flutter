import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/shared/providers/leaderboard_provider.dart';
import 'package:travel_buddy/shared/widgets/responsive_layout.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(leaderboardProvider);
    final notifier = ref.read(leaderboardProvider.notifier);

    final top3 = state.entries.where((e) => e.rank <= 3).toList();
    final rest = state.entries.where((e) => e.rank > 3).toList();

    return SafeArea(
      child: ResponsiveLayout(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.leaderboard,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.participants(state.totalParticipants),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _TimeChip(
                        label: l10n.weekly,
                        isSelected: state.timeRange == TimeRange.weekly,
                        onTap: () => notifier.setTimeRange(TimeRange.weekly),
                      ),
                      const SizedBox(width: 8),
                      _TimeChip(
                        label: l10n.monthly,
                        isSelected: state.timeRange == TimeRange.monthly,
                        onTap: () => notifier.setTimeRange(TimeRange.monthly),
                      ),
                      const SizedBox(width: 8),
                      _TimeChip(
                        label: l10n.allTime,
                        isSelected: state.timeRange == TimeRange.allTime,
                        onTap: () => notifier.setTimeRange(TimeRange.allTime),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (top3.length >= 3) _Podium(entries: top3),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: rest.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = rest[index];
                return _RankTile(entry: entry)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (index * 60).ms);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.3),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Sort: 2nd, 1st, 3rd for podium layout
    final first = entries.firstWhere((e) => e.rank == 1);
    final second = entries.firstWhere((e) => e.rank == 2);
    final third = entries.firstWhere((e) => e.rank == 3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumSpot(entry: second, height: 100, color: AppColors.silver)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumSpot(entry: first, height: 130, color: AppColors.gold)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumSpot(entry: third, height: 80, color: AppColors.bronze)),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }
}

class _PodiumSpot extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final Color color;

  const _PodiumSpot({required this.entry, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: entry.rank == 1 ? 28 : 22,
          backgroundColor: color.withValues(alpha: 0.3),
          child: Text(
            entry.displayName[0],
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: entry.rank == 1 ? 20 : 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(entry.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text('${entry.totalXp} XP', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(
            child: Icon(
              entry.rank == 1 ? LucideIcons.crown : LucideIcons.trophy,
              color: color,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _RankTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const _RankTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: entry.isCurrentUser
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: entry.isCurrentUser ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.bgCardLight,
            child: Text(
              entry.displayName[0],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.displayName,
              style: TextStyle(fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.w500),
            ),
          ),
          Text(
            '${entry.totalXp} XP',
            style: const TextStyle(color: AppColors.xpGreen, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
