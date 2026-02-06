import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_buddy/shared/models/user_profile.dart';

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    // Auto-login with demo user for development
    _initDemoUser();
  }

  void _initDemoUser() {
    state = AuthState(
      user: UserProfile.demo,
      isAuthenticated: true,
    );
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    // TODO: Implement Supabase auth
    await Future.delayed(const Duration(milliseconds: 500));
    state = AuthState(
      user: UserProfile.demo,
      isAuthenticated: true,
    );
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true);
    // TODO: Implement Supabase auth
    await Future.delayed(const Duration(milliseconds: 500));
    state = AuthState(
      user: UserProfile.demo,
      isAuthenticated: true,
    );
  }

  void signOut() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
