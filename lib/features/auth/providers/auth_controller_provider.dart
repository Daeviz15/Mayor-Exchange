import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../repositories/auth_repository.dart';
import 'auth_state_provider.dart';

// Auth controller - handles auth actions
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  // Sign up
  Future<void> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signUp(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        fullName: fullName,
      );
    });
  }

  // Sign in
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signIn(
        email: email,
        password: password,
      );
    });
  }

  // Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signOut();
    });
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.resetPassword(email);
    });
  }
}

// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthController(authRepo);
});