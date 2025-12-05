import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/profile_avatar_provider.dart';
import '../../auth/models/app_user.dart';
import '../../auth/providers/security_provider.dart';
import '../../auth/screens/change_password_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/two_factor_screen.dart';
import '../widgets/settings_item.dart';
import '../widgets/settings_section_header.dart';

/// Settings Screen
/// User settings and profile management screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSigningOut = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Compress image to reduce upload size
      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 70,
        minWidth: 400,
        minHeight: 400,
      );

      final fileToSave = File(compressed?.path ?? picked.path);

      // Upload to Supabase Storage
      await ref.read(profileAvatarProvider.notifier).uploadAvatar(fileToSave);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    setState(() => _isSigningOut = true);
    try {
      // Sign out and clear all data
      await ref.read(authControllerProvider.notifier).signOut();
      await ref.read(profileAvatarProvider.notifier).clear();

      if (!mounted) return;

      // Navigate to login screen immediately, clearing all routes
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      // If navigation fails, try alternative approach
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

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
      // Network URL (Supabase Storage)
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        memCacheWidth: 128,
        memCacheHeight: 128,
        maxWidthDiskCache: 300,
        maxHeightDiskCache: 300,
        placeholder: (context, url) => Container(
          color: AppColors.backgroundElevated,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
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
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final avatarState = ref.watch(profileAvatarProvider);
    final user = authState.asData?.value;
    final displayName = (user?.fullName?.trim().isNotEmpty == true)
        ? user!.fullName!
        : (user?.email.split('@').first ?? 'User');
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Settings',
                        style: AppTextStyles.titleLarge(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance for back button
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Profile Section
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            GestureDetector(
                              onTap:
                                  avatarState.isUploading ? null : _pickAvatar,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundElevated,
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: _buildAvatarImage(
                                        avatarState: avatarState,
                                        user: user,
                                      ),
                                    ),
                                  ),
                                  if (avatarState.isUploading)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Name and Email
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: AppTextStyles.headlineSmall(context),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? '',
                                    style: AppTextStyles.bodyMedium(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Account Section
                    const SettingsSectionHeader(title: 'Account'),
                    SettingsItem(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      onTap: () {
                        // Navigate to personal information
                      },
                    ),
                    SettingsItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Verification Center',
                      onTap: () {
                        // Navigate to verification center
                      },
                    ),
                    SettingsItem(
                      icon: Icons.account_balance_outlined,
                      title: 'Payment Methods',
                      onTap: () {
                        // Navigate to payment methods
                      },
                    ),
                    SettingsItem(
                      icon: Icons.history,
                      title: 'Transaction History',
                      onTap: () {
                        // Navigate to transaction history
                      },
                    ),

                    const SizedBox(height: 8),

                    // Security Section
                    const SettingsSectionHeader(title: 'Security'),
                    SettingsItem(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final securitySettings =
                            ref.watch(securitySettingsProvider);
                        return SettingsItem(
                          icon: Icons.security,
                          title: 'Two-Factor Authentication',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                securitySettings.twoFactorEnabled
                                    ? 'Enabled'
                                    : 'Disabled',
                                style:
                                    AppTextStyles.bodySmall(context).copyWith(
                                  color: securitySettings.twoFactorEnabled
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TwoFactorScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final securitySettings =
                            ref.watch(securitySettingsProvider);
                        return SettingsItem(
                          icon: Icons.fingerprint,
                          title: 'Biometric Login',
                          trailing: Switch(
                            value: securitySettings.biometricEnabled,
                            onChanged: (value) async {
                              if (value) {
                                // Check if biometric is available
                                final localAuth =
                                    ref.read(biometricAuthProvider);
                                final isAvailable =
                                    await localAuth.canCheckBiometrics;
                                final isDeviceSupported =
                                    await localAuth.isDeviceSupported();

                                if (!isAvailable || !isDeviceSupported) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Biometric authentication is not available on this device',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // Authenticate with biometric
                                try {
                                  final authenticated =
                                      await localAuth.authenticate(
                                    localizedReason:
                                        'Enable biometric login for Mayor Exchange',
                                    options: const AuthenticationOptions(
                                      biometricOnly: true,
                                      stickyAuth: true,
                                    ),
                                  );

                                  if (authenticated) {
                                    await ref
                                        .read(securitySettingsProvider.notifier)
                                        .setBiometricEnabled(true);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Biometric login enabled successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  String errorMessage =
                                      'Biometric authentication failed';
                                  if (e
                                      .toString()
                                      .contains('no_fragment_activity')) {
                                    errorMessage =
                                        'Please restart the app to enable biometric authentication';
                                  } else if (e
                                      .toString()
                                      .contains('NotAvailable')) {
                                    errorMessage =
                                        'Biometric authentication is not available';
                                  } else if (e
                                      .toString()
                                      .contains('NotEnrolled')) {
                                    errorMessage =
                                        'Please set up biometric authentication in your device settings';
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } else {
                                await ref
                                    .read(securitySettingsProvider.notifier)
                                    .setBiometricEnabled(false);
                              }
                            },
                            activeThumbColor: AppColors.primaryOrange,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // App Settings Section
                    const SettingsSectionHeader(title: 'App Settings'),
                    SettingsItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () {
                        // Navigate to notifications settings
                      },
                    ),
                    SettingsItem(
                      icon: Icons.dark_mode_outlined,
                      title: 'Theme',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Dark', style: AppTextStyles.bodySmall(context)),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textTertiary,
                            size: 20,
                          ),
                        ],
                      ),
                      onTap: () {
                        // Navigate to theme settings
                      },
                    ),
                    SettingsItem(
                      icon: Icons.attach_money,
                      title: 'Currency',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('USD', style: AppTextStyles.bodySmall(context)),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textTertiary,
                            size: 20,
                          ),
                        ],
                      ),
                      onTap: () {
                        // Navigate to currency settings
                      },
                    ),

                    const SizedBox(height: 32),

                    // Log Out Button
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          // Handle logout
                          _showLogoutDialog(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Log Out',
                                style:
                                    AppTextStyles.titleSmall(context).copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out', style: AppTextStyles.titleLarge(context)),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTextStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.titleSmall(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout(context);
            },
            child: Text(
              _isSigningOut ? 'Signing Out...' : 'Log Out',
              style: AppTextStyles.titleSmall(
                context,
              ).copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
