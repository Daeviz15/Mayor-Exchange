import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Sign up with email and password
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
  }) async {
    // Validate password match before making API call
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    // Validate password strength
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long');
    }

    // Basic email validation
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception('Please enter a valid email address');
    }

    try {
      final response = await _supabaseClient.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Sign up failed: No user returned from server');
      }

      // Even if email confirmation is required, the user is created
      // Return the user object so the UI can show appropriate message
      return AppUser(
        id: user.id,
        email: user.email ?? email.trim(),
        fullName: fullName.trim(),
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.parse(user.createdAt),
      );
    } on AuthException catch (e) {
      // Provide user-friendly error messages
      String errorMessage = e.message;
      if (e.message.contains('already registered')) {
        errorMessage =
            'An account with this email already exists. Please sign in instead.';
      } else if (e.message.contains('invalid')) {
        errorMessage = 'Invalid email or password. Please check your input.';
      } else if (e.message.contains('rate limit')) {
        errorMessage = 'Too many attempts. Please try again later.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Catch any other exceptions and provide a clear message
      throw Exception('Failed to create account: ${e.toString()}');
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

  // Sign in with Google OAuth
  Future<void> signInWithGoogle() async {
    try {
      // For mobile apps, use a custom URL scheme or let Supabase handle the default
      // The redirect URL should be configured in Supabase dashboard under:
      // Authentication > URL Configuration > Redirect URLs
      final redirectUrl = SupabaseConstants.effectiveRedirectUrl;

      await _supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      // Provide more specific error messages
      if (e.message.contains('provider is not enabled')) {
        throw Exception(
            'Google sign-in is not enabled in your Supabase project. Please enable it in Authentication > Providers.');
      }
      throw Exception(e.message);
    } catch (e) {
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

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('An unexpected error occurred while resetting password');
    }
  }

  // Update password
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
