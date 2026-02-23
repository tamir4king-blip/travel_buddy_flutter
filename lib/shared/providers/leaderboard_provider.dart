import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy_mobile/core/config/supabase_config.dart';
import 'package:travel_buddy_mobile/shared/providers/leaderboard_service_provider.dart';
import 'package:travel_buddy_mobile/shared/providers/user_profile_provider.dart';

enum TimeRange { weekly, monthly, allTime }

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalXp;
  final int rank;
  final int level;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.totalXp,
    required this.rank,
    this.level = 1,
    this.isCurrentUser = false,
  });
}

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final TimeRange timeRange;
  final bool isLoading;
  final int totalParticipants;
  final String? errorMessage;
  final int? currentUserRank;

  const LeaderboardState({
    this.entries = const [],
    this.timeRange = TimeRange.weekly,
    this.isLoading = false,
    this.totalParticipants = 0,
    this.errorMessage,
    this.currentUserRank,
  });

  LeaderboardEntry? get currentUserEntry {
    try {
      return entries.firstWhere((e) => e.isCurrentUser);
    } catch (_) {
      return null;
    }
  }

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    TimeRange? timeRange,
    bool? isLoading,
    int? totalParticipants,
    String? errorMessage,
    bool clearError = false,
    int? currentUserRank,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      timeRange: timeRange ?? this.timeRange,
      isLoading: isLoading ?? this.isLoading,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentUserRank: currentUserRank ?? this.currentUserRank,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref ref;

  LeaderboardNotifier(this.ref) : super(const LeaderboardState()) {
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    state = state.copyWith(isLoading: true, clearError: true);

    if (SupabaseConfig.isConfigured) {
      await _loadFromSupabase();
    } else {
      // No Supabase connection — show empty leaderboard
      state = state.copyWith(
        isLoading: false,
        entries: const [],
        totalParticipants: 0,
        errorMessage: 'Leaderboard unavailable without server connection.',
      );
    }
  }

  Future<void> _loadFromSupabase() async {
    final service = ref.read(leaderboardServiceProvider);
    if (service == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final result = await service.fetchLeaderboard(limit: 50);

    if (result.error != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error,
      );
      return;
    }

    final userProfile = ref.read(userProfileProvider);
    final userRank = await service.fetchCurrentUserRank();

    // Map entries and check if current user is in the list
    var entries = <LeaderboardEntry>[];
    var foundCurrentUser = false;

    for (var i = 0; i < result.entries.length; i++) {
      final e = result.entries[i];
      final isCurrent = e.userId == userProfile.id;
      if (isCurrent) foundCurrentUser = true;

      entries.add(LeaderboardEntry(
        userId: e.userId,
        displayName: e.displayName,
        avatarUrl: e.avatarUrl,
        totalXp: e.totalXp,
        rank: i + 1,
        level: e.level,
        isCurrentUser: isCurrent,
      ));
    }

    // Always ensure the current user appears, even if not in the query results
    if (!foundCurrentUser) {
      entries.add(LeaderboardEntry(
        userId: userProfile.id,
        displayName: userProfile.displayName,
        avatarUrl: userProfile.avatarUrl,
        totalXp: userProfile.totalXp,
        rank: userRank ?? entries.length + 1,
        level: userProfile.level,
        isCurrentUser: true,
      ));
    }

    state = state.copyWith(
      entries: entries,
      totalParticipants:
          result.totalParticipants > 0 ? result.totalParticipants : entries.length,
      isLoading: false,
      currentUserRank: userRank ?? entries.length,
    );
  }

  void setTimeRange(TimeRange range) {
    state = state.copyWith(timeRange: range);
    // All time ranges return the same data for now.
    // Weekly/monthly filtering requires an xp_snapshots table.
    _loadLeaderboard();
  }

  Future<void> refresh() async {
    await _loadLeaderboard();
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>(
  (ref) => LeaderboardNotifier(ref),
);

