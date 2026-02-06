import 'package:travel_buddy/shared/models/skill_group.dart';

/// Expanded skill registry - 44 skill groups from Travel Trophies
/// Categories: outdoor, water, extreme, sports, food, culture, social, urban, travel, crafts, mind, lifestyle, wellness
const skillRegistry = <SkillGroup>[
  // === OUTDOOR & NATURE ===
  SkillGroup(
    id: 'hiker', name: 'Hiker', icon: '🥾',
    description: 'Trail master',
    categories: ['hiking'],
    maxLevel: 50, xpPerLevel: 500,
    gradientStart: '#16a34a', gradientEnd: '#10b981',
  ),
  SkillGroup(
    id: 'camper', name: 'Camper', icon: '⛺',
    description: 'Outdoor survivor',
    categories: ['camping'],
    maxLevel: 50, xpPerLevel: 500,
    gradientStart: '#d97706', gradientEnd: '#f97316',
  ),
  SkillGroup(
    id: 'angler', name: 'Angler', icon: '🎣',
    description: 'Master fisher',
    categories: ['fishing'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#2563eb', gradientEnd: '#06b6d4',
  ),
  SkillGroup(
    id: 'naturalist', name: 'Naturalist', icon: '🦋',
    description: 'Wildlife whisperer',
    categories: ['wildlife'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#84cc16', gradientEnd: '#22c55e',
  ),
  SkillGroup(
    id: 'stargazer', name: 'Stargazer', icon: '🔭',
    description: 'Cosmic explorer',
    categories: ['adventure'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#1e1b4b', gradientEnd: '#312e81',
  ),
  SkillGroup(
    id: 'gardener', name: 'Gardener', icon: '🌱',
    description: 'Life grower',
    categories: ['wellness'],
    maxLevel: 50, xpPerLevel: 350,
    gradientStart: '#15803d', gradientEnd: '#4ade80',
  ),

  // === WATER SPORTS ===
  SkillGroup(
    id: 'diver', name: 'Diver', icon: '🤿',
    description: 'Deep explorer',
    categories: ['water-sports'],
    maxLevel: 50, xpPerLevel: 600,
    gradientStart: '#0891b2', gradientEnd: '#2563eb',
  ),
  SkillGroup(
    id: 'surfer', name: 'Surfer', icon: '🏄',
    description: 'Wave rider',
    categories: ['water-sports'],
    maxLevel: 50, xpPerLevel: 550,
    gradientStart: '#14b8a6', gradientEnd: '#22d3ee',
  ),
  SkillGroup(
    id: 'sailor', name: 'Sailor', icon: '⛵',
    description: 'Sea captain',
    categories: ['water-sports'],
    maxLevel: 50, xpPerLevel: 550,
    gradientStart: '#3b82f6', gradientEnd: '#6366f1',
  ),
  SkillGroup(
    id: 'kayaker', name: 'Kayaker', icon: '🚣',
    description: 'River rider',
    categories: ['water-sports'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#0284c7', gradientEnd: '#0ea5e9',
  ),
  SkillGroup(
    id: 'swimmer', name: 'Swimmer', icon: '🏊',
    description: 'Human fish',
    categories: ['water-sports', 'wellness'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#06b6d4', gradientEnd: '#22d3ee',
  ),

  // === EXTREME & ADRENALINE ===
  SkillGroup(
    id: 'skydiver', name: 'Skydiver', icon: '🪂',
    description: 'Freefall master',
    categories: ['extreme'],
    maxLevel: 50, xpPerLevel: 700,
    gradientStart: '#7c3aed', gradientEnd: '#d946ef',
  ),
  SkillGroup(
    id: 'climber', name: 'Climber', icon: '🧗',
    description: 'Vertical warrior',
    categories: ['extreme'],
    maxLevel: 50, xpPerLevel: 650,
    gradientStart: '#57534e', gradientEnd: '#d97706',
  ),
  SkillGroup(
    id: 'skier', name: 'Skier', icon: '⛷️',
    description: 'Mountain shredder',
    categories: ['skiing'],
    maxLevel: 50, xpPerLevel: 600,
    gradientStart: '#0ea5e9', gradientEnd: '#6366f1',
  ),
  SkillGroup(
    id: 'snowboarder', name: 'Snowboarder', icon: '🏂',
    description: 'Snow shredder',
    categories: ['skiing', 'extreme'],
    maxLevel: 50, xpPerLevel: 600,
    gradientStart: '#6366f1', gradientEnd: '#8b5cf6',
  ),
  SkillGroup(
    id: 'paraglider', name: 'Paraglider', icon: '🪂',
    description: 'Wind rider',
    categories: ['extreme'],
    maxLevel: 50, xpPerLevel: 650,
    gradientStart: '#f97316', gradientEnd: '#eab308',
  ),

  // === SPORTS & FITNESS ===
  SkillGroup(
    id: 'runner', name: 'Runner', icon: '🏃',
    description: 'Speed demon',
    categories: ['wellness'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#ef4444', gradientEnd: '#f97316',
  ),
  SkillGroup(
    id: 'biker', name: 'Cyclist', icon: '🚴',
    description: 'Road warrior',
    categories: ['transportation'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#eab308', gradientEnd: '#f59e0b',
  ),
  SkillGroup(
    id: 'yogi', name: 'Yogi', icon: '🧘',
    description: 'Inner peace',
    categories: ['wellness'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#a78bfa', gradientEnd: '#a855f7',
  ),
  SkillGroup(
    id: 'martial', name: 'Martial Artist', icon: '🥋',
    description: 'Warrior path',
    categories: ['wellness', 'extreme'],
    maxLevel: 50, xpPerLevel: 500,
    gradientStart: '#1f2937', gradientEnd: '#4b5563',
  ),

  // === FOOD & DRINK ===
  SkillGroup(
    id: 'chef', name: 'Chef', icon: '👨‍🍳',
    description: 'Kitchen master',
    categories: ['cooking'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#f97316', gradientEnd: '#ef4444',
  ),
  SkillGroup(
    id: 'baker', name: 'Baker', icon: '🥐',
    description: 'Dough artist',
    categories: ['cooking'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#d97706', gradientEnd: '#fbbf24',
  ),
  SkillGroup(
    id: 'grillmaster', name: 'Grill Master', icon: '🔥',
    description: 'Fire lord',
    categories: ['cooking'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#dc2626', gradientEnd: '#f97316',
  ),
  SkillGroup(
    id: 'sommelier', name: 'Sommelier', icon: '🍷',
    description: 'Wine expert',
    categories: ['food-drink'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#be123c', gradientEnd: '#9333ea',
  ),
  SkillGroup(
    id: 'barista', name: 'Barista', icon: '☕',
    description: 'Coffee artist',
    categories: ['food-drink'],
    maxLevel: 50, xpPerLevel: 350,
    gradientStart: '#92400e', gradientEnd: '#c2410c',
  ),
  SkillGroup(
    id: 'mixologist', name: 'Mixologist', icon: '🍸',
    description: 'Cocktail wizard',
    categories: ['food-drink', 'nightlife'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#7c3aed', gradientEnd: '#c026d3',
  ),
  SkillGroup(
    id: 'foodie', name: 'Foodie', icon: '🍜',
    description: 'World taster',
    categories: ['food-drink'],
    maxLevel: 50, xpPerLevel: 350,
    gradientStart: '#ea580c', gradientEnd: '#dc2626',
  ),

  // === CULTURE & ARTS ===
  SkillGroup(
    id: 'historian', name: 'Historian', icon: '🏛️',
    description: 'Past keeper',
    categories: ['cultural'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#b45309', gradientEnd: '#ca8a04',
  ),
  SkillGroup(
    id: 'artist', name: 'Artist', icon: '🎨',
    description: 'Creative soul',
    categories: ['cultural'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#ec4899', gradientEnd: '#a855f7',
  ),
  SkillGroup(
    id: 'musician', name: 'Musician', icon: '🎸',
    description: 'Sound master',
    categories: ['cultural'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#9333ea', gradientEnd: '#4f46e5',
  ),
  SkillGroup(
    id: 'linguist', name: 'Linguist', icon: '🗣️',
    description: 'Polyglot',
    categories: ['cultural'],
    maxLevel: 50, xpPerLevel: 500,
    gradientStart: '#0369a1', gradientEnd: '#0891b2',
  ),

  // === SOCIAL & NIGHTLIFE ===
  SkillGroup(
    id: 'partygoer', name: 'Party Animal', icon: '🎉',
    description: 'Life of party',
    categories: ['nightlife'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#d946ef', gradientEnd: '#ec4899',
  ),
  SkillGroup(
    id: 'dancer', name: 'Dancer', icon: '💃',
    description: 'Dance floor king',
    categories: ['nightlife'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#f43f5e', gradientEnd: '#db2777',
  ),
  SkillGroup(
    id: 'socialite', name: 'Socialite', icon: '🤝',
    description: 'People person',
    categories: ['social'],
    maxLevel: 50, xpPerLevel: 350,
    gradientStart: '#10b981', gradientEnd: '#14b8a6',
  ),
  SkillGroup(
    id: 'volunteer', name: 'Volunteer', icon: '💚',
    description: 'Community giver',
    categories: ['social'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#16a34a', gradientEnd: '#22c55e',
  ),

  // === URBAN & PHOTOGRAPHY ===
  SkillGroup(
    id: 'photographer', name: 'Photographer', icon: '📸',
    description: 'Moment catcher',
    categories: ['photography'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#374151', gradientEnd: '#475569',
  ),
  SkillGroup(
    id: 'explorer', name: 'Explorer', icon: '🧭',
    description: 'Urban navigator',
    categories: ['urban'],
    maxLevel: 50, xpPerLevel: 350,
    gradientStart: '#475569', gradientEnd: '#71717a',
  ),
  SkillGroup(
    id: 'shopper', name: 'Shopper', icon: '🛍️',
    description: 'Deal hunter',
    categories: ['shopping'],
    maxLevel: 50, xpPerLevel: 300,
    gradientStart: '#ec4899', gradientEnd: '#fb7185',
  ),

  // === TRAVEL & FREEDOM ===
  SkillGroup(
    id: 'nomad', name: 'Digital Nomad', icon: '💻',
    description: 'Work anywhere',
    categories: ['urban', 'adventure'],
    maxLevel: 50, xpPerLevel: 500,
    gradientStart: '#3b82f6', gradientEnd: '#8b5cf6',
  ),
  SkillGroup(
    id: 'backpacker', name: 'Backpacker', icon: '🎒',
    description: 'Free traveler',
    categories: ['adventure'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#059669', gradientEnd: '#10b981',
  ),
  SkillGroup(
    id: 'roadtripper', name: 'Road Tripper', icon: '🚗',
    description: 'Road nomad',
    categories: ['transportation', 'adventure'],
    maxLevel: 50, xpPerLevel: 400,
    gradientStart: '#f59e0b', gradientEnd: '#ef4444',
  ),
  SkillGroup(
    id: 'pilot', name: 'Aviator', icon: '✈️',
    description: 'Sky master',
    categories: ['transportation'],
    maxLevel: 50, xpPerLevel: 600,
    gradientStart: '#0284c7', gradientEnd: '#1d4ed8',
  ),

  // === UNIQUE EXPERIENCES ===
  SkillGroup(
    id: 'festival', name: 'Festival Goer', icon: '🎪',
    description: 'Life celebrator',
    categories: ['nightlife', 'social', 'cultural'],
    maxLevel: 50, xpPerLevel: 450,
    gradientStart: '#c026d3', gradientEnd: '#e879f9',
  ),
  SkillGroup(
    id: 'sunset', name: 'Sunset Chaser', icon: '🌅',
    description: 'Moment lover',
    categories: ['photography'],
    maxLevel: 50, xpPerLevel: 300,
    gradientStart: '#f97316', gradientEnd: '#fb923c',
  ),
  SkillGroup(
    id: 'aurora', name: 'Aurora Hunter', icon: '🌌',
    description: 'Light seeker',
    categories: ['adventure', 'photography'],
    maxLevel: 50, xpPerLevel: 600,
    gradientStart: '#4f46e5', gradientEnd: '#22c55e',
  ),
];

/// Get a skill group by ID
SkillGroup? getSkillById(String id) {
  try {
    return skillRegistry.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}

/// Get skill groups by category
List<SkillGroup> getSkillsByCategory(String category) {
  return skillRegistry.where((s) => s.categories.contains(category)).toList();
}
