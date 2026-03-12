import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapFilterState {
  final bool showAchievements;
  final bool showQuests;
  final bool showSkills;
  /// Selected subfilter for achievements (collectionId), null = show all
  final String? selectedAchievementCollection;
  /// Selected subfilter for quests (category), null = show all
  final String? selectedQuestCategory;
  /// Selected subfilter for skills (skill id), null = show all
  final String? selectedSkillId;

  const MapFilterState({
    this.showAchievements = true,
    this.showQuests = true,
    this.showSkills = true,
    this.selectedAchievementCollection,
    this.selectedQuestCategory,
    this.selectedSkillId,
  });

  MapFilterState copyWith({
    bool? showAchievements,
    bool? showQuests,
    bool? showSkills,
    String? selectedAchievementCollection,
    String? selectedQuestCategory,
    String? selectedSkillId,
    bool clearAchievementCollection = false,
    bool clearQuestCategory = false,
    bool clearSkillId = false,
  }) {
    return MapFilterState(
      showAchievements: showAchievements ?? this.showAchievements,
      showQuests: showQuests ?? this.showQuests,
      showSkills: showSkills ?? this.showSkills,
      selectedAchievementCollection: clearAchievementCollection
          ? null
          : (selectedAchievementCollection ?? this.selectedAchievementCollection),
      selectedQuestCategory: clearQuestCategory
          ? null
          : (selectedQuestCategory ?? this.selectedQuestCategory),
      selectedSkillId: clearSkillId
          ? null
          : (selectedSkillId ?? this.selectedSkillId),
    );
  }
}

class MapFilterNotifier extends StateNotifier<MapFilterState> {
  MapFilterNotifier() : super(const MapFilterState());

  void toggleAchievements() =>
      state = state.copyWith(
        showAchievements: !state.showAchievements,
        clearAchievementCollection: true,
      );

  void toggleQuests() =>
      state = state.copyWith(
        showQuests: !state.showQuests,
        clearQuestCategory: true,
      );

  void toggleSkills() =>
      state = state.copyWith(
        showSkills: !state.showSkills,
        clearSkillId: true,
      );

  void selectAchievementCollection(String? collectionId) {
    if (collectionId == state.selectedAchievementCollection) {
      state = state.copyWith(clearAchievementCollection: true);
    } else {
      state = state.copyWith(selectedAchievementCollection: collectionId);
    }
  }

  void selectQuestCategory(String? category) {
    if (category == state.selectedQuestCategory) {
      state = state.copyWith(clearQuestCategory: true);
    } else {
      state = state.copyWith(selectedQuestCategory: category);
    }
  }

  void selectSkillId(String? skillId) {
    if (skillId == state.selectedSkillId) {
      state = state.copyWith(clearSkillId: true);
    } else {
      state = state.copyWith(selectedSkillId: skillId);
    }
  }
}

final mapFilterProvider =
    StateNotifierProvider<MapFilterNotifier, MapFilterState>(
  (ref) => MapFilterNotifier(),
);
