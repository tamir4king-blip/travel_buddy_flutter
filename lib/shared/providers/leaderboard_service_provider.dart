import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy/core/config/supabase_config.dart';
import 'package:travel_buddy/shared/providers/supabase_provider.dart';
import 'package:travel_buddy/shared/services/leaderboard_service.dart';

/// Provides a [LeaderboardService] when Supabase is configured, otherwise null.
final leaderboardServiceProvider = Provider<LeaderboardService?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  final client = ref.watch(supabaseClientProvider);
  return LeaderboardService(client);
});
