import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the Supabase client instance to the app.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provides the current Supabase auth state as a stream.
final supabaseAuthStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// Provides the currently signed-in Supabase user (or null).
final supabaseUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser;
});
