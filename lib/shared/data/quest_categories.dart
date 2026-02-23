import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';

/// Super-categories that group the 18 quest categories into logical groups.
/// Used by both the Quests and Skills screens for consistent grouping.
class QuestSuperCategory {
  final String id;
  final String labelEn;
  final String labelHe;
  final IconData icon;
  final List<String> questCategories; // quest_registry category strings
  final Color color;

  const QuestSuperCategory({
    required this.id,
    required this.labelEn,
    required this.labelHe,
    required this.icon,
    required this.questCategories,
    required this.color,
  });

  String label(Locale locale) =>
      locale.languageCode == 'he' ? labelHe : labelEn;
}

const questSuperCategories = <QuestSuperCategory>[
  QuestSuperCategory(
    id: 'outdoor',
    labelEn: 'Outdoor',
    labelHe: 'שטח',
    icon: LucideIcons.trees,
    questCategories: ['hiking', 'camping', 'wildlife'],
    color: Color(0xFF16a34a),
  ),
  QuestSuperCategory(
    id: 'water',
    labelEn: 'Water',
    labelHe: 'מים',
    icon: LucideIcons.waves,
    questCategories: ['water-sports', 'fishing'],
    color: Color(0xFF0891b2),
  ),
  QuestSuperCategory(
    id: 'extreme',
    labelEn: 'Extreme',
    labelHe: 'אקסטרים',
    icon: LucideIcons.zap,
    questCategories: ['extreme', 'adventure', 'skiing'],
    color: Color(0xFF7c3aed),
  ),
  QuestSuperCategory(
    id: 'food',
    labelEn: 'Food & Drink',
    labelHe: 'אוכל ושתייה',
    icon: LucideIcons.utensils,
    questCategories: ['cooking', 'food-drink'],
    color: Color(0xFFf97316),
  ),
  QuestSuperCategory(
    id: 'culture',
    labelEn: 'Culture',
    labelHe: 'תרבות',
    icon: LucideIcons.landmark,
    questCategories: ['cultural'],
    color: Color(0xFFb45309),
  ),
  QuestSuperCategory(
    id: 'social',
    labelEn: 'Social',
    labelHe: 'חברתי',
    icon: LucideIcons.users,
    questCategories: ['social', 'nightlife'],
    color: Color(0xFFd946ef),
  ),
  QuestSuperCategory(
    id: 'urban',
    labelEn: 'Urban',
    labelHe: 'עירוני',
    icon: LucideIcons.building2,
    questCategories: ['urban', 'transportation', 'shopping'],
    color: Color(0xFF475569),
  ),
  QuestSuperCategory(
    id: 'creative',
    labelEn: 'Photo',
    labelHe: 'צילום',
    icon: LucideIcons.camera,
    questCategories: ['photography'],
    color: Color(0xFF374151),
  ),
  QuestSuperCategory(
    id: 'wellness',
    labelEn: 'Wellness',
    labelHe: 'רווחה',
    icon: LucideIcons.heart,
    questCategories: ['wellness'],
    color: Color(0xFFa78bfa),
  ),
];

/// Find the super-category for a given quest category string.
QuestSuperCategory? getSuperCategoryForQuest(String questCategory) {
  for (final sc in questSuperCategories) {
    if (sc.questCategories.contains(questCategory)) return sc;
  }
  return null;
}

/// Find super-category by its ID.
QuestSuperCategory? getSuperCategoryById(String id) {
  for (final sc in questSuperCategories) {
    if (sc.id == id) return sc;
  }
  return null;
}

/// Map a skill's categories to the best-matching super-category.
QuestSuperCategory? getSuperCategoryForSkill(List<String> skillCategories) {
  for (final cat in skillCategories) {
    final sc = getSuperCategoryForQuest(cat);
    if (sc != null) return sc;
  }
  return null;
}
