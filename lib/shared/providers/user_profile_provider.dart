import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/shared/models/user_profile.dart';
import 'package:travel_buddy_mobile/shared/providers/auth_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/persistence_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/profile_sync_provider.dart';

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final Ref ref;

  UserProfileNotifier(this.ref, UserProfile initial) : super(initial) {
    _loadFromPersistence();
    _loadFromRemote();
  }

  void _loadFromPersistence() {
    final persistence = ref.read(persistenceServiceProvider);
    final saved = persistence.loadUserProfile();
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> _loadFromRemote() async {
    try {
      final syncService = ref.read(profileSyncServiceProvider);
      if (syncService == null) return;

      final remote = await syncService.loadProfileFromRemote();
      if (remote == null) return;

      // Merge: remote wins for text fields, higher value wins for XP/level
      state = state.copyWith(
        displayName: remote.displayName,
        username: remote.username,
        bio: remote.bio,
        avatarUrl: remote.avatarUrl,
        totalXp: remote.totalXp > state.totalXp ? remote.totalXp : null,
        level: remote.level > state.level ? remote.level : null,
        isPublic: remote.isPublic,
        isPremium: remote.isPremium,
      );
      _persistLocally();
    } catch (_) {
      // Silently fail — local persistence is primary
    }
  }

  void _persistLocally() {
    final persistence = ref.read(persistenceServiceProvider);
    persistence.saveUserProfile(state);
  }

  void _persist() {
    _persistLocally();
    _syncToRemote();
  }

  Future<void> _syncToRemote() async {
    try {
      final syncService = ref.read(profileSyncServiceProvider);
      if (syncService == null) return;
      // Fire-and-forget
      syncService.syncProfileToRemote(state);
    } catch (_) {
      // Silently fail
    }
  }

  void addXp(int amount) {
    final newXp = state.totalXp + amount;
    final newLevel = _calculateLevel(newXp);
    state = state.copyWith(totalXp: newXp, level: newLevel);
    _persist();
  }

  void updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    bool? isPublic,
  }) {
    state = state.copyWith(
      displayName: displayName,
      username: username,
      bio: bio,
      avatarUrl: avatarUrl,
      isPublic: isPublic,
    );
    _persist();
  }

  static int _calculateLevel(int totalXp) {
    if (totalXp < 100) return 1;
    if (totalXp < 250) return 2;
    if (totalXp < 500) return 3;
    if (totalXp < 850) return 4;
    if (totalXp < 1300) return 5;
    if (totalXp < 1850) return 6;
    if (totalXp < 2500) return 7;
    if (totalXp < 3300) return 8;
    if (totalXp < 4250) return 9;
    if (totalXp < 5400) return 10;
    return 10 + ((totalXp - 5400) ~/ 1500);
  }

  static int xpForLevel(int level) {
    const thresholds = [0, 100, 250, 500, 850, 1300, 1850, 2500, 3300, 4250, 5400];
    if (level <= 10) return thresholds[level];
    return 5400 + (level - 10) * 1500;
  }

  static int xpToNextLevel(int totalXp, int currentLevel) {
    final nextLevelXp = xpForLevel(currentLevel + 1);
    return nextLevelXp - totalXp;
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final authState = ref.watch(authProvider);
  return UserProfileNotifier(ref, authState.user ?? UserProfile.demo);
});
