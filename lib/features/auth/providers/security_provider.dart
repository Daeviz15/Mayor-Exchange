import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'auth_providers.dart';

/// Security Settings State
class SecuritySettings {
  final bool biometricEnabled;
  final bool twoFactorEnabled;
  final String? twoFactorSecret;

  const SecuritySettings({
    this.biometricEnabled = false,
    this.twoFactorEnabled = false,
    this.twoFactorSecret,
  });

  SecuritySettings copyWith({
    bool? biometricEnabled,
    bool? twoFactorEnabled,
    String? twoFactorSecret,
  }) {
    return SecuritySettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      twoFactorSecret: twoFactorSecret ?? this.twoFactorSecret,
    );
  }
}

/// Security Settings Provider
final securitySettingsProvider =
    NotifierProvider<SecuritySettingsNotifier, SecuritySettings>(
  SecuritySettingsNotifier.new,
);

class SecuritySettingsNotifier extends Notifier<SecuritySettings> {
  static const String _biometricKey = 'biometric_enabled';
  static const String _twoFactorKey = 'two_factor_enabled';
  static const String _twoFactorSecretKey = 'two_factor_secret';

  @override
  SecuritySettings build() {
    _loadSettings();
    return const SecuritySettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SecuritySettings(
      biometricEnabled: prefs.getBool(_biometricKey) ?? false,
      twoFactorEnabled: prefs.getBool(_twoFactorKey) ?? false,
      twoFactorSecret: prefs.getString(_twoFactorSecretKey),
    );
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }

  Future<void> setTwoFactorEnabled(bool enabled, {String? secret}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_twoFactorKey, enabled);
    if (secret != null) {
      await prefs.setString(_twoFactorSecretKey, secret);
    }
    state = state.copyWith(
      twoFactorEnabled: enabled,
      twoFactorSecret: secret ?? state.twoFactorSecret,
    );
  }

  Future<void> disableTwoFactor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_twoFactorKey);
    await prefs.remove(_twoFactorSecretKey);
    state = state.copyWith(
      twoFactorEnabled: false,
      twoFactorSecret: null,
    );
  }
}

/// Biometric Auth Provider
final biometricAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

/// Change Password Provider
final changePasswordProvider =
    NotifierProvider<ChangePasswordNotifier, AsyncValue<void>>(
  ChangePasswordNotifier.new,
);

class ChangePasswordNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (newPassword != confirmPassword) {
        throw Exception('New passwords do not match');
      }

      if (newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }

      final authRepo = ref.read(authRepositoryProvider);
      
      // Get current user
      final user = authRepo.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Verify current password by attempting to sign in
      try {
        await authRepo.signIn(
          email: user.email ?? '',
          password: currentPassword,
        );
      } catch (e) {
        throw Exception('Current password is incorrect');
      }

      // Update password using Supabase
      await authRepo.updatePassword(newPassword);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

