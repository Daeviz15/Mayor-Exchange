import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayor_exchange/core/providers/supabase_provider.dart';
import 'package:mayor_exchange/core/services/cache_service.dart';
import 'package:mayor_exchange/features/auth/models/app_user.dart';
import 'package:mayor_exchange/features/auth/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides a single instance of [AuthRepository] wired to the shared Supabase client.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return AuthRepository(client);
});

/// Exposes the current [User] from Supabase, or null if not authenticated.
final authUserProvider = Provider<User?>((ref) {
  final client = ref.read(supabaseClientProvider);
  return client.auth.currentUser;
});

/// Stream of auth state changes, useful for reacting to log in / log out.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.read(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// Simple async notifier that exposes the last authenticated [AppUser].
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    // Listen to auth state changes and refresh when auth changes
    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((authState) {
        final session = authState.session;
        final event = authState.event;
        
        if (session != null &&
            (event == AuthChangeEvent.signedIn ||
                event == AuthChangeEvent.tokenRefreshed ||
                event == AuthChangeEvent.userUpdated)) {
          // Refresh the user data when auth state changes
          _refreshUser();
        } else if (event == AuthChangeEvent.signedOut) {
          state = const AsyncData(null);
        }
      });
    });

    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentUser;

    if (user == null) return null;

    return _mapUser(user);
  }

  Future<void> _refreshUser() async {
    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentUser;
    
    if (user == null) {
      state = const AsyncData(null);
      return;
    }

    state = AsyncData(_mapUser(user));
  }

  /// Public method to refresh user data
  Future<void> refresh() async {
    await _refreshUser();
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signIn(email: email, password: password);
      state = AsyncData(user);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      rethrow; // Re-throw so UI can handle it
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signUp(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        fullName: fullName,
      );
      state = AsyncData(user);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      rethrow; // Re-throw so UI can handle it
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    await repo.signInWithGoogle();
    // Don't set state here - wait for auth state change listener to handle it
    // The authStateChangesProvider listener will refresh the user when OAuth completes
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    
    // Clear all cached data on signout
    await _clearCache();
    
    state = const AsyncData(null);
  }

  Future<void> _clearCache() async {
    try {
      await CacheService.clearAll();
    } catch (e) {
      // Silently fail - cache clearing is not critical
    }
  }

  AppUser _mapUser(User user) {
    final metadata = user.userMetadata ?? <String, dynamic>{};
    String? fullName;
    if (metadata['full_name'] is String && metadata['full_name'].toString().trim().isNotEmpty) {
      fullName = metadata['full_name'] as String?;
    } else if (metadata['name'] is String && metadata['name'].toString().trim().isNotEmpty) {
      fullName = metadata['name'] as String?;
    } else {
      final first = metadata['firstName'] as String?;
      final last = metadata['lastName'] as String?;
      final parts = [first, last]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        fullName = parts.join(' ');
      }
    }

    final avatarUrl = metadata['avatar_url'] as String?;

    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: fullName?.trim().isEmpty == true ? null : fullName?.trim(),
      avatarUrl: avatarUrl,
      createdAt: DateTime.parse(user.createdAt),
    );
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);


