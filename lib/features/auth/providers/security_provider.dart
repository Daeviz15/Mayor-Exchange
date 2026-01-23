import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'auth_providers.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/utils/security_utils.dart';

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

  // Create secure storage instance
  final _secureStorage = const FlutterSecureStorage();

  @override
  SecuritySettings build() {
    _loadSettings();
    return const SecuritySettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final twoFactorSecret = await _secureStorage.read(key: _twoFactorSecretKey);

    state = SecuritySettings(
      biometricEnabled: prefs.getBool(_biometricKey) ?? false,
      twoFactorEnabled: prefs.getBool(_twoFactorKey) ?? false,
      twoFactorSecret: twoFactorSecret,
    );
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }

  String _generateRecoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid ambiguous chars
    final rnd = math.Random();
    return List.generate(10, (index) => chars[rnd.nextInt(chars.length)])
        .join();
  }

  Future<List<String>> generateAndStoreRecoveryCodes() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final codes = List.generate(8, (_) => _generateRecoveryCode());

    // In a real app, we'd hash these before storing.
    // For this implementation, we'll store them as they are or with a simple placeholder hash logic
    // since we want the user to be able to see them once.

    final inserts = codes
        .map((code) => {
              'user_id': user.id,
              'code_hash': SecurityUtils.hashString(code.toUpperCase()),
              'created_at': DateTime.now().toIso8601String(),
            })
        .toList();

    await supabase.from('user_2fa_recovery_codes').insert(inserts);

    return codes;
  }

  Future<void> setTwoFactorEnabled(bool enabled, {String? secret}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_twoFactorKey, enabled);

    if (secret != null) {
      await _secureStorage.write(key: _twoFactorSecretKey, value: secret);
    } else if (!enabled) {
      // If disabling, also clear from secure storage
      await _secureStorage.delete(key: _twoFactorSecretKey);
    }

    // Update Supabase user metadata and private secrets table
    try {
      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Sync metadata
        await supabase.auth.updateUser(
          UserAttributes(
            data: {
              'two_factor_enabled': enabled,
            },
          ),
        );

        // Sync to private table
        if (enabled && secret != null) {
          await supabase.from('user_2fa_secrets').upsert({
            'user_id': user.id,
            'secret': secret,
            'enabled': true,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } else if (!enabled) {
          await supabase
              .from('user_2fa_secrets')
              .delete()
              .eq('user_id', user.id);
          await supabase
              .from('user_2fa_recovery_codes')
              .delete()
              .eq('user_id', user.id);
        }
      }
    } catch (e) {
      debugPrint('Failed to sync 2FA status to Supabase: $e');
    }

    state = state.copyWith(
      twoFactorEnabled: enabled,
      twoFactorSecret: secret ?? state.twoFactorSecret,
    );
  }

  Future<void> disableTwoFactor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_twoFactorKey);
    await _secureStorage.delete(key: _twoFactorSecretKey);

    // Update Supabase user metadata if logged in
    try {
      final supabase = ref.read(supabaseClientProvider);
      if (supabase.auth.currentUser != null) {
        await supabase.auth.updateUser(
          UserAttributes(
            data: {
              'two_factor_enabled': false,
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to sync 2FA status to Supabase: $e');
    }

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

/// Last Logged In User State
/// Stores the last logged-in user's credentials for biometric login
class LastLoggedInUser {
  final String email;
  final String? avatarUrl;
  final String? displayName;

  const LastLoggedInUser({
    required this.email,
    this.avatarUrl,
    this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'avatar_url': avatarUrl,
        'display_name': displayName,
      };

  factory LastLoggedInUser.fromJson(Map<String, dynamic> json) {
    return LastLoggedInUser(
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      displayName: json['display_name'] as String?,
    );
  }
}

/// Last Logged In User Provider
final lastLoggedInUserProvider =
    NotifierProvider<LastLoggedInUserNotifier, LastLoggedInUser?>(
  LastLoggedInUserNotifier.new,
);

class LastLoggedInUserNotifier extends Notifier<LastLoggedInUser?> {
  static const String _emailKey = 'last_logged_in_email';
  static const String _avatarKey = 'last_logged_in_avatar';
  static const String _displayNameKey = 'last_logged_in_display_name';
  // Removed _passwordKey for security - biometrics will now rely on secure session persistence

  // Create secure storage instance
  final _secureStorage = const FlutterSecureStorage();

  @override
  LastLoggedInUser? build() {
    _loadUser();
    return null;
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    if (email != null) {
      state = LastLoggedInUser(
        email: email,
        avatarUrl: prefs.getString(_avatarKey),
        displayName: prefs.getString(_displayNameKey),
      );
    }
  }

  Future<void> setUser({
    required String email,
    String? avatarUrl,
    String? displayName,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    if (avatarUrl != null) {
      await prefs.setString(_avatarKey, avatarUrl);
    }
    if (displayName != null) {
      await prefs.setString(_displayNameKey, displayName);
    }

    // Removed password storage for security

    state = LastLoggedInUser(
      email: email,
      avatarUrl: avatarUrl,
      displayName: displayName,
    );
  }

  // No longer storing passwords

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_avatarKey);
    await prefs.remove(_displayNameKey);
    // Removed password deletion since it's no longer stored
    state = null;
  }
}

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
