import 'dart:ui';

import 'package:travel_buddy_mobile/core/theme/app_theme.dart';
import 'package:travel_buddy_mobile/features/map/presentation/widgets/achievement_marker.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/models/side_quest.dart';
import 'package:travel_buddy_mobile/shared/models/skill_group.dart';

enum MapMarkerType { achievement, quest, skill }

sealed class MapMarkerItem {
  final String id;
  final double latitude;
  final double longitude;
  final MapMarkerType type;
  final Color pinColor;

  const MapMarkerItem({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.pinColor,
  });
}

class AchievementMarkerItem extends MapMarkerItem {
  final Achievement achievement;

  AchievementMarkerItem({required this.achievement})
      : super(
          id: achievement.id,
          latitude: achievement.latitude!,
          longitude: achievement.longitude!,
          type: MapMarkerType.achievement,
          pinColor: AchievementMarker.tierColor(achievement.tier),
        );
}

class QuestMarkerItem extends MapMarkerItem {
  final SideQuest quest;

  QuestMarkerItem({required this.quest})
      : super(
          id: quest.id,
          latitude: quest.latitude!,
          longitude: quest.longitude!,
          type: MapMarkerType.quest,
          pinColor: _questDifficultyColor(quest.difficulty),
        );

  static Color _questDifficultyColor(QuestDifficulty difficulty) {
    return switch (difficulty) {
      QuestDifficulty.easy => AppColors.success,
      QuestDifficulty.medium => AppColors.accent,
      QuestDifficulty.hard => const Color(0xFFF97316),
      QuestDifficulty.legendary => const Color(0xFF9333EA),
    };
  }
}

class SkillMarkerItem extends MapMarkerItem {
  final SkillGroup skill;

  SkillMarkerItem({required this.skill})
      : super(
          id: skill.id,
          latitude: skill.latitude!,
          longitude: skill.longitude!,
          type: MapMarkerType.skill,
          pinColor: parseHexColor(skill.gradientStart),
        );

  static Color parseHexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) buffer.write('FF');
    buffer.write(hex);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
