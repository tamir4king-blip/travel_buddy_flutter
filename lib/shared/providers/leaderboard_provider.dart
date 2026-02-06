import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimeRange { weekly, monthly, allTime }

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalXp;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.totalXp,
    required this.rank,
    this.isCurrentUser = false,
  });
}

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final TimeRange timeRange;
  final bool isLoading;
  final int totalParticipants;

  const LeaderboardState({
    this.entries = const [],
    this.timeRange = TimeRange.weekly,
    this.isLoading = false,
    this.totalParticipants = 0,
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
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      timeRange: timeRange ?? this.timeRange,
      isLoading: isLoading ?? this.isLoading,
      totalParticipants: totalParticipants ?? this.totalParticipants,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier() : super(const LeaderboardState()) {
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    // Mock data — will connect to Supabase materialized view
    state = LeaderboardState(
      entries: _mockEntries,
      totalParticipants: _mockEntries.length,
    );
  }

  void setTimeRange(TimeRange range) {
    state = state.copyWith(timeRange: range, isLoading: true);
    // TODO: Fetch from Supabase based on time range
    Future.delayed(const Duration(milliseconds: 300), () {
      state = state.copyWith(isLoading: false);
    });
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>(
  (ref) => LeaderboardNotifier(),
);

final _mockEntries = [
  LeaderboardEntry(userId: '1', displayName: 'Alex', totalXp: 3200, rank: 1),
  LeaderboardEntry(userId: '2', displayName: 'Sarah', totalXp: 2850, rank: 2),
  LeaderboardEntry(userId: '3', displayName: 'Mike', totalXp: 2400, rank: 3),
  LeaderboardEntry(userId: '4', displayName: 'Emma', totalXp: 2100, rank: 4),
  LeaderboardEntry(
    userId: 'demo-user-1', displayName: 'Jide', totalXp: 1250, rank: 5,
    isCurrentUser: true,
  ),
  LeaderboardEntry(userId: '6', displayName: 'Carlos', totalXp: 1180, rank: 6),
  LeaderboardEntry(userId: '7', displayName: 'Yuki', totalXp: 1050, rank: 7),
  LeaderboardEntry(userId: '8', displayName: 'Luna', totalXp: 980, rank: 8),
  LeaderboardEntry(userId: '9', displayName: 'David', totalXp: 870, rank: 9),
  LeaderboardEntry(userId: '10', displayName: 'Priya', totalXp: 750, rank: 10),
];
