import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/profile_avatar_provider.dart';
import '../../auth/models/app_user.dart';
import '../../kyc/providers/kyc_provider.dart';
import '../../../core/widgets/rocket_loader.dart';

class ProfileSettingsHeader extends ConsumerWidget {
  const ProfileSettingsHeader({super.key});

  Widget _buildAvatarImage({
    required ProfileAvatarState avatarState,
    required AppUser? user,
  }) {
    // Priority: Storage URL > Local Path > User Metadata URL
    final imageUrl = avatarState.storageUrl ??
        user?.avatarUrl ??
        (avatarState.localPath != null
            ? 'file://${avatarState.localPath}'
            : null);

    if (imageUrl == null) {
      return const Icon(
        Icons.person,
        color: AppColors.textSecondary,
        size: 32,
      );
    }

    if (imageUrl.startsWith('file://')) {
      // Local file
      final filePath = imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(filePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.person,
          color: AppColors.textSecondary,
          size: 32,
        ),
      );
    } else {
      // Network URL
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.backgroundElevated,
          child: const Center(
            child: RocketLoader(size: 20, color: AppColors.primaryOrange),
          ),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.person,
          color: AppColors.textSecondary,
          size: 32,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final avatarState = ref.watch(profileAvatarProvider);
    final user = authState.asData?.value;

    final displayName = (user?.fullName?.trim().isNotEmpty == true)
        ? user!.fullName!
        : (user?.email.split('@').first ?? 'User');

    final kycAsync = ref.watch(kycStatusProvider);

    return Row(
      children: [
        // Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.backgroundCardLight, width: 2),
          ),
          child: ClipOval(
            child: _buildAvatarImage(avatarState: avatarState, user: user),
          ),
        ),
        const SizedBox(width: 16),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: AppTextStyles.titleMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  kycAsync.when(
                    data: (kyc) {
                      Color badgeColor;
                      if (kyc?.status == 'verified') {
                        badgeColor = AppColors.success;
                      } else if (kyc?.status == 'in_progress') {
                        badgeColor = AppColors.primaryOrange;
                      } else {
                        // Pending, Rejected, or Null
                        badgeColor = AppColors.textTertiary;
                      }
                      return Icon(
                        Icons.check_circle,
                        color: badgeColor,
                        size: 16,
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
