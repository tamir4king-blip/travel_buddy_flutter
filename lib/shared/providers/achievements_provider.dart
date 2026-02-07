import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy/shared/models/achievement.dart';
import 'package:travel_buddy/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy/shared/providers/persistence_provider.dart';

/// Data class for retroactive achievement claims
class RetroactiveClaimData {
  final DateTime visitDate;
  final List<String> photos;
  final String? notes;

  const RetroactiveClaimData({
    required this.visitDate,
    this.photos = const [],
    this.notes,
  });
}

class AchievementsState {
  final List<Achievement> allAchievements;
  final List<Achievement> unlockedAchievements;
  final AchievementTier? filterTier;
  final String? filterCollection;
  final String searchQuery;
  final Set<String> completedCollections;

  const AchievementsState({
    this.allAchievements = const [],
    this.unlockedAchievements = const [],
    this.filterTier,
    this.filterCollection,
    this.searchQuery = '',
    this.completedCollections = const {},
  });

  List<Achievement> get filteredAchievements {
    var list = allAchievements;
    if (filterTier != null) {
      list = list.where((a) => a.tier == filterTier).toList();
    }
    if (filterCollection != null) {
      list = list.where((a) => a.collectionId == filterCollection).toList();
    }
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((a) =>
          a.title.toLowerCase().contains(query) ||
          a.description.toLowerCase().contains(query)).toList();
    }
    return list;
  }

  int get totalUnlocked => unlockedAchievements.length;
  int get totalAchievements => allAchievements.length;

  AchievementsState copyWith({
    List<Achievement>? allAchievements,
    List<Achievement>? unlockedAchievements,
    AchievementTier? filterTier,
    String? filterCollection,
    String? searchQuery,
    Set<String>? completedCollections,
    bool clearTierFilter = false,
    bool clearCollectionFilter = false,
  }) {
    return AchievementsState(
      allAchievements: allAchievements ?? this.allAchievements,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      filterTier: clearTierFilter ? null : (filterTier ?? this.filterTier),
      filterCollection: clearCollectionFilter
          ? null
          : (filterCollection ?? this.filterCollection),
      searchQuery: searchQuery ?? this.searchQuery,
      completedCollections: completedCollections ?? this.completedCollections,
    );
  }
}

class AchievementsNotifier extends StateNotifier<AchievementsState> {
  final Ref ref;

  AchievementsNotifier(this.ref) : super(const AchievementsState()) {
    _loadAchievements();
  }

  void _loadAchievements() {
    final persistence = ref.read(persistenceServiceProvider);
    final savedAchievements = persistence.loadUnlockedAchievements();
    final savedCollections = persistence.loadCompletedCollections();

    // Build a map of saved data by id
    final savedMap = <String, Map<String, dynamic>>{};
    for (final json in savedAchievements) {
      final id = json['id'] as String?;
      if (id != null) savedMap[id] = json;
    }

    // Merge saved state onto registry
    final merged = achievementRegistry.map((a) {
      final saved = savedMap[a.id];
      if (saved != null) {
        return Achievement.fromJsonOverlay(a, saved);
      }
      return a;
    }).toList();

    state = AchievementsState(
      allAchievements: merged,
      unlockedAchievements: merged.where((a) => a.isUnlocked).toList(),
      completedCollections: savedCollections,
    );
  }

  void _persist() {
    final persistence = ref.read(persistenceServiceProvider);
    final unlockedJsons = state.unlockedAchievements
        .map((a) => a.toJson())
        .toList();
    persistence.saveUnlockedAchievements(unlockedJsons);
    persistence.saveCompletedCollections(state.completedCollections);
  }

  void setTierFilter(AchievementTier? tier) {
    if (tier == state.filterTier) {
      state = state.copyWith(clearTierFilter: true);
    } else {
      state = state.copyWith(filterTier: tier);
    }
  }

