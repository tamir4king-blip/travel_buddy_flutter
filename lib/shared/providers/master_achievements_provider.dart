import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy/shared/models/master_achievement.dart';
import 'package:travel_buddy/shared/models/user_profile.dart';
import 'package:travel_buddy/shared/data/master_achievement_registry.dart';
import 'package:travel_buddy/shared/providers/achievements_provider.dart';
import 'package:travel_buddy/shared/providers/quests_provider.dart';
import 'package:travel_buddy/shared/providers/user_profile_provider.dart';

class MasterAchievementsState {
  final List<MasterAchievement> allMasterAchievements;
  final List<MasterAchievement> unlockedMasterAchievements;
  final MasterTier? filterTier;

  const MasterAchievementsState({
    this.allMasterAchievements = const [],
    this.unlockedMasterAchievements = const [],
    this.filterTier,
  });

  List<MasterAchievement> get filteredMasterAchievements {
    if (filterTier == null) return allMasterAchievements;
    return allMasterAchievements.where((m) => m.tier == filterTier).toList();
  }

  int get totalUnlocked => unlockedMasterAchievements.length;
  int get totalMasterAchievements => allMasterAchievements.length;

  MasterAchievementsState copyWith({
    List<MasterAchievement>? allMasterAchievements,
    List<MasterAchievement>? unlockedMasterAchievements,
    MasterTier? filterTier,
    bool clearTierFilter = false,
  }) {
    return MasterAchievementsState(
      allMasterAchievements: allMasterAchievements ?? this.allMasterAchievements,
      unlockedMasterAchievements: unlockedMasterAchievements ?? this.unlockedMasterAchievements,
      filterTier: clearTierFilter ? null : (filterTier ?? this.filterTier),
    );
  }
}

class MasterAchievementsNotifier extends StateNotifier<MasterAchievementsState> {
  final Ref ref;

  MasterAchievementsNotifier(this.ref) : super(const MasterAchievementsState()) {
    _loadMasterAchievements();
    _listenToChanges();
  }

  void _loadMasterAchievements() {
    final achievements = _calculateProgress(masterAchievementRegistry);
    state = MasterAchievementsState(
      allMasterAchievements: achievements,
      unlockedMasterAchievements: achievements.where((m) => m.isUnlocked).toList(),
    );
  }

  void _listenToChanges() {
    // Listen to achievements provider changes
    ref.listen(achievementsProvider, (_, __) => _checkAndUpdateProgress());
    // Listen to quests provider changes
    ref.listen(questsProvider, (_, __) => _checkAndUpdateProgress());
    // Listen to user profile changes
    ref.listen(userProfileProvider, (_, __) => _checkAndUpdateProgress());
  }

  void _checkAndUpdateProgress() {
    final updated = _calculateProgress(state.allMasterAchievements);

    // Check for newly unlocked achievements
    final newlyUnlocked = <MasterAchievement>[];
    for (int i = 0; i < updated.length; i++) {
      if (updated[i].isUnlocked && !state.allMasterAchievements[i].isUnlocked) {
        newlyUnlocked.add(updated[i]);
      }
    }

    state = state.copyWith(
      allMasterAchievements: updated,
      unlockedMasterAchievements: updated.where((m) => m.isUnlocked).toList(),
    );

    // Award XP for newly unlocked master achievements
    for (final master in newlyUnlocked) {
      ref.read(userProfileProvider.notifier).addXp(master.xpReward);
    }
  }

  List<MasterAchievement> _calculateProgress(List<MasterAchievement> masters) {
    final achievementsState = ref.read(achievementsProvider);
    final questsState = ref.read(questsProvider);
    final userProfile = ref.read(userProfileProvider);

    return masters.map((master) {
      if (master.isUnlocked) return master;

      double totalProgress = 0.0;
      int metRequirements = 0;

      for (final req in master.requirements) {
        final (progress, met) = _checkRequirement(
          req,
          achievementsState,
          questsState,
          userProfile,
        );
        totalProgress += progress;
        if (met) metRequirements++;
      }

      final avgProgress = master.requirements.isEmpty
          ? 0.0
          : totalProgress / master.requirements.length;

      final allMet = metRequirements == master.requirements.length;

      if (allMet && !master.isUnlocked) {
        return master.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          progress: 1.0,
        );
      }

      return master.copyWith(progress: avgProgress);
    }).toList();
  }

  (double progress, bool met) _checkRequirement(
    MasterRequirement req,
    AchievementsState achievementsState,
    QuestsState questsState,
    UserProfile userProfile,
  ) {
    switch (req.type) {
      case MasterRequirementType.completeCollection:
        final collectionAchievements = achievementsState.allAchievements
            .where((a) => a.collectionId == req.targetId)
            .toList();
        if (collectionAchievements.isEmpty) return (0.0, false);

        final unlocked = collectionAchievements.where((a) => a.isUnlocked).length;
        final progress = unlocked / collectionAchievements.length;
        return (progress, unlocked == collectionAchievements.length);

      case MasterRequirementType.skillLevel:
        if (req.targetId == '_multi_10') {
          // Special case: 10 skills at level 10
          final skillsAtLevel = questsState.skillLevels.values
              .where((level) => level >= 10)
              .length;
          final progress = skillsAtLevel / 10;
          return (progress.clamp(0.0, 1.0), skillsAtLevel >= 10);
        }

        final currentLevel = questsState.skillLevels[req.targetId] ?? 0;
        final progress = currentLevel / req.targetValue;
        return (progress.clamp(0.0, 1.0), currentLevel >= req.targetValue);

      case MasterRequirementType.questCount:
        final completed = questsState.completedCount;
        final progress = completed / req.targetValue;
        return (progress.clamp(0.0, 1.0), completed >= req.targetValue);

      case MasterRequirementType.userLevel:
        final progress = userProfile.level / req.targetValue;
        return (progress.clamp(0.0, 1.0), userProfile.level >= req.targetValue);

      case MasterRequirementType.achievementCount:
        final unlocked = achievementsState.totalUnlocked;
        final progress = unlocked / req.targetValue;
        return (progress.clamp(0.0, 1.0), unlocked >= req.targetValue);

      case MasterRequirementType.questCategory:
        final categoryQuests = questsState.allQuests
            .where((q) => q.category == req.targetId && q.isCompleted)
            .length;
        final progress = categoryQuests / req.targetValue;
        return (progress.clamp(0.0, 1.0), categoryQuests >= req.targetValue);

      case MasterRequirementType.streakDays:
        final streak = questsState.currentStreak;
        final progress = streak / req.targetValue;
        return (progress.clamp(0.0, 1.0), streak >= req.targetValue);
    }
  }

  void setTierFilter(MasterTier? tier) {
    if (tier == state.filterTier) {
      state = state.copyWith(clearTierFilter: true);
    } else {
      state = state.copyWith(filterTier: tier);
    }
  }

  void refresh() {
    _checkAndUpdateProgress();
  }
}

final masterAchievementsProvider =
    StateNotifierProvider<MasterAchievementsNotifier, MasterAchievementsState>(
  (ref) => MasterAchievementsNotifier(ref),
);
