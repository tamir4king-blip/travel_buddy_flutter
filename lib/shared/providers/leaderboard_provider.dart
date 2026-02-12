import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy/core/config/supabase_config.dart';
import 'package:travel_buddy/shared/providers/leaderboard_service_provider.dart';
import 'package:travel_buddy/shared/providers/user_profile_provider.dart';

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

    // In demo mode, listen to user profile changes so rank updates reactively
    if (!SupabaseConfig.isConfigured) {
      ref.listen(userProfileProvider, (prev, next) {
        if (prev?.totalXp != next.totalXp) {
          _loadLeaderboard();
        }
      });
    }
  }

  Future<void> _loadLeaderboard() async {
    state = state.copyWith(isLoading: true, clearError: true);

    if (SupabaseConfig.isConfigured) {
      await _loadFromSupabase();
    } else {
      _loadDemoData();
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

  void _loadDemoData() {
    final userProfile = ref.read(userProfileProvider);

    // Combine mock entries (without current user) with live user data
    final allEntries = <_RawEntry>[
      ..._mockEntries,
      _RawEntry(
        userId: userProfile.id,
        displayName: userProfile.displayName,
        avatarUrl: userProfile.avatarUrl,
        totalXp: userProfile.totalXp,
        level: userProfile.level,
        isCurrentUser: true,
      ),
    ];

    // Sort by XP descending
    allEntries.sort((a, b) => b.totalXp.compareTo(a.totalXp));

    // Assign ranks
    final entries = allEntries
        .asMap()
        .entries
        .map((e) => LeaderboardEntry(
              userId: e.value.userId,
              displayName: e.value.displayName,
              avatarUrl: e.value.avatarUrl,
              totalXp: e.value.totalXp,
              rank: e.key + 1,
              level: e.value.level,
              isCurrentUser: e.value.isCurrentUser,
            ))
        .toList();

    final userRank = entries
        .firstWhere((e) => e.isCurrentUser,
            orElse: () => entries.last)
        .rank;

    state = state.copyWith(
      entries: entries,
      totalParticipants: entries.length,
      isLoading: false,
      currentUserRank: userRank,
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

// Internal helper for sorting before rank assignment
class _RawEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalXp;
  final int level;
  final bool isCurrentUser;

  const _RawEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.totalXp,
    required this.level,
    this.isCurrentUser = false,
  });
}

const _mockEntries = [
  _RawEntry(userId: '1', displayName: 'Alex', totalXp: 3200, level: 8),
  _RawEntry(userId: '2', displayName: 'Sarah', totalXp: 2850, level: 7),
  _RawEntry(userId: '3', displayName: 'Mike', totalXp: 2400, level: 7),
  _RawEntry(userId: '4', displayName: 'Emma', totalXp: 2100, level: 6),
  _RawEntry(userId: '6', displayName: 'Carlos', totalXp: 1180, level: 5),
  _RawEntry(userId: '7', displayName: 'Yuki', totalXp: 1050, level: 4),
  _RawEntry(userId: '8', displayName: 'Luna', totalXp: 980, level: 4),
  _RawEntry(userId: '9', displayName: 'David', totalXp: 870, level: 3),
  _RawEntry(userId: '10', displayName: 'Priya', totalXp: 750, level: 3),
];
