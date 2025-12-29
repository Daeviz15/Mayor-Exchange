import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';

class PermissionUtils {
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
    // Android 13+ (SDK 33) uses READ_MEDIA_IMAGES for photos
    Permission permission = Permission.photos;

    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      final photosStatus = await Permission.photos.status;

      // 1. Check if either is already granted
      if (storageStatus.isGranted || photosStatus.isGranted) {
        return true;
      }

      // 2. Select permission based on OS behavior
      // On Android 13+ (SDK 33), storage is 'permanentlyDenied' (disabled).
      // On Android < 13, storage is 'denied' (requestable).
      if (!storageStatus.isPermanentlyDenied) {
        permission = Permission.storage;
      } else {
        permission = Permission.photos;
      }
    }

    return _requestPermission(
      context,
      permission,
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

    // 2. Request permission
    // Sometimes we might want to show rationale BEFORE requesting if needed,
    // but standard flow is Request -> If Denied -> Rationale -> Settings.

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
    // We could show a snackbar or rationale here if we want to be very persistent,
    // but usually we respect the first denial and maybe show a hint.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$featureName permission is required. $rationale'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () =>
                _requestPermission(context, permission, featureName, rationale),
          ),
        ),
      );
    }

    return false;
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
