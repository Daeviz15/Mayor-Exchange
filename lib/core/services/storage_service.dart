import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Storage Service
/// Handles file uploads to Supabase Storage
class StorageService {
  final SupabaseClient _supabaseClient;
  static const String _profileBucket = 'profile-images';

  StorageService(this._supabaseClient);

  /// Upload profile image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // Verify user is authenticated
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to upload images');
      }

      // Verify the userId matches the current user
      if (currentUser.id != userId) {
        throw Exception('Cannot upload image for another user');
      }

      // Generate unique filename: userId_timestamp.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/$timestamp.jpg';

      // Upload to Supabase Storage using file path
      await _supabaseClient.storage.from(_profileBucket).upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              upsert: true, // Replace if exists
              contentType: 'image/jpeg',
            ),
          );

      // Get public URL
      final publicUrl =
          _supabaseClient.storage.from(_profileBucket).getPublicUrl(fileName);

      return publicUrl;
    } on StorageException catch (e) {
      // Handle storage-specific errors
      if (e.statusCode == 403) {
        throw Exception(
          'Permission denied. Please ensure the storage bucket policies are configured correctly. '
          'See SUPABASE_STORAGE_SETUP.md for instructions.',
        );
      } else if (e.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else {
        throw Exception('Storage error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Delete profile image from Supabase Storage
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the bucket name and file path
      final bucketIndex = pathSegments.indexOf(_profileBucket);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        return; // Invalid URL, skip deletion
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await _supabaseClient.storage.from(_profileBucket).remove([filePath]);
    } catch (e) {
      // Silently fail - deletion is not critical
      debugPrint('Failed to delete profile image: $e');
    }
  }

  /// Get public URL for a profile image
  String getPublicUrl(String filePath) {
    return _supabaseClient.storage.from(_profileBucket).getPublicUrl(filePath);
  }
}

/// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageService(client);
});
