import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy/shared/models/side_quest.dart';
import 'package:travel_buddy/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy/shared/data/quest_registry.dart';

class QuestsState {
  final List<SideQuest> allQuests;
  final String? filterCategory;
  final QuestDifficulty? filterDifficulty;
  final Map<String, int> skillXp; // skillType -> xp
  final Map<String, int> skillLevels; // skillType -> level
  final int currentStreak;
  final DateTime? lastCompletionDate;

  const QuestsState({
    this.allQuests = const [],
    this.filterCategory,
    this.filterDifficulty,
    this.skillXp = const {},
    this.skillLevels = const {},
    this.currentStreak = 0,
    this.lastCompletionDate,
  });

  List<SideQuest> get filteredQuests {
    var list = allQuests;
    if (filterCategory != null) {
      list = list.where((q) => q.category == filterCategory).toList();
    }
    if (filterDifficulty != null) {
      list = list.where((q) => q.difficulty == filterDifficulty).toList();
    }
    return list;
  }

  int get completedCount => allQuests.where((q) => q.isCompleted).length;

  QuestsState copyWith({
    List<SideQuest>? allQuests,
    String? filterCategory,
    QuestDifficulty? filterDifficulty,
    Map<String, int>? skillXp,
    Map<String, int>? skillLevels,
    int? currentStreak,
    DateTime? lastCompletionDate,
    bool clearCategoryFilter = false,
    bool clearDifficultyFilter = false,
  }) {
    return QuestsState(
      allQuests: allQuests ?? this.allQuests,
      filterCategory:
          clearCategoryFilter ? null : (filterCategory ?? this.filterCategory),
      filterDifficulty: clearDifficultyFilter
          ? null
          : (filterDifficulty ?? this.filterDifficulty),
      skillXp: skillXp ?? this.skillXp,
      skillLevels: skillLevels ?? this.skillLevels,
      currentStreak: currentStreak ?? this.currentStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
    );
  }
}

class QuestsNotifier extends StateNotifier<QuestsState> {
  final Ref ref;

  QuestsNotifier(this.ref) : super(const QuestsState()) {
    _loadQuests();
  }

  void _loadQuests() {
    state = QuestsState(
      allQuests: questRegistry,
      skillXp: const {
        // Outdoor & Nature
        'hiker': 620,
        'camper': 180,
        'angler': 240,
        'naturalist': 150,
        'stargazer': 80,
        'gardener': 50,
        // Water Sports
        'diver': 320,
        'surfer': 180,
        'sailor': 100,
        'kayaker': 220,
        'swimmer': 150,
        // Extreme & Adrenaline
        'skydiver': 50,
        'climber': 180,
        'skier': 240,
        'snowboarder': 120,
        'paraglider': 80,
        // Sports & Fitness
        'runner': 200,
        'biker': 180,
        'yogi': 320,
        'martial': 100,
        // Food & Drink
        'chef': 290,
        'baker': 150,
        'grillmaster': 180,
        'sommelier': 100,
        'barista': 250,
        'mixologist': 120,
        'foodie': 380,
        // Culture & Arts
        'historian': 200,
        'artist': 120,
        'musician': 80,
        'linguist': 200,
        // Social & Nightlife
        'partygoer': 150,
        'dancer': 100,
        'socialite': 280,
        'volunteer': 180,
        // Urban & Photography
        'photographer': 510,
        'explorer': 350,
        'shopper': 180,
        // Travel & Freedom
        'nomad': 90,
        'backpacker': 260,
        'roadtripper': 210,
        'pilot': 50,
        // Unique
        'festival': 120,
        'sunset': 200,
        'aurora': 30,
      },
      skillLevels: const {},
      currentStreak: 5,
    );
  }

  void setCategoryFilter(String? category) {
    if (category == state.filterCategory) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(filterCategory: category);
    }
  }

  void setDifficultyFilter(QuestDifficulty? difficulty) {
    if (difficulty == state.filterDifficulty) {
      state = state.copyWith(clearDifficultyFilter: true);
    } else {
      state = state.copyWith(filterDifficulty: difficulty);
    }
  }

  bool completeQuest(String questId) {
    final index = state.allQuests.indexWhere((q) => q.id == questId);
    if (index == -1) return false;

    final quest = state.allQuests[index];
    if (quest.isCompleted && !quest.isRepeatable) return false;
    if (quest.isRepeatable && quest.completionCount >= quest.maxCompletions) {
      return false;
    }

    final newCount = quest.completionCount + 1;
    final completed = SideQuest(
      id: quest.id,
      title: quest.title,
      description: quest.description,
      category: quest.category,
      skillType: quest.skillType,
      difficulty: quest.difficulty,
      xpReward: quest.xpReward,
      verification: quest.verification,
      isRepeatable: quest.isRepeatable,
      maxCompletions: quest.maxCompletions,
      completionCount: newCount,
      isCompleted: true,
    );

    final updatedQuests = [...state.allQuests];
    updatedQuests[index] = completed;

    // Calculate XP with diminishing returns for repeats
    final xpEarned = _calculateQuestXp(quest.xpReward, newCount);

    // Update skill XP
    final updatedSkillXp = Map<String, int>.from(state.skillXp);
    final currentSkillXp = updatedSkillXp[quest.skillType] ?? 0;
    updatedSkillXp[quest.skillType] = currentSkillXp + xpEarned;

    // Update skill level
    final updatedSkillLevels = Map<String, int>.from(state.skillLevels);
    updatedSkillLevels[quest.skillType] =
        _calculateSkillLevel(updatedSkillXp[quest.skillType]!);

    // Update streak
    final now = DateTime.now();
    final lastDate = state.lastCompletionDate;
    int newStreak = state.currentStreak;
    if (lastDate != null) {
      final diff = now.difference(lastDate).inDays;
      if (diff <= 1) {
        newStreak = state.currentStreak + 1;
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    state = state.copyWith(
      allQuests: updatedQuests,
      skillXp: updatedSkillXp,
      skillLevels: updatedSkillLevels,
      currentStreak: newStreak,
      lastCompletionDate: now,
    );

    // Award global XP
    ref.read(userProfileProvider.notifier).addXp(xpEarned);
    return true;
  }

  int _calculateQuestXp(int baseXp, int completionCount) {
    // Diminishing returns: 100%, 75%, 50%, 25% for repeats
    if (completionCount <= 1) return baseXp;
    if (completionCount == 2) return (baseXp * 0.75).round();
    if (completionCount == 3) return (baseXp * 0.50).round();
    return (baseXp * 0.25).round();
  }

  int _calculateSkillLevel(int skillXp) {
    // 350-700 XP per level, max level 50
    const xpPerLevel = 500;
    final level = (skillXp / xpPerLevel).floor() + 1;
    return level.clamp(1, 50);
  }
}

final questsProvider =
    StateNotifierProvider<QuestsNotifier, QuestsState>(
  (ref) => QuestsNotifier(ref),
);

// Note: questRegistry is now imported from quest_registry.dart
// Contains 150+ quests across 18 categories
