import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Image utility functions for compression and optimization.
/// Centralizes image processing to ensure consistent compression across the app.
class ImageUtils {
  /// Compresses an image file to reduce upload size and bandwidth.
  ///
  /// Returns the compressed file, or the original file if compression fails.
  ///
  /// [file] - The original image file to compress
  /// [quality] - Compression quality (1-100), default 70
  /// [maxWidth] - Maximum width in pixels, default 1024
  /// [maxHeight] - Maximum height in pixels, default 1024
  static Future<File> compressImage(
    File file, {
    int quality = 70,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      // Return compressed file if successful, otherwise return original
      return result != null ? File(result.path) : file;
    } catch (e) {
      // On any error, return the original file
      return file;
    }
  }

  /// Compresses an image for proof uploads (transaction proofs, gift card images).
  /// Uses moderate compression settings optimized for document/proof images.
  static Future<File> compressProofImage(File file) async {
    return compressImage(file, quality: 75, maxWidth: 1280, maxHeight: 1280);
  }

  /// Compresses an image for avatar/profile uploads.
  /// Uses smaller dimensions suitable for profile pictures.
  static Future<File> compressAvatarImage(File file) async {
    return compressImage(file, quality: 70, maxWidth: 400, maxHeight: 400);
  }
}
