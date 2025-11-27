import 'package:supabase_flutter/supabase_flutter.dart';
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
    String? firstname,
    String? lastname,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'firstName': firstname, 'lastName': lastname},
      );

      if (response.user == null) {
        throw Exception('Sign up failed');
      }
      if (password != confirmPassword) {
        throw Exception('Passwords do not match');
      }
      return AppUser(
        id: response.user!.id,
        email: response.user!.email!,
        firstName: firstname,
        lastName: lastname,
        createdAt: DateTime.parse(response.user!.createdAt),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred');
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

      if (response.user == null) {
        throw Exception('Sign in failed');
      }

      return AppUser(
        id: response.user!.id,
        email: response.user!.email!,
        firstName: response.user!.userMetadata?['firstName'] as String?,
        lastName: response.user!.userMetadata?['lastName'] as String?,
        createdAt: DateTime.parse(response.user!.createdAt),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }
}
