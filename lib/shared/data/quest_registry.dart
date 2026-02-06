import 'package:travel_buddy/shared/models/side_quest.dart';

/// Expanded quest registry - 150+ quests from Travel Trophies
/// 18 categories: fishing, cooking, hiking, skiing, camping, photography,
/// water-sports, wildlife, cultural, adventure, wellness, nightlife,
/// urban, social, extreme, food-drink, transportation, shopping

// ============================================
// FISHING QUESTS
// ============================================
const fishingQuests = <SideQuest>[
  SideQuest(
    id: 'first-catch', title: 'First Catch',
    description: 'Catch your first fish on a trip',
    category: 'fishing', skillType: 'angler',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'sea-fishing', title: 'Sea Fishing',
    description: 'Go deep sea fishing in the open ocean',
    category: 'fishing', skillType: 'angler',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'lake-fishing', title: 'Lake Fishing',
    description: 'Fish at a lake or reservoir',
    category: 'fishing', skillType: 'angler',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'catch-three', title: 'Triple Catch',
    description: 'Catch 3 fish in one day',
    category: 'fishing', skillType: 'angler',
    difficulty: QuestDifficulty.medium, xpReward: 75,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'night-fishing', title: 'Night Fishing',
    description: 'Go fishing after sunset',
    category: 'fishing', skillType: 'angler',
    difficulty: QuestDifficulty.hard, xpReward: 85,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.timeBased,
  ),
  SideQuest(
    id: 'fly-fishing', title: 'Fly Fishing',
    description: 'Try traditional fly fishing technique',
    category: 'fishing', skillType: 'angler',
    difficulty: QuestDifficulty.hard, xpReward: 90,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'ice-fishing', title: 'Ice Fishing',
    description: 'Fish through a hole in the ice',
    category: 'fishing', skillType: 'angler',
    difficulty: QuestDifficulty.legendary, xpReward: 200,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'catch-and-release', title: 'Catch & Release',
    description: 'Catch a fish and release it back',
    category: 'fishing', skillType: 'angler',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// COOKING QUESTS
// ============================================
const cookingQuests = <SideQuest>[
  SideQuest(
    id: 'local-dish', title: 'Local Taste',
    description: 'Cook a traditional local dish',
    category: 'cooking', skillType: 'chef',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'street-food-tour', title: 'Street Food Tour',
    description: 'Try 5 different street foods in one day',
    category: 'cooking', skillType: 'chef',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'cooking-class', title: 'Cooking Class',
    description: 'Take a local cooking class',
    category: 'cooking', skillType: 'chef',
    difficulty: QuestDifficulty.medium, xpReward: 60,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'campfire-cooking', title: 'Campfire Cooking',
    description: 'Prepare a meal over a campfire',
    category: 'cooking', skillType: 'chef',
    difficulty: QuestDifficulty.hard, xpReward: 80,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'bake-bread', title: 'Bread Baker',
    description: 'Bake traditional local bread',
    category: 'cooking', skillType: 'baker',
    difficulty: QuestDifficulty.medium, xpReward: 55,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'farm-to-table', title: 'Farm to Table',
    description: 'Pick vegetables and cook a meal with them',
    category: 'cooking', skillType: 'chef',
    difficulty: QuestDifficulty.hard, xpReward: 85,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'catch-cook', title: 'Catch & Cook',
    description: 'Catch a fish and cook it the same day',
    category: 'cooking', skillType: 'chef',
    difficulty: QuestDifficulty.legendary, xpReward: 150,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// HIKING QUESTS
// ============================================
const hikingQuests = <SideQuest>[
  SideQuest(
    id: 'sunrise-hike', title: 'Summit Sunrise',
    description: 'Reach a peak before sunrise',
    category: 'hiking', skillType: 'hiker',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.timeBased,
  ),
  SideQuest(
    id: 'waterfall-trail', title: 'Waterfall Hunter',
    description: 'Hike to a waterfall',
    category: 'hiking', skillType: 'hiker',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'night-hike', title: 'Night Hike',
    description: 'Go hiking after dark',
    category: 'hiking', skillType: 'hiker',
    difficulty: QuestDifficulty.hard, xpReward: 80,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.timeBased,
  ),
  SideQuest(
    id: 'ten-km-hike', title: '10K Challenge',
    description: 'Complete a 10km hike',
    category: 'hiking', skillType: 'hiker',
    difficulty: QuestDifficulty.medium, xpReward: 60,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.manual,
  ),
  SideQuest(
    id: 'canyon-hike', title: 'Canyon Crossing',
    description: 'Hike through a canyon or gorge',
    category: 'hiking', skillType: 'hiker',
    difficulty: QuestDifficulty.hard, xpReward: 90,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'summit-peak', title: 'Peak Conquest',
    description: 'Reach a mountain summit',
    category: 'hiking', skillType: 'hiker',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'forest-walk', title: 'Forest Walk',
    description: 'Walk through a forest for at least an hour',
    category: 'hiking', skillType: 'hiker',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'coastal-trail', title: 'Coastal Trail',
    description: 'Hike along the coastline',
    category: 'hiking', skillType: 'hiker',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'multi-day-trek', title: 'Multi-Day Trek',
    description: 'Complete a trek of 2+ days',
    category: 'hiking', skillType: 'hiker',
    difficulty: QuestDifficulty.legendary, xpReward: 250,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'thousand-steps', title: 'Thousand Steps',
    description: 'Climb 1000+ steps on a single hike',
    category: 'hiking', skillType: 'hiker',
    difficulty: QuestDifficulty.hard, xpReward: 75,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.manual,
  ),
];

// ============================================
// SKIING QUESTS
// ============================================
const skiingQuests = <SideQuest>[
  SideQuest(
    id: 'first-slope', title: 'First Slope',
    description: 'Ski down a slope for the first time',
    category: 'skiing', skillType: 'skier',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'black-diamond', title: 'Black Diamond',
    description: 'Complete an expert black run',
    category: 'skiing', skillType: 'skier',
    difficulty: QuestDifficulty.legendary, xpReward: 200,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'powder-day', title: 'Powder Day',
    description: 'Ski in fresh powder snow',
    category: 'skiing', skillType: 'skier',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'snowboard-first', title: 'Snowboard First',
    description: 'Try snowboarding for the first time',
    category: 'skiing', skillType: 'snowboarder',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'night-skiing', title: 'Night Skiing',
    description: 'Ski on illuminated slopes at night',
    category: 'skiing', skillType: 'skier',
    difficulty: QuestDifficulty.hard, xpReward: 85,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.timeBased,
  ),
  SideQuest(
    id: 'ski-lesson', title: 'Ski Lesson',
    description: 'Take a professional ski lesson',
    category: 'skiing', skillType: 'skier',
    difficulty: QuestDifficulty.easy, xpReward: 35,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// CAMPING QUESTS
// ============================================
const campingQuests = <SideQuest>[
  SideQuest(
    id: 'first-night', title: 'First Night',
    description: 'Spend your first night in a tent',
    category: 'camping', skillType: 'camper',
    difficulty: QuestDifficulty.easy, xpReward: 35,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'wild-camping', title: 'Wild Camping',
    description: 'Camp in the wilderness (not a campsite)',
    category: 'camping', skillType: 'camper',
    difficulty: QuestDifficulty.hard, xpReward: 90,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'stargazing', title: 'Stargazing',
    description: 'Watch stars in a dark location',
    category: 'camping', skillType: 'camper',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.timeBased,
  ),
  SideQuest(
    id: 'beach-camping', title: 'Beach Camping',
    description: 'Camp on the beach',
    category: 'camping', skillType: 'camper',
    difficulty: QuestDifficulty.medium, xpReward: 55,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'hammock-night', title: 'Hammock Night',
    description: 'Sleep in a hammock outdoors',
    category: 'camping', skillType: 'camper',
    difficulty: QuestDifficulty.medium, xpReward: 60,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'mountain-camping', title: 'Mountain Camping',
    description: 'Camp at 1000m+ elevation',
    category: 'camping', skillType: 'camper',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'rainy-camp', title: 'Rainy Camp',
    description: 'Camp through a rainy night',
    category: 'camping', skillType: 'camper',
    difficulty: QuestDifficulty.hard, xpReward: 80,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'week-camping', title: 'Week in Nature',
    description: 'Camp for 7 consecutive nights',
    category: 'camping', skillType: 'camper',
    difficulty: QuestDifficulty.legendary, xpReward: 300,
    isRepeatable: true, maxCompletions: 2,
    verification: VerificationMethod.manual,
  ),
];

// ============================================
// PHOTOGRAPHY QUESTS
// ============================================
const photographyQuests = <SideQuest>[
  SideQuest(
    id: 'golden-hour', title: 'Golden Hour',
    description: 'Take a photo during golden hour',
    category: 'photography', skillType: 'photographer',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.timeBased,
  ),
  SideQuest(
    id: 'wildlife-shot', title: 'Wildlife Shot',
    description: 'Photograph wildlife in its natural habitat',
    category: 'photography', skillType: 'photographer',
    difficulty: QuestDifficulty.hard, xpReward: 80,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'panorama', title: 'Panorama',
    description: 'Take a panoramic landscape photo',
    category: 'photography', skillType: 'photographer',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'night-photography', title: 'Night Shot',
    description: 'Take a long-exposure night photo',
    category: 'photography', skillType: 'photographer',
    difficulty: QuestDifficulty.hard, xpReward: 75,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'selfie-landmark', title: 'Landmark Selfie',
    description: 'Take a selfie at a famous landmark',
    category: 'photography', skillType: 'photographer',
    difficulty: QuestDifficulty.easy, xpReward: 20,
    isRepeatable: true, maxCompletions: 20,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'drone-shot', title: 'Drone Shot',
    description: 'Capture aerial footage with a drone',
    category: 'photography', skillType: 'photographer',
    difficulty: QuestDifficulty.hard, xpReward: 90,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'underwater-photo', title: 'Underwater Photo',
    description: 'Take photos underwater',
    category: 'photography', skillType: 'photographer',
    difficulty: QuestDifficulty.hard, xpReward: 85,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'milky-way', title: 'Milky Way',
    description: 'Photograph the Milky Way',
    category: 'photography', skillType: 'photographer',
    difficulty: QuestDifficulty.legendary, xpReward: 200,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'street-portrait', title: 'Street Portrait',
    description: 'Take a portrait of a local (with permission)',
    category: 'photography', skillType: 'photographer',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// WATER SPORTS QUESTS
// ============================================
const waterSportsQuests = <SideQuest>[
  SideQuest(
    id: 'first-surf', title: 'First Wave',
    description: 'Catch your first wave surfing',
    category: 'water-sports', skillType: 'surfer',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'snorkeling', title: 'Snorkeling',
    description: 'Go snorkeling and see fish',
    category: 'water-sports', skillType: 'diver',
    difficulty: QuestDifficulty.easy, xpReward: 35,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'kayaking', title: 'Kayak Trip',
    description: 'Go kayaking or canoeing',
    category: 'water-sports', skillType: 'kayaker',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'scuba-diving', title: 'Scuba Diving',
    description: 'Go scuba diving',
    category: 'water-sports', skillType: 'diver',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'jet-ski', title: 'Jet Ski',
    description: 'Ride a jet ski',
    category: 'water-sports', skillType: 'diver',
    difficulty: QuestDifficulty.medium, xpReward: 55,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'paddleboard', title: 'Paddleboard',
    description: 'Stand-up paddleboarding (SUP)',
    category: 'water-sports', skillType: 'surfer',
    difficulty: QuestDifficulty.easy, xpReward: 35,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'wakeboard', title: 'Wakeboard',
    description: 'Try wakeboarding behind a boat',
    category: 'water-sports', skillType: 'surfer',
    difficulty: QuestDifficulty.hard, xpReward: 85,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'white-water-rafting', title: 'White Water Rafting',
    description: 'Go white water rafting',
    category: 'water-sports', skillType: 'kayaker',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'cliff-jumping', title: 'Cliff Jumping',
    description: 'Jump from a cliff into water',
    category: 'water-sports', skillType: 'diver',
    difficulty: QuestDifficulty.hard, xpReward: 90,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// WILDLIFE QUESTS
// ============================================
const wildlifeQuests = <SideQuest>[
  SideQuest(
    id: 'bird-watching', title: 'Bird Watching',
    description: 'Identify 5 different bird species',
    category: 'wildlife', skillType: 'naturalist',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'safari', title: 'Safari',
    description: 'Go on a safari tour',
    category: 'wildlife', skillType: 'naturalist',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'marine-life', title: 'Marine Life',
    description: 'Spot dolphins, sea turtles, or similar',
    category: 'wildlife', skillType: 'naturalist',
    difficulty: QuestDifficulty.hard, xpReward: 80,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'whale-watching', title: 'Whale Watching',
    description: 'Go on a whale watching trip',
    category: 'wildlife', skillType: 'naturalist',
    difficulty: QuestDifficulty.legendary, xpReward: 180,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'butterfly-garden', title: 'Butterfly Garden',
    description: 'Visit a butterfly garden',
    category: 'wildlife', skillType: 'naturalist',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'night-wildlife', title: 'Night Wildlife',
    description: 'Spot nocturnal animals active at night',
    category: 'wildlife', skillType: 'naturalist',
    difficulty: QuestDifficulty.hard, xpReward: 75,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.timeBased,
  ),
  SideQuest(
    id: 'zoo-visit', title: 'Zoo Visit',
    description: 'Visit a zoo',
    category: 'wildlife', skillType: 'naturalist',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'aquarium', title: 'Aquarium',
    description: 'Visit an aquarium',
    category: 'wildlife', skillType: 'naturalist',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// CULTURAL QUESTS
// ============================================
const culturalQuests = <SideQuest>[
  SideQuest(
    id: 'local-festival', title: 'Local Festival',
    description: 'Attend a local festival or celebration',
    category: 'cultural', skillType: 'historian',
    difficulty: QuestDifficulty.medium, xpReward: 60,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'museum-visit', title: 'Museum Visit',
    description: 'Visit a local museum',
    category: 'cultural', skillType: 'historian',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'traditional-craft', title: 'Traditional Craft',
    description: 'Learn a traditional local craft',
    category: 'cultural', skillType: 'historian',
    difficulty: QuestDifficulty.medium, xpReward: 55,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'local-music', title: 'Local Music',
    description: 'Listen to live local music',
    category: 'cultural', skillType: 'musician',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'religious-site', title: 'Religious Site',
    description: 'Visit a religious or spiritual site',
    category: 'cultural', skillType: 'historian',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'traditional-dance', title: 'Traditional Dance',
    description: 'Participate in a traditional dance',
    category: 'cultural', skillType: 'dancer',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'language-lesson', title: 'Language Lesson',
    description: 'Learn phrases in the local language',
    category: 'cultural', skillType: 'linguist',
    difficulty: QuestDifficulty.easy, xpReward: 35,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.manual,
  ),
  SideQuest(
    id: 'historical-tour', title: 'Historical Tour',
    description: 'Take a guided historical tour',
    category: 'cultural', skillType: 'historian',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'unesco-site', title: 'UNESCO World Heritage',
    description: 'Visit a UNESCO World Heritage Site',
    category: 'cultural', skillType: 'historian',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// ADVENTURE QUESTS
// ============================================
const adventureQuests = <SideQuest>[
  SideQuest(
    id: 'bungee-jump', title: 'Bungee Jump',
    description: 'Do a bungee jump',
    category: 'adventure', skillType: 'skydiver',
    difficulty: QuestDifficulty.legendary, xpReward: 200,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'paragliding', title: 'Paragliding',
    description: 'Go paragliding',
    category: 'adventure', skillType: 'paraglider',
    difficulty: QuestDifficulty.hard, xpReward: 120,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'rock-climbing', title: 'Rock Climbing',
    description: 'Go outdoor rock climbing',
    category: 'adventure', skillType: 'climber',
    difficulty: QuestDifficulty.hard, xpReward: 90,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'zip-line', title: 'Zip Line',
    description: 'Ride a zip line',
    category: 'adventure', skillType: 'backpacker',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'atv-ride', title: 'ATV Ride',
    description: 'Ride an ATV off-road',
    category: 'adventure', skillType: 'roadtripper',
    difficulty: QuestDifficulty.medium, xpReward: 55,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'hot-air-balloon', title: 'Hot Air Balloon',
    description: 'Ride in a hot air balloon',
    category: 'adventure', skillType: 'pilot',
    difficulty: QuestDifficulty.legendary, xpReward: 180,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'caving', title: 'Cave Exploration',
    description: 'Explore a natural cave',
    category: 'adventure', skillType: 'backpacker',
    difficulty: QuestDifficulty.hard, xpReward: 85,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'helicopter-ride', title: 'Helicopter Ride',
    description: 'Take a scenic helicopter ride',
    category: 'adventure', skillType: 'pilot',
    difficulty: QuestDifficulty.legendary, xpReward: 200,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// WELLNESS QUESTS
// ============================================
const wellnessQuests = <SideQuest>[
  SideQuest(
    id: 'spa-day', title: 'Spa Day',
    description: 'Spend a day at a spa',
    category: 'wellness', skillType: 'yogi',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'hot-springs', title: 'Hot Springs',
    description: 'Bathe in natural hot springs',
    category: 'wellness', skillType: 'yogi',
    difficulty: QuestDifficulty.medium, xpReward: 60,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'yoga-session', title: 'Yoga Session',
    description: 'Attend a yoga class',
    category: 'wellness', skillType: 'yogi',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'beach-yoga', title: 'Beach Yoga',
    description: 'Do yoga on the beach',
    category: 'wellness', skillType: 'yogi',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'meditation-retreat', title: 'Meditation Retreat',
    description: 'Attend a meditation retreat',
    category: 'wellness', skillType: 'yogi',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'massage', title: 'Traditional Massage',
    description: 'Get a traditional local massage',
    category: 'wellness', skillType: 'yogi',
    difficulty: QuestDifficulty.easy, xpReward: 35,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.manual,
  ),
  SideQuest(
    id: 'sunrise-meditation', title: 'Sunrise Meditation',
    description: 'Meditate during sunrise',
    category: 'wellness', skillType: 'yogi',
    difficulty: QuestDifficulty.hard, xpReward: 80,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.timeBased,
  ),
  SideQuest(
    id: 'digital-detox', title: 'Digital Detox',
    description: 'Spend 24 hours without screens',
    category: 'wellness', skillType: 'yogi',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.manual,
  ),
];

// ============================================
// NIGHTLIFE QUESTS
// ============================================
const nightlifeQuests = <SideQuest>[
  SideQuest(
    id: 'rooftop-bar', title: 'Rooftop Bar',
    description: 'Visit a rooftop bar with a view',
    category: 'nightlife', skillType: 'partygoer',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'local-club', title: 'Local Club',
    description: 'Dance at a local nightclub',
    category: 'nightlife', skillType: 'partygoer',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'pub-crawl', title: 'Pub Crawl',
    description: 'Visit 3+ pubs in one night',
    category: 'nightlife', skillType: 'partygoer',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'live-concert', title: 'Live Concert',
    description: 'Attend a live concert at night',
    category: 'nightlife', skillType: 'partygoer',
    difficulty: QuestDifficulty.medium, xpReward: 55,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'karaoke', title: 'Karaoke Night',
    description: 'Sing karaoke in public',
    category: 'nightlife', skillType: 'partygoer',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'beach-party', title: 'Beach Party',
    description: 'Attend a beach party at night',
    category: 'nightlife', skillType: 'partygoer',
    difficulty: QuestDifficulty.medium, xpReward: 60,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'all-nighter', title: 'All Nighter',
    description: 'Stay out until sunrise',
    category: 'nightlife', skillType: 'partygoer',
    difficulty: QuestDifficulty.hard, xpReward: 90,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.timeBased,
  ),
];

// ============================================
// URBAN QUESTS
// ============================================
const urbanQuests = <SideQuest>[
  SideQuest(
    id: 'street-art-tour', title: 'Street Art Tour',
    description: 'Find 5 pieces of street art',
    category: 'urban', skillType: 'explorer',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'hidden-alley', title: 'Hidden Alley',
    description: 'Discover a hidden alley or corner',
    category: 'urban', skillType: 'explorer',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'observation-deck', title: 'City Viewpoint',
    description: 'Visit an observation deck',
    category: 'urban', skillType: 'explorer',
    difficulty: QuestDifficulty.easy, xpReward: 35,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'local-market', title: 'Local Market',
    description: 'Explore a local market',
    category: 'urban', skillType: 'explorer',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'public-transport', title: 'Public Transport',
    description: 'Ride local public transport',
    category: 'urban', skillType: 'explorer',
    difficulty: QuestDifficulty.easy, xpReward: 20,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'city-park', title: 'City Park',
    description: 'Spend an hour in a city park',
    category: 'urban', skillType: 'explorer',
    difficulty: QuestDifficulty.easy, xpReward: 20,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'walking-tour', title: 'Walking Tour',
    description: 'Join a guided walking tour',
    category: 'urban', skillType: 'explorer',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'get-lost', title: 'Get Lost',
    description: 'Explore without a map and discover new places',
    category: 'urban', skillType: 'explorer',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.manual,
  ),
];

// ============================================
// SOCIAL QUESTS
// ============================================
const socialQuests = <SideQuest>[
  SideQuest(
    id: 'meet-local', title: 'Meet a Local',
    description: 'Make friends with a local',
    category: 'social', skillType: 'socialite',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.manual,
  ),
  SideQuest(
    id: 'travel-buddy', title: 'Travel Buddy',
    description: 'Meet another traveler and do an activity together',
    category: 'social', skillType: 'socialite',
    difficulty: QuestDifficulty.medium, xpReward: 55,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'hostel-social', title: 'Hostel Event',
    description: 'Join a hostel social event',
    category: 'social', skillType: 'socialite',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'share-meal', title: 'Shared Meal',
    description: 'Share a meal with strangers',
    category: 'social', skillType: 'socialite',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'volunteer', title: 'Volunteer',
    description: 'Volunteer for a local project',
    category: 'social', skillType: 'volunteer',
    difficulty: QuestDifficulty.hard, xpReward: 100,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'group-activity', title: 'Group Activity',
    description: 'Join an organized group activity',
    category: 'social', skillType: 'socialite',
    difficulty: QuestDifficulty.easy, xpReward: 35,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'local-invite', title: 'Local Invitation',
    description: 'Get invited to a local\'s home',
    category: 'social', skillType: 'socialite',
    difficulty: QuestDifficulty.legendary, xpReward: 150,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// EXTREME QUESTS
// ============================================
const extremeQuests = <SideQuest>[
  SideQuest(
    id: 'skydiving', title: 'Skydiving',
    description: 'Go skydiving',
    category: 'extreme', skillType: 'skydiver',
    difficulty: QuestDifficulty.legendary, xpReward: 300,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'shark-diving', title: 'Shark Cage Diving',
    description: 'Dive in a cage with sharks',
    category: 'extreme', skillType: 'diver',
    difficulty: QuestDifficulty.legendary, xpReward: 250,
    isRepeatable: true, maxCompletions: 2,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'via-ferrata', title: 'Via Ferrata',
    description: 'Complete a via ferrata route',
    category: 'extreme', skillType: 'climber',
    difficulty: QuestDifficulty.hard, xpReward: 120,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'ice-climbing', title: 'Ice Climbing',
    description: 'Climb an ice wall',
    category: 'extreme', skillType: 'climber',
    difficulty: QuestDifficulty.legendary, xpReward: 220,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'volcano-hike', title: 'Active Volcano',
    description: 'Hike on an active volcano',
    category: 'extreme', skillType: 'hiker',
    difficulty: QuestDifficulty.legendary, xpReward: 200,
    isRepeatable: true, maxCompletions: 3,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'night-dive', title: 'Night Dive',
    description: 'Go scuba diving at night',
    category: 'extreme', skillType: 'diver',
    difficulty: QuestDifficulty.hard, xpReward: 130,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.timeBased,
  ),
  SideQuest(
    id: 'sandboarding', title: 'Sandboarding',
    description: 'Sandboard down dunes',
    category: 'extreme', skillType: 'snowboarder',
    difficulty: QuestDifficulty.hard, xpReward: 85,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// FOOD & DRINK QUESTS
// ============================================
const foodDrinkQuests = <SideQuest>[
  SideQuest(
    id: 'local-breakfast', title: 'Local Breakfast',
    description: 'Eat a traditional local breakfast',
    category: 'food-drink', skillType: 'foodie',
    difficulty: QuestDifficulty.easy, xpReward: 20,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'wine-tasting', title: 'Wine Tasting',
    description: 'Do a wine tasting at a winery',
    category: 'food-drink', skillType: 'sommelier',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'beer-brewery', title: 'Brewery Tour',
    description: 'Visit a beer brewery',
    category: 'food-drink', skillType: 'mixologist',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'food-market', title: 'Food Market',
    description: 'Try 5 things at a food market',
    category: 'food-drink', skillType: 'foodie',
    difficulty: QuestDifficulty.easy, xpReward: 35,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'exotic-food', title: 'Exotic Food',
    description: 'Try something you\'ve never eaten',
    category: 'food-drink', skillType: 'foodie',
    difficulty: QuestDifficulty.medium, xpReward: 60,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'coffee-culture', title: 'Coffee Culture',
    description: 'Try traditional local coffee',
    category: 'food-drink', skillType: 'barista',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'tea-ceremony', title: 'Tea Ceremony',
    description: 'Participate in a traditional tea ceremony',
    category: 'food-drink', skillType: 'barista',
    difficulty: QuestDifficulty.medium, xpReward: 55,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'local-dessert', title: 'Local Dessert',
    description: 'Try a traditional local dessert',
    category: 'food-drink', skillType: 'foodie',
    difficulty: QuestDifficulty.easy, xpReward: 20,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// TRANSPORTATION QUESTS
// ============================================
const transportationQuests = <SideQuest>[
  SideQuest(
    id: 'train-journey', title: 'Train Journey',
    description: 'Take a train ride over 2 hours',
    category: 'transportation', skillType: 'roadtripper',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'overnight-train', title: 'Overnight Train',
    description: 'Travel on a sleeper train',
    category: 'transportation', skillType: 'roadtripper',
    difficulty: QuestDifficulty.hard, xpReward: 80,
    isRepeatable: true, maxCompletions: 5,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'tuk-tuk', title: 'Tuk-Tuk Ride',
    description: 'Ride a tuk-tuk or rickshaw',
    category: 'transportation', skillType: 'roadtripper',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'cable-car', title: 'Cable Car',
    description: 'Ride a cable car',
    category: 'transportation', skillType: 'roadtripper',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'ferry-ride', title: 'Ferry Ride',
    description: 'Take a ferry',
    category: 'transportation', skillType: 'sailor',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'bike-rental', title: 'Bike Rental',
    description: 'Rent a bike and explore the city',
    category: 'transportation', skillType: 'biker',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'scooter-ride', title: 'Scooter Ride',
    description: 'Rent a scooter and explore',
    category: 'transportation', skillType: 'roadtripper',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'boat-tour', title: 'Boat Tour',
    description: 'Take a scenic boat tour',
    category: 'transportation', skillType: 'sailor',
    difficulty: QuestDifficulty.easy, xpReward: 35,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// SHOPPING QUESTS
// ============================================
const shoppingQuests = <SideQuest>[
  SideQuest(
    id: 'local-souvenir', title: 'Local Souvenir',
    description: 'Buy a locally-made souvenir',
    category: 'shopping', skillType: 'shopper',
    difficulty: QuestDifficulty.easy, xpReward: 20,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'bargain-master', title: 'Bargain Master',
    description: 'Successfully bargain for a lower price',
    category: 'shopping', skillType: 'shopper',
    difficulty: QuestDifficulty.medium, xpReward: 40,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.manual,
  ),
  SideQuest(
    id: 'night-market', title: 'Night Market',
    description: 'Visit a night market',
    category: 'shopping', skillType: 'shopper',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'flea-market', title: 'Flea Market Find',
    description: 'Find a treasure at a flea market',
    category: 'shopping', skillType: 'shopper',
    difficulty: QuestDifficulty.medium, xpReward: 45,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'local-craft', title: 'Handmade Craft',
    description: 'Buy handmade crafts from a local artisan',
    category: 'shopping', skillType: 'shopper',
    difficulty: QuestDifficulty.medium, xpReward: 50,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'local-fashion', title: 'Local Fashion',
    description: 'Buy clothing in local style',
    category: 'shopping', skillType: 'shopper',
    difficulty: QuestDifficulty.easy, xpReward: 30,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
  SideQuest(
    id: 'bookshop', title: 'Local Bookshop',
    description: 'Visit an independent bookshop',
    category: 'shopping', skillType: 'shopper',
    difficulty: QuestDifficulty.easy, xpReward: 25,
    isRepeatable: true, maxCompletions: 10,
    verification: VerificationMethod.photo,
  ),
];

// ============================================
// ALL QUESTS COMBINED
// ============================================
const questRegistry = <SideQuest>[
  ...fishingQuests,
  ...cookingQuests,
  ...hikingQuests,
  ...skiingQuests,
  ...campingQuests,
  ...photographyQuests,
  ...waterSportsQuests,
  ...wildlifeQuests,
  ...culturalQuests,
  ...adventureQuests,
  ...wellnessQuests,
  ...nightlifeQuests,
  ...urbanQuests,
  ...socialQuests,
  ...extremeQuests,
  ...foodDrinkQuests,
  ...transportationQuests,
  ...shoppingQuests,
];

/// Get quests by category
List<SideQuest> getQuestsByCategory(String category) {
  return questRegistry.where((q) => q.category == category).toList();
}

/// Get a quest by ID
SideQuest? getQuestById(String id) {
  try {
    return questRegistry.firstWhere((q) => q.id == id);
  } catch (_) {
    return null;
  }
}

/// Get all unique categories
List<String> getAllCategories() {
  return questRegistry.map((q) => q.category).toSet().toList()..sort();
}