  void setCollectionFilter(String? collectionId) {
    if (collectionId == state.filterCollection) {
      state = state.copyWith(clearCollectionFilter: true);
    } else {
      state = state.copyWith(filterCollection: collectionId);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  bool claimAchievement(String achievementId, {RetroactiveClaimData? retroactiveData}) {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return false;

    final achievement = state.allAchievements[index];
    if (achievement.isUnlocked) return false;

    final isRetroactive = retroactiveData != null;
    final claimDate = DateTime.now();

    final unlocked = achievement.copyWith(
      isUnlocked: true,
      unlockedAt: claimDate,
      visitDate: isRetroactive ? retroactiveData.visitDate : claimDate,
      photos: isRetroactive ? retroactiveData.photos : const [],
      notes: isRetroactive ? retroactiveData.notes : null,
      isRetroactive: isRetroactive,
    );

    final updatedAll = [...state.allAchievements];
    updatedAll[index] = unlocked;

    // Check for collection completion
    final collectionId = achievement.collectionId;
    var completedCollections = Set<String>.from(state.completedCollections);
    String? newlyCompletedCollection;

    if (collectionId != null && !completedCollections.contains(collectionId)) {
      final collectionAchievements =
          updatedAll.where((a) => a.collectionId == collectionId).toList();
      final allUnlocked = collectionAchievements.every((a) => a.isUnlocked);
      if (allUnlocked) {
        completedCollections.add(collectionId);
        newlyCompletedCollection = collectionId;
      }
    }

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: [...state.unlockedAchievements, unlocked],
      completedCollections: completedCollections,
    );

    // Award XP (slightly reduced for retroactive claims)
    final xpMultiplier = isRetroactive ? 0.8 : 1.0;
    final xpAwarded = (achievement.xpReward * xpMultiplier).round();
    ref.read(userProfileProvider.notifier).addXp(xpAwarded);

    // Award collection bonus XP if newly completed
    if (newlyCompletedCollection != null) {
      _lastCompletedCollection = newlyCompletedCollection;
      final bonusXp = _collectionBonusXp(newlyCompletedCollection);
      if (bonusXp > 0) {
        ref.read(userProfileProvider.notifier).addXp(bonusXp);
      }
    }

    _persist();
    return true;
  }

  /// Returns the newly completed collection ID if the last claim completed one, else null.
  String? get lastCompletedCollection => _lastCompletedCollection;
  String? _lastCompletedCollection;

  /// Call after showing the celebration dialog to clear.
  void clearLastCompletedCollection() {
    _lastCompletedCollection = null;
  }

  int _collectionBonusXp(String collectionId) {
    const bonuses = {
      'getting-started': 50,
      'cities': 75,
      'nature': 100,
      'food-drink': 75,
      'culture': 100,
      'photography': 75,
      'countries': 200,
      'water-sports': 100,
    };
    return bonuses[collectionId] ?? 50;
  }
}

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>(
  (ref) => AchievementsNotifier(ref),
);

// Placeholder registry — will be replaced with full data from React app
final achievementRegistry = <Achievement>[
  Achievement(
    id: 'first-steps',
    title: 'First Steps',
    description: 'Visit your first location',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 37.7749,
    longitude: -122.4194,
    claimRadius: 500,
    collectionId: 'getting-started',
    tags: ['starter'],
    isUnlocked: true,
    unlockedAt: DateTime(2025, 6, 15),
  ),
  Achievement(
    id: 'city-explorer',
    title: 'City Explorer',
    description: 'Visit 5 different cities',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 34.0522,
    longitude: -118.2437,
    claimRadius: 700,
    collectionId: 'cities',
    tags: ['cities', 'exploration'],
    isUnlocked: true,
  ),
  Achievement(
    id: 'foodie',
    title: 'Foodie',
    description: 'Try local cuisine in 3 countries',
    tier: AchievementTier.gold,
    xpReward: 35,
    collectionId: 'food-drink',
    tags: ['food', 'culture'],
    isUnlocked: true,
  ),
  Achievement(
    id: 'mountain-conqueror',
    title: 'Mountain Conqueror',
    description: 'Reach a summit above 3000m',
    tier: AchievementTier.platinum,
    xpReward: 50,
    latitude: 46.8523,
    longitude: -121.7603,
    claimRadius: 800,
    collectionId: 'nature',
    tags: ['hiking', 'extreme'],
  ),
  Achievement(
    id: 'night-owl',
    title: 'Night Owl',
    description: 'Complete a quest after midnight',
    tier: AchievementTier.bronze,
    xpReward: 10,
    collectionId: 'getting-started',
    tags: ['time-based'],
  ),
  Achievement(
    id: 'photographer',
    title: 'Photographer',
    description: 'Upload 10 travel photos',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 40.7128,
    longitude: -74.0060,
    claimRadius: 600,
    collectionId: 'photography',
    tags: ['photography', 'creative'],
  ),
  Achievement(
    id: 'globe-trotter',
    title: 'Globe Trotter',
    description: 'Visit 10 different countries',
    tier: AchievementTier.platinum,
    xpReward: 50,
    collectionId: 'countries',
    tags: ['countries', 'exploration'],
  ),
  Achievement(
    id: 'sunrise-chaser',
    title: 'Sunrise Chaser',
    description: 'Watch a sunrise from a mountain peak',
    tier: AchievementTier.gold,
    xpReward: 35,
    collectionId: 'nature',
    tags: ['nature', 'time-based'],
  ),
  Achievement(
    id: 'local-guide',
    title: 'Local Guide',
    description: 'Get a recommendation from a local resident',
    tier: AchievementTier.bronze,
    xpReward: 10,
    collectionId: 'culture',
    tags: ['culture', 'social'],
  ),
  Achievement(
    id: 'market-master',
    title: 'Market Master',
    description: 'Visit 5 local markets',
    tier: AchievementTier.silver,
    xpReward: 20,
    collectionId: 'food-drink',
    tags: ['food', 'shopping'],
  ),
  Achievement(
    id: 'deep-diver',
    title: 'Deep Diver',
    description: 'Go scuba diving or snorkeling',
    tier: AchievementTier.gold,
    xpReward: 35,
    collectionId: 'water-sports',
    tags: ['water', 'extreme'],
  ),
  Achievement(
    id: 'history-buff',
    title: 'History Buff',
    description: 'Visit 10 historical sites',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 51.5007,
    longitude: -0.1246,
    claimRadius: 700,
    collectionId: 'culture',
    tags: ['history', 'culture'],
  ),
  Achievement(
    id: 'polyglot',
    title: 'Polyglot',
    description: 'Learn a phrase in 5 different languages',
    tier: AchievementTier.gold,
    xpReward: 35,
    collectionId: 'culture',
    tags: ['language', 'culture'],
  ),
  Achievement(
    id: 'island-hopper',
    title: 'Island Hopper',
    description: 'Visit 3 different islands',
    tier: AchievementTier.silver,
    xpReward: 20,
    collectionId: 'nature',
    tags: ['islands', 'exploration'],
  ),
  Achievement(
    id: 'campfire-stories',
    title: 'Campfire Stories',
    description: 'Camp overnight in the wilderness',
    tier: AchievementTier.bronze,
    xpReward: 10,
    collectionId: 'nature',
    tags: ['camping', 'nature'],
  ),
];
