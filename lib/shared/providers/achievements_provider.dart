import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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

  bool claimAchievement(String achievementId, {RetroactiveClaimData? retroactiveData, double? userLat, double? userLng}) {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return false;

    final achievement = state.allAchievements[index];
    if (achievement.isUnlocked) return false;

    final isRetroactive = retroactiveData != null;

    // Location-gated validation for achievements with coordinates
    // Skip for retroactive claims (they have date-based validation)
    if (!isRetroactive &&
        achievement.latitude != null &&
        achievement.longitude != null &&
        achievement.claimRadius != null &&
        userLat != null &&
        userLng != null) {
      final distance = Geolocator.distanceBetween(
        userLat, userLng, achievement.latitude!, achievement.longitude!,
      );
      if (distance > achievement.claimRadius!) return false;
    }

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

  // ── Dev Panel Methods ──────────────────────────────────────────────────────

  void forceUnlock(String id) {
    final index = state.allAchievements.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final achievement = state.allAchievements[index];
    if (achievement.isUnlocked) return;

    final unlocked = achievement.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
    final updatedAll = [...state.allAchievements];
    updatedAll[index] = unlocked;

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: [...state.unlockedAchievements, unlocked],
    );
    ref.read(userProfileProvider.notifier).addXp(achievement.xpReward);
    _persist();
  }

  void forceLock(String id) {
    final index = state.allAchievements.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final achievement = state.allAchievements[index];
    if (!achievement.isUnlocked) return;

    final locked = achievement.copyWith(
      isUnlocked: false,
      unlockedAt: null,
    );
    final updatedAll = [...state.allAchievements];
    updatedAll[index] = locked;

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements:
          state.unlockedAchievements.where((a) => a.id != id).toList(),
    );
    _persist();
  }

  void unlockAll() {
    final now = DateTime.now();
    final updatedAll = state.allAchievements.map((a) {
      if (a.isUnlocked) return a;
      return a.copyWith(isUnlocked: true, unlockedAt: now);
    }).toList();

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: updatedAll.where((a) => a.isUnlocked).toList(),
    );
    _persist();
  }

  void lockAll() {
    final updatedAll = state.allAchievements.map((a) {
      if (!a.isUnlocked) return a;
      return a.copyWith(isUnlocked: false, unlockedAt: null);
    }).toList();

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: [],
      completedCollections: {},
    );
    _persist();
  }

  void updateAchievementRadius(String id, double newRadius) {
    final index = state.allAchievements.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final updated = state.allAchievements[index].copyWith(claimRadius: newRadius);
    final updatedAll = [...state.allAchievements];
    updatedAll[index] = updated;

    // Also update in unlocked list if present
    final unlockedIndex = state.unlockedAchievements.indexWhere((a) => a.id == id);
    final updatedUnlocked = [...state.unlockedAchievements];
    if (unlockedIndex != -1) {
      updatedUnlocked[unlockedIndex] = updated;
    }

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: updatedUnlocked,
    );
    _persist();
  }

  int _collectionBonusXp(String collectionId) {
    const bonuses = {
      'beaches': 75,
      'landmarks': 100,
      'parks': 100,
      'culture': 75,
    };
    return bonuses[collectionId] ?? 50;
  }
}

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>(
  (ref) => AchievementsNotifier(ref),
);

