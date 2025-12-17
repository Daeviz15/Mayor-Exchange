import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state_provider.dart';

class ForgotPasswordController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is null (void)
    return;
  }

  Future<void> sendResetCode(String email) async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => authRepository.resetPassword(email));
  }

  Future<void> verifyCode(String email, String code) async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => authRepository.verifyRecoveryOtp(email: email, token: code));
  }

  Future<void> completeReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => authRepository.completePasswordReset(
          email: email,
          code: code,
          newPassword: newPassword,
        ));
  }
}

final forgotPasswordControllerProvider =
    AsyncNotifierProvider<ForgotPasswordController, void>(() {
  return ForgotPasswordController();
});
