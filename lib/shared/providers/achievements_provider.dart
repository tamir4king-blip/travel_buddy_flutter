import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/shared/models/achievement.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/supabase_provider.dart';
import 'package:travel_buddy_mobile/shared/data/travel_achievement_registry.dart';
import 'package:travel_buddy_mobile/shared/data/collection_registry.dart';

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
    // Sync from Supabase in background after local load
    _syncFromRemote();
  }

  void _loadAchievements() {
    try {
      final persistence = ref.read(persistenceServiceProvider);
      final savedAchievements = persistence.loadUnlockedAchievements();
      final savedCollections = persistence.loadCompletedCollections();
      final pendingClaims = persistence.loadPendingClaims();

      // Build a map of saved data by id
      final savedMap = <String, Map<String, dynamic>>{};
      for (final json in savedAchievements) {
        final id = json['id'] as String?;
        if (id != null) savedMap[id] = json;
      }

      // Merge saved state onto registry
      final merged = achievementRegistry.map((a) {
        var achievement = a;
        final saved = savedMap[a.id];
        if (saved != null) {
          achievement = Achievement.fromJsonOverlay(a, saved);
        }
        // Restore pending claim state
        final pendingAt = pendingClaims[a.id];
        if (pendingAt != null && !achievement.isUnlocked) {
          achievement = achievement.copyWith(
            isPendingClaim: true,
            pendingClaimAt: DateTime.parse(pendingAt),
          );
        }
        return achievement;
      }).toList();

      state = AchievementsState(
        allAchievements: merged,
        unlockedAchievements: merged.where((a) => a.isUnlocked).toList(),
        completedCollections: savedCollections,
      );
    } catch (_) {
      // If persistence data is corrupted, load fresh from registry
      state = AchievementsState(
        allAchievements: achievementRegistry,
        unlockedAchievements: const [],
        completedCollections: const {},
      );
    }
  }

  /// Fetches unlocked achievements from Supabase and merges with local state.
  /// Remote achievements that aren't in local state are added (e.g. from another device).
  /// Local achievements that aren't in remote are synced up.
  Future<void> _syncFromRemote() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final rows = await client
          .from('user_achievements')
          .select()
          .eq('user_id', userId);

      if (rows.isEmpty) {
        // No remote data — push local unlocked achievements to Supabase
        _syncAllToRemote();
        return;
      }

      // Build a map of remote unlocked achievements by achievement_id
      final remoteMap = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final id = row['achievement_id'] as String?;
        if (id != null) remoteMap[id] = row;
      }

      // Merge: if remote has an achievement unlocked that local doesn't, unlock it locally
      var changed = false;
      final updatedAll = [...state.allAchievements];
      final updatedUnlocked = [...state.unlockedAchievements];

      for (var i = 0; i < updatedAll.length; i++) {
        final a = updatedAll[i];
        final remote = remoteMap[a.id];
        if (remote != null && !a.isUnlocked) {
          // Remote says unlocked but local doesn't — restore it
          updatedAll[i] = a.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.tryParse(remote['unlocked_at'] as String? ?? ''),
            visitDate: remote['visit_date'] != null
                ? DateTime.tryParse(remote['visit_date'] as String)
                : null,
            notes: remote['notes'] as String?,
            isRetroactive: remote['is_retroactive'] as bool? ?? false,
            photos: (remote['photos'] as List<dynamic>?)?.cast<String>() ?? const [],
          );
          updatedUnlocked.add(updatedAll[i]);
          changed = true;
        }
      }

      if (changed) {
        // Recompute completed collections by checking all distinct collection IDs
        final completedCollections = <String>{...state.completedCollections};
        final allCollectionIds = updatedAll
            .map((a) => a.collectionId)
            .whereType<String>()
            .toSet();
        for (final collectionId in allCollectionIds) {
          if (!completedCollections.contains(collectionId)) {
            final all = updatedAll.where((a) => a.collectionId == collectionId);
            if (all.isNotEmpty && all.every((a) => a.isUnlocked)) {
              completedCollections.add(collectionId);
            }
          }
        }

        state = state.copyWith(
          allAchievements: updatedAll,
          unlockedAchievements: updatedUnlocked,
          completedCollections: completedCollections,
        );
        await _persistLocally();
      }

      // Push any locally-unlocked achievements that aren't in remote
      _syncMissingToRemote(remoteMap);
    } catch (_) {
      // Silently fail — local data is primary
    }
  }

  /// Push all locally unlocked achievements to Supabase.
  Future<void> _syncAllToRemote() async {
    for (final a in state.unlockedAchievements) {
      await _upsertAchievementToRemote(a);
    }
  }

  /// Push locally-unlocked achievements missing from remote.
  Future<void> _syncMissingToRemote(Map<String, Map<String, dynamic>> remoteMap) async {
    for (final a in state.unlockedAchievements) {
      if (!remoteMap.containsKey(a.id)) {
        await _upsertAchievementToRemote(a);
      }
    }
  }

  /// Upsert a single achievement to the user_achievements table.
  Future<void> _upsertAchievementToRemote(Achievement a) async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('user_achievements').upsert({
        'user_id': userId,
        'achievement_id': a.id,
        'unlocked_at': a.unlockedAt?.toIso8601String(),
        'visit_date': a.visitDate?.toIso8601String(),
        'notes': a.notes,
        'is_retroactive': a.isRetroactive,
        'photos': a.photos,
      }, onConflict: 'user_id,achievement_id');
    } catch (_) {
      // Silently fail — will retry on next sync
    }
  }

  /// Save to local persistence only (no remote sync).
  Future<void> _persistLocally() async {
    final persistence = ref.read(persistenceServiceProvider);
    final unlockedJsons = state.unlockedAchievements
        .map((a) => a.toJson())
        .toList();
    await persistence.saveUnlockedAchievements(unlockedJsons);
    await persistence.saveCompletedCollections(state.completedCollections);

    final pendingClaims = <String, String>{};
    for (final a in state.allAchievements) {
      if (a.isPendingClaim && !a.isUnlocked && a.pendingClaimAt != null) {
        pendingClaims[a.id] = a.pendingClaimAt!.toIso8601String();
      }
    }
    await persistence.savePendingClaims(pendingClaims);
  }

  /// Persists locally and optionally syncs a specific achievement to Supabase.
  Future<void> _persist({Achievement? syncToRemote}) async {
    await _persistLocally();

    if (syncToRemote != null && syncToRemote.isUnlocked) {
      _upsertAchievementToRemote(syncToRemote);
    }
  }

  /// Mark an achievement as pending claim (detected nearby via background tracking).
  /// Returns true if newly marked as pending.
  Future<bool> markPendingClaim(String achievementId) async {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return false;

    final achievement = state.allAchievements[index];
    if (achievement.isUnlocked || achievement.isPendingClaim) return false;

    final pending = achievement.copyWith(
      isPendingClaim: true,
      pendingClaimAt: DateTime.now(),
    );

    final updatedAll = [...state.allAchievements];
    updatedAll[index] = pending;

    state = state.copyWith(allAchievements: updatedAll);
    await _persist();
    return true;
  }

  /// Confirm a pending claim — fully unlock the achievement.
  Future<bool> confirmPendingClaim(String achievementId) async {
    final index =
        state.allAchievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return false;

    final achievement = state.allAchievements[index];
    if (achievement.isUnlocked) return false;

    final unlocked = achievement.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
      isPendingClaim: false,
      clearPendingClaimAt: true,
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

    // Award XP
    ref.read(userProfileProvider.notifier).addXp(achievement.xpReward);

    // Award collection bonus XP if newly completed
    if (newlyCompletedCollection != null) {
      _lastCompletedCollection = newlyCompletedCollection;
      final bonusXp = _collectionBonusXp(newlyCompletedCollection);
      if (bonusXp > 0) {
        ref.read(userProfileProvider.notifier).addXp(bonusXp);
      }
    }

    await _persist(syncToRemote: unlocked);
    return true;
  }

  /// Reload pending claims from SharedPreferences (e.g. after the background
  /// service has written new entries while the app was suspended).
  Future<void> refreshFromStorage() async {
    final persistence = ref.read(persistenceServiceProvider);
    await persistence.reload();

    final pendingClaims = persistence.loadPendingClaims();
    if (pendingClaims.isEmpty) return;

    var changed = false;
    final updatedAll = [...state.allAchievements];

    for (var i = 0; i < updatedAll.length; i++) {
      final a = updatedAll[i];
      final pendingAt = pendingClaims[a.id];
      if (pendingAt != null && !a.isUnlocked && !a.isPendingClaim) {
        updatedAll[i] = a.copyWith(
          isPendingClaim: true,
          pendingClaimAt: DateTime.parse(pendingAt),
        );
        changed = true;
      }
    }

    if (changed) {
      state = state.copyWith(allAchievements: updatedAll);
    }
  }

  /// Get all achievements with pending claims.
  List<Achievement> get pendingClaims =>
      state.allAchievements.where((a) => a.isPendingClaim && !a.isUnlocked).toList();

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

  Future<bool> claimAchievement(String achievementId, {RetroactiveClaimData? retroactiveData, double? userLat, double? userLng}) async {
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

    await _persist(syncToRemote: unlocked);
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

  Future<void> forceUnlock(String id) async {
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
    await _persist(syncToRemote: unlocked);
  }

  Future<void> forceLock(String id) async {
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
    await _persist();
  }

  Future<void> unlockAll() async {
    final now = DateTime.now();
    final updatedAll = state.allAchievements.map((a) {
      if (a.isUnlocked) return a;
      return a.copyWith(isUnlocked: true, unlockedAt: now);
    }).toList();

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: updatedAll.where((a) => a.isUnlocked).toList(),
    );
    await _persist();
  }

  Future<void> lockAll() async {
    final updatedAll = state.allAchievements.map((a) {
      if (!a.isUnlocked) return a;
      return a.copyWith(isUnlocked: false, unlockedAt: null);
    }).toList();

    state = state.copyWith(
      allAchievements: updatedAll,
      unlockedAchievements: [],
      completedCollections: {},
    );
    await _persist();
  }

  Future<void> updateAchievementRadius(String id, double newRadius) async {
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
    await _persist();
  }

  int _collectionBonusXp(String collectionId) {
    final info = getCollectionInfo(collectionId);
    return info?.bonusXp ?? 50;
  }
}

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>(
  (ref) => AchievementsNotifier(ref),
);