// Netanya location-based achievements registry
final achievementRegistry = <Achievement>[
  // ── Landmarks ──
  Achievement(
    id: 'tayelet-netanya',
    title: 'The Netanya Promenade',
    description: 'Walk along the famous clifftop promenade overlooking the Mediterranean',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.3282,
    longitude: 34.8485,
    claimRadius: 300,
    collectionId: 'landmarks',
    tags: ['landmarks', 'coastal'],
  ),
  Achievement(
    id: 'kikar-haatzmaut',
    title: 'Independence Square',
    description: 'Visit the vibrant heart of Netanya at Independence Square',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.3290,
    longitude: 34.8555,
    claimRadius: 200,
    collectionId: 'landmarks',
    tags: ['landmarks', 'city-center'],
  ),
  Achievement(
    id: 'glass-elevator',
    title: 'The Glass Elevator',
    description: 'Ride the panoramic glass elevator connecting the cliff to the beach',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3275,
    longitude: 34.8487,
    claimRadius: 150,
    collectionId: 'landmarks',
    tags: ['landmarks', 'scenic'],
  ),
  Achievement(
    id: 'wingate-institute',
    title: 'Wingate Institute',
    description: 'Visit Israel\'s national center for physical education and sport',
    tier: AchievementTier.platinum,
    xpReward: 50,
    latitude: 32.2780,
    longitude: 34.8530,
    claimRadius: 400,
    collectionId: 'landmarks',
    tags: ['landmarks', 'sports'],
  ),
  // ── Beaches ──
  Achievement(
    id: 'sironit-beach',
    title: 'Sironit Beach',
    description: 'Enjoy the popular Sironit Beach with its golden sands',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.3340,
    longitude: 34.8470,
    claimRadius: 300,
    collectionId: 'beaches',
    tags: ['beaches', 'swimming'],
  ),
  Achievement(
    id: 'herzl-beach',
    title: 'Herzl Beach',
    description: 'Relax at Herzl Beach, one of Netanya\'s most beloved shores',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.3245,
    longitude: 34.8475,
    claimRadius: 300,
    collectionId: 'beaches',
    tags: ['beaches', 'swimming'],
  ),
  Achievement(
    id: 'poleg-beach',
    title: 'Poleg Beach',
    description: 'Discover the scenic Poleg Beach at the southern edge of Netanya',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.2950,
    longitude: 34.8420,
    claimRadius: 400,
    collectionId: 'beaches',
    tags: ['beaches', 'nature'],
  ),
  Achievement(
    id: 'blue-bay',
    title: 'Blue Bay Beach',
    description: 'Visit the beautiful Blue Bay Beach and its turquoise waters',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3140,
    longitude: 34.8430,
    claimRadius: 300,
    collectionId: 'beaches',
    tags: ['beaches', 'resort'],
  ),
  // ── Parks ──
  Achievement(
    id: 'nahal-alexander',
    title: 'Alexander Stream Nature Reserve',
    description: 'Explore the Alexander Stream where sea turtles nest',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 32.3740,
    longitude: 34.8640,
    claimRadius: 500,
    collectionId: 'parks',
    tags: ['parks', 'nature', 'wildlife'],
  ),
  Achievement(
    id: 'gan-hamelech',
    title: 'King\'s Garden & Amphitheatre',
    description: 'Stroll through the King\'s Garden and its open-air amphitheatre',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3290,
    longitude: 34.8500,
    claimRadius: 200,
    collectionId: 'parks',
    tags: ['parks', 'culture'],
  ),
  Achievement(
    id: 'utman-park',
    title: 'Utman Garden Park',
    description: 'Relax in the peaceful Utman Garden Park',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.3200,
    longitude: 34.8600,
    claimRadius: 250,
    collectionId: 'parks',
    tags: ['parks', 'relaxation'],
  ),
  Achievement(
    id: 'ir-yamim',
    title: 'Ir Yamim Park',
    description: 'Explore the expansive Ir Yamim Park in south Netanya',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 32.2870,
    longitude: 34.8480,
    claimRadius: 350,
    collectionId: 'parks',
    tags: ['parks', 'recreation'],
  ),
  // ── North Netanya — Landmarks ──
  Achievement(
    id: 'umm-khalid-fortress',
    title: 'Umm Khalid Fortress',
    description: 'Explore the ancient Crusader fortress ruins overlooking the northern coastline',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 32.3520,
    longitude: 34.8490,
    claimRadius: 250,
    collectionId: 'landmarks',
    tags: ['landmarks', 'history', 'ruins'],
  ),
  Achievement(
    id: 'north-promenade-lookout',
    title: 'North Cliff Lookout',
    description: 'Take in the panoramic sea view from the northern promenade lookout point',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3430,
    longitude: 34.8475,
    claimRadius: 200,
    collectionId: 'landmarks',
    tags: ['landmarks', 'scenic', 'coastal'],
  ),
  // ── North Netanya — Beaches ──
  Achievement(
    id: 'argaman-beach',
    title: 'Argaman Beach',
    description: 'Discover the quiet Argaman Beach in northern Netanya, perfect for sunset walks',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3460,
    longitude: 34.8460,
    claimRadius: 300,
    collectionId: 'beaches',
    tags: ['beaches', 'quiet', 'sunset'],
  ),
  Achievement(
    id: 'tzofit-beach',
    title: 'Tzofit Beach',
    description: 'Visit the scenic Tzofit Beach nestled beneath the northern cliffs',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.3390,
    longitude: 34.8465,
    claimRadius: 300,
    collectionId: 'beaches',
    tags: ['beaches', 'cliffs', 'nature'],
  ),
  // ── North Netanya — Parks ──
  Achievement(
    id: 'park-raanana-junction',
    title: 'Arison Park North',
    description: 'Stroll through the green Arison Park on the northern edge of Netanya',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.3500,
    longitude: 34.8580,
    claimRadius: 300,
    collectionId: 'parks',
    tags: ['parks', 'nature', 'walking'],
  ),
  // ── North Netanya — Culture ──
  Achievement(
    id: 'well-museum',
    title: 'The Well House Museum',
    description: 'Visit the historic Well House Museum documenting the founding of Netanya',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 32.3380,
    longitude: 34.8560,
    claimRadius: 200,
    collectionId: 'culture',
    tags: ['culture', 'history', 'museum'],
  ),
  // ── Culture ──
  Achievement(
    id: 'netanya-market',
    title: 'The Netanya Market',
    description: 'Browse the bustling Netanya Market for fresh produce and local flavors',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 32.3310,
    longitude: 34.8570,
    claimRadius: 200,
    collectionId: 'culture',
    tags: ['culture', 'food', 'shopping'],
  ),
  Achievement(
    id: 'beit-haedut',
    title: 'Beit HaEdut Museum',
    description: 'Discover the history of immigration at the Beit HaEdut Museum',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 32.3290,
    longitude: 34.8545,
    claimRadius: 150,
    collectionId: 'culture',
    tags: ['culture', 'history', 'museum'],
  ),
  Achievement(
    id: 'hasharon-mall',
    title: 'HaSharon Mall',
    description: 'Visit the HaSharon Mall, a major shopping and entertainment hub',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3170,
    longitude: 34.8640,
    claimRadius: 300,
    collectionId: 'culture',
    tags: ['culture', 'shopping', 'entertainment'],
  ),
];
