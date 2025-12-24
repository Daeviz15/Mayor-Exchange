import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../notifications/widgets/notification_badge.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final String? displayName;
  final String? email;
  final String? localAvatarPath;
  final String? networkAvatarUrl;

  const DashboardHeader({
    super.key,
    this.onNotificationTap,
    this.onAvatarTap,
    this.displayName,
    this.email,
    this.localAvatarPath,
    this.networkAvatarUrl,
  });

  Widget _buildAvatarContent({
    String? localAvatarPath,
    String? networkAvatarUrl,
  }) {
    // Priority: Storage URL > Local Path
    final imageUrl = networkAvatarUrl ??
        (localAvatarPath != null ? 'file://$localAvatarPath' : null);

    if (imageUrl == null) {
      return const Icon(
        Icons.person,
        color: Colors.white,
        size: 24,
      );
    }

    if (imageUrl.startsWith('file://')) {
      // Local file
      final filePath = imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(filePath),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.person,
          color: Colors.white,
          size: 24,
        ),
      );
    } else {
      // Network URL (Supabase Storage)
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          memCacheWidth: 80,
          memCacheHeight: 80,
          maxWidthDiskCache: 200,
          maxHeightDiskCache: 200,
          placeholder: (context, url) => Container(
            color: AppColors.avatarBackground,
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.avatarBackground,
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onAvatarTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.avatarBackground,
                        shape: BoxShape.circle,
                        image: localAvatarPath != null
                            ? DecorationImage(
                                image: FileImage(
                                  File(localAvatarPath!),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _buildAvatarContent(
                        localAvatarPath: localAvatarPath,
                        networkAvatarUrl: networkAvatarUrl,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back ${displayName?.split(' ').first ?? 'User'}',
                          style: AppTextStyles.titleMedium(context).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            NotificationBadge(
              onTap: onNotificationTap ?? () {},
            ),
          ],
        ),
      ),
    );
  }
}
