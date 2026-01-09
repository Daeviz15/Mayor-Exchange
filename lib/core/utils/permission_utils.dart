import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';

class PermissionUtils {
  static bool _isRequesting = false;

  /// Request Camera Permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    return _requestPermission(
      context,
      Permission.camera,
      'Camera',
      'We need camera access to take photos for your profile or transaction proofs.',
    );
  }

  /// Request Gallery/Photos Permission
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    // On Android 13+ (SDK 33), use Permission.photos (READ_MEDIA_IMAGES).
    // On older Android, use Permission.storage (READ_EXTERNAL_STORAGE).
    // iOS uses Permission.photos.

    if (Platform.isAndroid) {
      if (_isRequesting) return false;
      _isRequesting = true;

      try {
        // First, check if already granted
        final storageStatus = await Permission.storage.status;
        final photosStatus = await Permission.photos.status;

        if (storageStatus.isGranted || photosStatus.isGranted) {
          return true;
        }

        // Try Permission.photos first (Android 13+)
        final photosResult = await Permission.photos.request();
        if (photosResult.isGranted) {
          return true;
        }

        // If photos permission is restricted/unavailable (older Android), try storage
        if (photosResult.isDenied || photosResult.isPermanentlyDenied) {
          final storageResult = await Permission.storage.request();
          if (storageResult.isGranted) {
            return true;
          }

          // Both denied - show settings dialog if permanently denied
          if (photosResult.isPermanentlyDenied ||
              storageResult.isPermanentlyDenied) {
            if (context.mounted) {
              _showSettingsDialog(
                context,
                'Photo Library',
                'We need access to your photo library to select images.',
              );
            }
            return false;
          }
        }

        // Simple denial - show retry snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Photo Library permission is required to select images.'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => requestGalleryPermission(context),
              ),
            ),
          );
        }
        return false;
      } finally {
        _isRequesting = false;
      }
    }

    // iOS and other platforms
    return _requestPermission(
      context,
      Permission.photos,
      'Photo Library',
      'We need access to your photo library to select images.',
    );
  }

  /// Internal handler for generic permission request flow
  static Future<bool> _requestPermission(
    BuildContext context,
    Permission permission,
    String featureName,
    String rationale,
  ) async {
    // 1. Check current status
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (_isRequesting) return false;
    _isRequesting = true;

    try {
      // 2. Request permission
      final result = await permission.request();

      if (result.isGranted) {
        return true;
      }

      // 3. Handle Permanent Denial (User selected "Don't ask again")
      if (result.isPermanentlyDenied) {
        if (context.mounted) {
          _showSettingsDialog(context, featureName, rationale);
        }
        return false;
      }

      // 4. Handle Simple Denial (User just clicked Deny)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$featureName permission is required. $rationale'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _requestPermission(
                  context, permission, featureName, rationale),
            ),
          ),
        );
      }

      return false;
    } finally {
      _isRequesting = false;
    }
  }

  static void _showSettingsDialog(
      BuildContext context, String featureName, String explanation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          '$featureName Permission Required',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '$explanation\n\nPlease enable it in the app settings.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
