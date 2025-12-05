import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/supabase_provider.dart';
import 'auth_providers.dart';
import '../models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Profile Avatar State
/// Manages both local cache and Supabase Storage URL
class ProfileAvatarState {
  final String? localPath; // Temporary local cache
  final String? storageUrl; // Supabase Storage URL (persistent)
  final bool isUploading;
  
  const ProfileAvatarState({
    this.localPath,
    this.storageUrl,
    this.isUploading = false,
  });

  ProfileAvatarState copyWith({
    String? localPath,
    String? storageUrl,
    bool? isUploading,
  }) =>
      ProfileAvatarState(
        localPath: localPath ?? this.localPath,
        storageUrl: storageUrl ?? this.storageUrl,
        isUploading: isUploading ?? this.isUploading,
      );
}

final profileAvatarProvider =
    NotifierProvider<ProfileAvatarNotifier, ProfileAvatarState>(
  ProfileAvatarNotifier.new,
);

class ProfileAvatarNotifier extends Notifier<ProfileAvatarState> {
  static const _prefKey = 'profile_avatar_storage_url';

  @override
  ProfileAvatarState build() {
    // Watch auth state changes to refresh avatar URL when user logs in
    ref.listen<AsyncValue<AppUser?>>(authControllerProvider, (_, next) {
      next.whenData((user) {
        if (user != null) {
          _loadAvatarUrl();
        } else {
          // User logged out, clear avatar
          state = const ProfileAvatarState();
        }
      });
    });
    
    // Load from user metadata and local prefs
    _loadAvatarUrl();
    return const ProfileAvatarState();
  }

  Future<void> _loadAvatarUrl() async {
    // First, try to get from current user metadata
    final authState = ref.read(authControllerProvider);
    final user = authState.value;
    
    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      state = state.copyWith(storageUrl: user.avatarUrl);
      // Also cache in SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, user.avatarUrl!);
      return;
    }

    // Fallback to SharedPreferences cache
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString(_prefKey);
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      state = state.copyWith(storageUrl: cachedUrl);
    }
  }

  /// Upload avatar to Supabase Storage and update user metadata
  Future<void> uploadAvatar(File file) async {
    try {
      state = state.copyWith(isUploading: true);

      final user = ref.read(supabaseClientProvider).auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Upload to Supabase Storage
      final storageService = ref.read(storageServiceProvider);
      final publicUrl = await storageService.uploadProfileImage(
        imageFile: file,
        userId: user.id,
      );

      // Update user metadata with avatar URL
      await ref.read(supabaseClientProvider).auth.updateUser(
        UserAttributes(
          data: {
            ...?user.userMetadata,
            'avatar_url': publicUrl,
          },
        ),
      );

      // Cache locally for immediate display
      final cacheDir = await getTemporaryDirectory();
      final targetPath =
          '${cacheDir.path}/profile_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await file.copy(targetPath);

      // Update state
      state = state.copyWith(
        localPath: targetPath,
        storageUrl: publicUrl,
        isUploading: false,
      );

      // Cache URL in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, publicUrl);

      // Refresh auth controller to update user data
      await ref.read(authControllerProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(isUploading: false);
      rethrow;
    }
  }

  /// Clear avatar (delete from storage and remove from metadata)
  Future<void> clear() async {
    try {
      final user = ref.read(supabaseClientProvider).auth.currentUser;
      
      // Delete from storage if URL exists
      if (state.storageUrl != null && user != null) {
        final storageService = ref.read(storageServiceProvider);
        await storageService.deleteProfileImage(state.storageUrl!);
      }

      // Remove from user metadata
      if (user != null) {
        await ref.read(supabaseClientProvider).auth.updateUser(
          UserAttributes(
            data: {
              ...?user.userMetadata,
              'avatar_url': null,
            },
          ),
        );
      }

      // Clear local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);

      state = const ProfileAvatarState();

      // Refresh auth controller
      await ref.read(authControllerProvider.notifier).refresh();
    } catch (e) {
      // Silently fail - clearing is not critical
      state = const ProfileAvatarState();
    }
  }
}

