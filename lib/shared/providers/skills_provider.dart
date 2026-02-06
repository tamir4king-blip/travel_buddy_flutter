import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy/shared/models/skill_group.dart';
import 'package:travel_buddy/shared/data/skill_registry.dart';

class SkillsState {
  final List<SkillGroup> allSkills;

  const SkillsState({this.allSkills = const []});

  SkillGroup? getSkillById(String id) {
    try {
      return allSkills.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<SkillGroup> getSkillsByCategory(String category) {
    return allSkills.where((s) => s.categories.contains(category)).toList();
  }
}

class SkillsNotifier extends StateNotifier<SkillsState> {
  SkillsNotifier() : super(const SkillsState()) {
    _loadSkills();
  }

  void _loadSkills() {
    state = const SkillsState(allSkills: skillRegistry);
  }
}

final skillsProvider =
    StateNotifierProvider<SkillsNotifier, SkillsState>(
  (ref) => SkillsNotifier(),
);

// Legacy: keeping the old registry reference for backwards compatibility
// Now uses the expanded 44-skill registry from skill_registry.dart
const legacySkillRegistry = <SkillGroup>[
  SkillGroup(
    id: 'hiker',
    name: 'Hiker',
    icon: '🥾',
    description: 'Trail master',
    categories: ['hiking'],
    maxLevel: 50,
    xpPerLevel: 500,
    gradientStart: '#16a34a',
    gradientEnd: '#10b981',
  ),
  SkillGroup(
    id: 'camper',
    name: 'Camper',
    icon: '⛺',
    description: 'Outdoor survivor',
    categories: ['camping'],
    maxLevel: 50,
    xpPerLevel: 500,
    gradientStart: '#d97706',
    gradientEnd: '#f97316',
  ),
  SkillGroup(
    id: 'angler',
    name: 'Angler',
    icon: '🎣',
    description: 'Master fisher',
    categories: ['fishing'],
    maxLevel: 50,
    xpPerLevel: 450,
    gradientStart: '#2563eb',
    gradientEnd: '#06b6d4',
  ),
  SkillGroup(
    id: 'diver',
    name: 'Diver',
    icon: '🤿',
    description: 'Deep explorer',
    categories: ['water_sports'],
    maxLevel: 50,
    xpPerLevel: 600,
    gradientStart: '#0891b2',
    gradientEnd: '#2563eb',
  ),
  SkillGroup(
    id: 'photographer',
    name: 'Photographer',
    icon: '📸',
    description: 'Moment catcher',
    categories: ['photography'],
    maxLevel: 50,
    xpPerLevel: 400,
    gradientStart: '#374151',
    gradientEnd: '#475569',
  ),
  SkillGroup(
    id: 'chef',
    name: 'Chef',
    icon: '👨‍🍳',
    description: 'Kitchen master',
    categories: ['cooking'],
    maxLevel: 50,
    xpPerLevel: 400,
    gradientStart: '#f97316',
    gradientEnd: '#ef4444',
  ),
  SkillGroup(
    id: 'historian',
    name: 'Historian',
    icon: '🏛️',
    description: 'Past keeper',
    categories: ['culture'],
    maxLevel: 50,
    xpPerLevel: 400,
    gradientStart: '#b45309',
    gradientEnd: '#ca8a04',
  ),
  SkillGroup(
    id: 'explorer',
    name: 'Explorer',
    icon: '🧭',
    description: 'Urban navigator',
    categories: ['culture', 'photography'],
    maxLevel: 50,
    xpPerLevel: 350,
    gradientStart: '#475569',
    gradientEnd: '#71717a',
  ),
  SkillGroup(
    id: 'nomad',
    name: 'Digital Nomad',
    icon: '💻',
    description: 'Work anywhere',
    categories: ['culture', 'cooking'],
    maxLevel: 50,
    xpPerLevel: 500,
    gradientStart: '#3b82f6',
    gradientEnd: '#8b5cf6',
  ),
  SkillGroup(
    id: 'backpacker',
    name: 'Backpacker',
    icon: '🎒',
    description: 'Free traveler',
    categories: ['hiking', 'camping'],
    maxLevel: 50,
    xpPerLevel: 450,
    gradientStart: '#059669',
    gradientEnd: '#10b981',
  ),
  SkillGroup(
    id: 'roadtripper',
    name: 'Road Tripper',
    icon: '🚗',
    description: 'Road nomad',
    categories: ['culture', 'hiking'],
    maxLevel: 50,
    xpPerLevel: 400,
    gradientStart: '#f59e0b',
    gradientEnd: '#ef4444',
  ),
  SkillGroup(
    id: 'festival',
    name: 'Festival Goer',
    icon: '🎪',
    description: 'Life celebrator',
    categories: ['culture', 'photography'],
    maxLevel: 50,
    xpPerLevel: 450,
    gradientStart: '#c026d3',
    gradientEnd: '#e879f9',
  ),
];
