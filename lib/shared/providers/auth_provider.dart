import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:travel_buddy/core/config/supabase_config.dart';
import 'package:travel_buddy/shared/models/user_profile.dart';

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  StreamSubscription<sb.AuthState>? _authSubscription;

  AuthNotifier() : super(const AuthState()) {
    if (SupabaseConfig.isConfigured) {
      _initSupabaseAuth();
    } else {
      // Fallback to demo user when Supabase is not configured
      _initDemoUser();
    }
  }

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  void _initDemoUser() {
    state = AuthState(
      user: UserProfile.demo,
      isAuthenticated: true,
    );
  }

  void _initSupabaseAuth() {
    // Check if there's already a signed-in session
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      state = AuthState(
        user: _userProfileFromSupabase(currentUser),
        isAuthenticated: true,
      );
    }

    // Listen for auth state changes (sign in, sign out, token refresh)
    _authSubscription = _client.auth.onAuthStateChange.listen((authState) {
      final user = authState.session?.user;
      if (user != null) {
        state = AuthState(
          user: _userProfileFromSupabase(user),
          isAuthenticated: true,
        );
      } else {
        state = const AuthState();
      }
    });
  }

  UserProfile _userProfileFromSupabase(sb.User user) {
    final meta = user.userMetadata;
    return UserProfile(
      id: user.id,
      displayName: meta?['display_name'] as String? ??
          user.email?.split('@').first ??
          'Traveler',
      username: meta?['username'] as String?,
      bio: meta?['bio'] as String?,
      avatarUrl: meta?['avatar_url'] as String?,
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  Future<void> signIn(String email, String password) async {
    if (!SupabaseConfig.isConfigured) {
      _initDemoUser();
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Auth state listener will update the state
    } on sb.AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  Future<void> signUp(
      String email, String password, String displayName) async {
    if (!SupabaseConfig.isConfigured) {
      _initDemoUser();
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      // Auth state listener will update the state
    } on sb.AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      await _client.auth.signOut();
    }
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
