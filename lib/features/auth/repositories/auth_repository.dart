import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/supabase_constants.dart';
import '../models/app_user.dart';

class AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepository(this._supabaseClient);

  // Get current user
  User? get currentUser => _supabaseClient.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  // Sign up with email and password (via Edge Function)
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
  }) async {
    // Validate password match
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    // Validate password strength
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long');
    }

    try {
      final response = await _supabaseClient.functions.invoke(
        'auth-actions',
        body: {
          'action': 'signup',
          'email': email.trim(),
          'password': password,
          'data': {
            'full_name': fullName.trim(),
          },
        },
      );

      final userData = response.data['user'];
      // Note: Edge function returns the user object structure from admin.createUser
      // We map it to AppUser.
      // If user is null, something wrong.

      if (userData == null) {
        throw Exception('Sign up failed: No user returned');
      }

      return AppUser(
        id: userData['id'],
        email: userData['email'] ?? email.trim(),
        fullName: fullName.trim(), // We know the name we sent
        avatarUrl: userData['user_metadata']?['avatar_url'],
        createdAt: DateTime.now(), // Approximate
      );
    } on FunctionException catch (e) {
      throw Exception(e.details ?? e.toString());
    } catch (e) {
      throw Exception('Failed to create account: ${e.toString()}');
    }
  }

  // Verify signup otp (via Edge Function)
  Future<void> verifySignup({
    required String email,
    required String token,
  }) async {
    try {
      await _supabaseClient.functions.invoke(
        'auth-actions',
        body: {
          'action': 'verify_signup',
          'email': email,
          'code': token,
        },
      );
    } on FunctionException catch (e) {
      throw Exception(e.details ?? e.toString());
    } catch (e) {
      throw Exception('Failed to verify code: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Sign in failed');
      }

      return AppUser(
        id: user.id,
        email: user.email ?? email,
        fullName: _deriveFullName(user.userMetadata),
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.parse(user.createdAt),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('An unexpected error occurred while signing in');
    }
  }

  // Sign in with Google (Native)
  Future<void> signInWithGoogle() async {
    try {
      final webClientId = SupabaseConstants.googleWebClientId;
      if (webClientId.isEmpty) {
        throw Exception(
            'Google Web Client ID not found. Please check your .env file.');
      }

      // Native Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;

      if (googleAuth == null) {
        throw Exception('Google sign in cancelled');
      }

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('No ID Token found');
      }

      await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        return; // User cancelled
      }
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('An unexpected error occurred while signing out');
    }
  }

  // Reset password (via Edge Function)
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.functions.invoke(
        'auth-actions',
        body: {'action': 'request_reset', 'email': email},
      );
    } on FunctionException catch (e) {
      throw Exception(e.details ?? e.toString()); // Handle Edge Function errors
    } catch (e) {
      throw Exception('Failed to send reset code: ${e.toString()}');
    }
  }

  // Update password (for logged-in users)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('An unexpected error occurred while updating password');
    }
  }

  // Update user profile
  Future<AppUser> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    String? country,
    String? currency,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (address != null) updates['address'] = address;
      if (country != null) updates['country'] = country;
      if (currency != null) updates['currency'] = currency;
      if (dateOfBirth != null) {
        updates['date_of_birth'] = dateOfBirth.toIso8601String();
      }

      final response = await _supabaseClient.auth.updateUser(
        UserAttributes(data: updates),
      );

      final user = response.user;
      if (user == null) throw Exception('Failed to update profile');

      return AppUser(
        id: user.id,
        email: user.email ?? '',
        fullName: _deriveFullName(user.userMetadata),
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        phoneNumber: user.userMetadata?['phone_number'] as String?,
        dateOfBirth: user.userMetadata?['date_of_birth'] != null
            ? DateTime.tryParse(user.userMetadata!['date_of_birth'] as String)
            : null,
        address: user.userMetadata?['address'] as String?,
        country: user.userMetadata?['country'] as String?,
        currency: user.userMetadata?['currency'] as String?,
        createdAt: DateTime.parse(user.createdAt),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Complete password reset (via Edge Function)
  Future<void> completePasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _supabaseClient.functions.invoke(
        'auth-actions',
        body: {
          'action': 'complete_reset',
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
    } on FunctionException catch (e) {
      throw Exception(e.details ?? e.toString());
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  // Verify otp for password recovery (via Edge Function)
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    try {
      await _supabaseClient.functions.invoke(
        'auth-actions',
        body: {
          'action': 'verify_code',
          'email': email,
          'code': token,
        },
      );
    } on FunctionException catch (e) {
      throw Exception(e.details ?? e.toString());
    } catch (e) {
      throw Exception('Failed to verify code: ${e.toString()}');
    }
  }

  String? _deriveFullName(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    final fullName = metadata['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) return fullName.trim();
    final name = metadata['name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final first = metadata['firstName'] as String?;
    final last = metadata['lastName'] as String?;
    if (first != null && last != null) return '$first $last'.trim();
    return first ?? last;
  }
}
