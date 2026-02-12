import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy/core/config/supabase_config.dart';
import 'package:travel_buddy/shared/providers/supabase_provider.dart';
import 'package:travel_buddy/shared/services/profile_sync_service.dart';

/// Provides a [ProfileSyncService] when Supabase is configured, otherwise null.
final profileSyncServiceProvider = Provider<ProfileSyncService?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  final client = ref.watch(supabaseClientProvider);
  return ProfileSyncService(client);
});
