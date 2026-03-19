import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapFilterState {
  final bool showAchievements;
  final bool showQuests;
  final bool showSkills;
  /// Selected subfilters for achievements (collectionIds), empty = show all
  final Set<String> selectedAchievementCollections;
  /// Selected subfilters for quests (categories), empty = show all
  final Set<String> selectedQuestCategories;
  /// Selected subfilters for skills (skill ids), empty = show all
  final Set<String> selectedSkillIds;

  const MapFilterState({
    this.showAchievements = true,
    this.showQuests = true,
    this.showSkills = true,
    this.selectedAchievementCollections = const {},
    this.selectedQuestCategories = const {},
    this.selectedSkillIds = const {},
  });

  MapFilterState copyWith({
    bool? showAchievements,
    bool? showQuests,
    bool? showSkills,
    Set<String>? selectedAchievementCollections,
    Set<String>? selectedQuestCategories,
    Set<String>? selectedSkillIds,
  }) {
    return MapFilterState(
      showAchievements: showAchievements ?? this.showAchievements,
      showQuests: showQuests ?? this.showQuests,
      showSkills: showSkills ?? this.showSkills,
      selectedAchievementCollections:
          selectedAchievementCollections ?? this.selectedAchievementCollections,
      selectedQuestCategories:
          selectedQuestCategories ?? this.selectedQuestCategories,
      selectedSkillIds: selectedSkillIds ?? this.selectedSkillIds,
    );
  }
}

class MapFilterNotifier extends StateNotifier<MapFilterState> {
  MapFilterNotifier() : super(const MapFilterState());

  void toggleAchievements() =>
      state = state.copyWith(
        showAchievements: !state.showAchievements,
        selectedAchievementCollections: const {},
      );

  void toggleQuests() =>
      state = state.copyWith(
        showQuests: !state.showQuests,
        selectedQuestCategories: const {},
      );

  void toggleSkills() =>
      state = state.copyWith(
        showSkills: !state.showSkills,
        selectedSkillIds: const {},
      );

  void toggleAchievementCollection(String collectionId) {
    final current = Set<String>.from(state.selectedAchievementCollections);
    if (current.contains(collectionId)) {
      current.remove(collectionId);
    } else {
      current.add(collectionId);
    }
    state = state.copyWith(selectedAchievementCollections: current);
  }

  void toggleQuestCategory(String category) {
    final current = Set<String>.from(state.selectedQuestCategories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    state = state.copyWith(selectedQuestCategories: current);
  }

  void toggleSkillId(String skillId) {
    final current = Set<String>.from(state.selectedSkillIds);
    if (current.contains(skillId)) {
      current.remove(skillId);
    } else {
      current.add(skillId);
    }
    state = state.copyWith(selectedSkillIds: current);
  }
}

final mapFilterProvider =
    StateNotifierProvider<MapFilterNotifier, MapFilterState>(
  (ref) => MapFilterNotifier(),
);
