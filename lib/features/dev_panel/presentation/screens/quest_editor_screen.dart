import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/shared/providers/quests_provider.dart';

class QuestEditorScreen extends ConsumerStatefulWidget {
  const QuestEditorScreen({super.key});

  @override
  ConsumerState<QuestEditorScreen> createState() => _QuestEditorScreenState();
}

class _QuestEditorScreenState extends ConsumerState<QuestEditorScreen> {
  String _search = '';
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final quests = ref.watch(questsProvider);
    final filtered = quests.allQuests.where((q) {
      if (_search.isEmpty) return true;
      final query = _search.toLowerCase();
      return q.title.toLowerCase().contains(query) ||
          q.category.toLowerCase().contains(query) ||
          q.id.toLowerCase().contains(query);
    }).toList();

    // Group by category
    final categories = <String, List<int>>{};
    for (var i = 0; i < filtered.length; i++) {
      categories.putIfAbsent(filtered[i].category, () => []).add(i);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest Editor',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset All Quests?'),
                  content: const Text(
                      'This will reset all quest completions, skill XP, and streak data.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(questsProvider.notifier).resetAllQuests();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Reset All',
                style: TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search quests...',
                prefixIcon: Icon(LucideIcons.search, size: 18),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${quests.completedCount}/${quests.allQuests.length} completed  •  Streak: ${quests.currentStreak}',
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: categories.entries.map((entry) {
                final cat = entry.key;
                final indices = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 6),
                      child: Text(
                        cat.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...indices.map((i) {
                      final q = filtered[i];
                      final isExpanded = _expandedId == q.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: q.isCompleted
                              ? Border.all(
                                  color: AppColors.success
                                      .withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() {
                                _expandedId = isExpanded ? null : q.id;
                              }),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      q.isCompleted
                                          ? LucideIcons.checkCircle
                                          : LucideIcons.circle,
                                      size: 16,
                                      color: q.isCompleted
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(q.title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                          Text(
                                            '${q.difficulty.name} • ${q.xpReward} XP • ${q.skillType}',
                                            style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'x${q.completionCount}',
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      isExpanded
                                          ? LucideIcons.chevronUp
                                          : LucideIcons.chevronDown,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Divider(
                                        height: 1,
                                        color: AppColors.bgCardLight),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ID: ${q.id}\nRepeatable: ${q.isRepeatable ? "Yes (max ${q.maxCompletions})" : "No"}\nSkill: ${q.skillType}',
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: q.isCompleted
                                                ? null
                                                : () => ref
                                                    .read(questsProvider
                                                        .notifier)
                                                    .forceCompleteQuest(
                                                        q.id),
                                            icon: const Icon(
                                                LucideIcons.checkCircle,
                                                size: 14),
                                            label: const Text(
                                                'Force Complete',
                                                style: TextStyle(
                                                    fontSize: 12)),
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.success,
                                              disabledBackgroundColor:
                                                  AppColors.bgCardLight,
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      vertical: 8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: q.isCompleted
                                                ? () => ref
                                                    .read(questsProvider
                                                        .notifier)
                                                    .uncompleteQuest(q.id)
                                                : null,
                                            icon: const Icon(
                                                LucideIcons.undo,
                                                size: 14),
                                            label: const Text(
                                                'Uncomplete',
                                                style: TextStyle(
                                                    fontSize: 12)),
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.error,
                                              disabledBackgroundColor:
                                                  AppColors.bgCardLight,
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      vertical: 8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