// Combined achievement registry: local Netanya + travel achievements
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
  // ── More Landmarks ──
  Achievement(
    id: 'netanya-stadium',
    title: 'Netanya Stadium',
    description: 'Visit the home of Maccabi Netanya FC and its surrounding sports complex',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3100,
    longitude: 34.8620,
    claimRadius: 300,
    collectionId: 'landmarks',
    tags: ['landmarks', 'sports'],
  ),
  Achievement(
    id: 'seasons-lookout',
    title: 'Seasons Cliff Lookout',
    description: 'Take in the breathtaking view from the lookout near the Seasons Hotel',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3268,
    longitude: 34.8478,
    claimRadius: 150,
    collectionId: 'landmarks',
    tags: ['landmarks', 'scenic', 'coastal'],
  ),
  Achievement(
    id: 'founders-monument',
    title: 'Founders Monument',
    description: 'Visit the monument commemorating the founders of Netanya',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.3285,
    longitude: 34.8540,
    claimRadius: 150,
    collectionId: 'landmarks',
    tags: ['landmarks', 'history'],
  ),
  Achievement(
    id: 'old-train-station',
    title: 'Old Netanya Train Station',
    description: 'Discover the historic train station and its surrounding area',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3260,
    longitude: 34.8590,
    claimRadius: 200,
    collectionId: 'landmarks',
    tags: ['landmarks', 'history', 'transportation'],
  ),
  // ── More Beaches ──
  Achievement(
    id: 'kontiki-beach',
    title: 'Kontiki Beach',
    description: 'Relax at the charming Kontiki Beach with its laid-back atmosphere',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.3210,
    longitude: 34.8460,
    claimRadius: 300,
    collectionId: 'beaches',
    tags: ['beaches', 'relaxation'],
  ),
  Achievement(
    id: 'haonot-beach',
    title: 'HaOnot Beach',
    description: 'Visit HaOnot Beach tucked between the dramatic cliff inlets',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.3350,
    longitude: 34.8468,
    claimRadius: 250,
    collectionId: 'beaches',
    tags: ['beaches', 'cliffs', 'scenic'],
  ),
  Achievement(
    id: 'beit-yanai',
    title: 'Beit Yanai Beach',
    description: 'Discover the scenic Beit Yanai Beach at the Alexander Stream estuary',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 32.3890,
    longitude: 34.8580,
    claimRadius: 400,
    collectionId: 'beaches',
    tags: ['beaches', 'nature', 'river'],
  ),
  Achievement(
    id: 'mikhmoret-beach',
    title: 'Mikhmoret Beach',
    description: 'Explore the unspoiled Mikhmoret Beach north of Netanya',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3950,
    longitude: 34.8520,
    claimRadius: 400,
    collectionId: 'beaches',
    tags: ['beaches', 'quiet', 'nature'],
  ),
  // ── More Parks ──
  Achievement(
    id: 'poleg-reserve',
    title: 'Poleg Stream Nature Reserve',
    description: 'Hike through the lush Poleg Stream nature reserve and its wetlands',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 32.2900,
    longitude: 34.8450,
    claimRadius: 400,
    collectionId: 'parks',
    tags: ['parks', 'nature', 'hiking', 'wildlife'],
  ),
  Achievement(
    id: 'ramat-poleg-park',
    title: 'Ramat Poleg Park',
    description: 'Enjoy the open green spaces and playgrounds of Ramat Poleg',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.2920,
    longitude: 34.8520,
    claimRadius: 300,
    collectionId: 'parks',
    tags: ['parks', 'recreation', 'family'],
  ),
  Achievement(
    id: 'iris-reserve',
    title: 'Iris Nature Reserve',
    description: 'Visit the rare coastal iris reserve, home to endangered Iris atropurpurea',
    tier: AchievementTier.platinum,
    xpReward: 50,
    latitude: 32.3050,
    longitude: 34.8650,
    claimRadius: 350,
    collectionId: 'parks',
    tags: ['parks', 'nature', 'wildlife', 'rare'],
  ),
  // ── More Culture ──
  Achievement(
    id: 'netanya-gallery',
    title: 'Netanya Municipal Gallery',
    description: 'Browse contemporary art exhibitions at the municipal gallery',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3295,
    longitude: 34.8548,
    claimRadius: 150,
    collectionId: 'culture',
    tags: ['culture', 'art', 'museum'],
  ),
  Achievement(
    id: 'cliff-sculptures',
    title: 'Cliff-top Sculpture Garden',
    description: 'Walk among the open-air sculptures along the cliff promenade',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3260,
    longitude: 34.8490,
    claimRadius: 250,
    collectionId: 'culture',
    tags: ['culture', 'art', 'outdoor'],
  ),
  Achievement(
    id: 'diamond-center',
    title: 'Diamond Industry Center',
    description: 'Learn about Netanya\'s historic diamond polishing industry',
    tier: AchievementTier.gold,
    xpReward: 35,
    latitude: 32.3180,
    longitude: 34.8580,
    claimRadius: 250,
    collectionId: 'culture',
    tags: ['culture', 'history', 'industry'],
  ),
  Achievement(
    id: 'havatzelet',
    title: 'Havatzelet HaSharon',
    description: 'Explore the historic Havatzelet HaSharon village, one of the oldest settlements in the Sharon plain',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3600,
    longitude: 34.8530,
    claimRadius: 300,
    collectionId: 'culture',
    tags: ['culture', 'history', 'village'],
  ),
  Achievement(
    id: 'bialik-street',
    title: 'Bialik Cultural Street',
    description: 'Stroll down Bialik Street with its cafes, shops, and cultural vibe',
    tier: AchievementTier.bronze,
    xpReward: 10,
    latitude: 32.3300,
    longitude: 34.8555,
    claimRadius: 200,
    collectionId: 'culture',
    tags: ['culture', 'shopping', 'food'],
  ),
  Achievement(
    id: 'uranus-bar',
    title: 'Uranus Bar',
    description: 'Grab a drink at the legendary Uranus Pub on Independence Square, a Netanya icon since the 1980s',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.3303,
    longitude: 34.8514,
    claimRadius: 100,
    collectionId: 'culture',
    tags: ['culture', 'nightlife', 'bar'],
  ),
  Achievement(
    id: 'hansel-and-gretel',
    title: 'Hansel & Gretel',
    description: 'Enjoy craft beers at the Hansel & Gretel beer garden in south Netanya',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.2787,
    longitude: 34.8639,
    claimRadius: 100,
    collectionId: 'culture',
    tags: ['culture', 'nightlife', 'bar'],
  ),
  Achievement(
    id: 'beer-shop',
    title: 'Beer Shop',
    description: 'Browse over 900 beers at the legendary Beer Shop on Ha-Bonim Street',
    tier: AchievementTier.silver,
    xpReward: 20,
    latitude: 32.2808,
    longitude: 34.8618,
    claimRadius: 100,
    collectionId: 'culture',
    tags: ['culture', 'nightlife', 'bar'],
  ),
  // ── Travel Achievements ──
  ...travelAchievementRegistry,
];
