import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state_provider.dart';

// Auth controller - handles auth actions
// Auth controller - handles auth actions
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  // Sign up
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
  }) async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await authRepository.signUp(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        fullName: fullName,
      );
    });
  }

  // Verify signup
  Future<void> verifySignup({
    required String email,
    required String code,
  }) async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await authRepository.verifySignup(
        email: email,
        token: code,
      );
    });
  }

  // Sign in
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await authRepository.signIn(
        email: email,
        password: password,
      );
    });
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await authRepository.signInWithGoogle();
    });
  }

  // Sign out
  Future<void> signOut() async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await authRepository.signOut();
    });
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await authRepository.resetPassword(email);
    });
  }

  // Refresh session
  Future<void> refresh() async {
    // No-op or implementation if needed
  }
}

// Auth controller provider
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});
