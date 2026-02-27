import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapFilterState {
  final bool showAchievements;
  final bool showQuests;
  final bool showSkills;

  const MapFilterState({
    this.showAchievements = true,
    this.showQuests = true,
    this.showSkills = true,
  });

  MapFilterState copyWith({
    bool? showAchievements,
    bool? showQuests,
    bool? showSkills,
  }) {
    return MapFilterState(
      showAchievements: showAchievements ?? this.showAchievements,
      showQuests: showQuests ?? this.showQuests,
      showSkills: showSkills ?? this.showSkills,
    );
  }
}

class MapFilterNotifier extends StateNotifier<MapFilterState> {
  MapFilterNotifier() : super(const MapFilterState());

  void toggleAchievements() =>
      state = state.copyWith(showAchievements: !state.showAchievements);

  void toggleQuests() =>
      state = state.copyWith(showQuests: !state.showQuests);

  void toggleSkills() =>
      state = state.copyWith(showSkills: !state.showSkills);
}

final mapFilterProvider =
    StateNotifierProvider<MapFilterNotifier, MapFilterState>(
  (ref) => MapFilterNotifier(),
);
