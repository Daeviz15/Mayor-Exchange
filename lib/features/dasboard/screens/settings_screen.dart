import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/profile_avatar_provider.dart';
import '../../auth/providers/security_provider.dart';
import '../../auth/screens/change_password_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/two_factor_screen.dart';
import '../widgets/settings_item.dart';
import '../widgets/profile_settings_header.dart';
import '../../admin/providers/admin_role_provider.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import 'personal_details_screen.dart';
import '../../kyc/screens/kyc_verification_screen.dart';

/// Settings Screen
/// User settings and profile management screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSigningOut = false;

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
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() {});
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Back Button
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile Header
              const ProfileSettingsHeader(),

              const SizedBox(height: 16),

              // 2. My Profile Section
              _buildSectionHeader('My Profile'),

              // Admin Portal (Conditional)
              Consumer(
                builder: (context, ref, _) {
                  final isAdminAsync = ref.watch(isAdminProvider);
                  return isAdminAsync.when(
                    data: (isAdmin) {
                      if (isAdmin) {
                        return SettingsItem(
                          title: 'Admin Portal',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminDashboardScreen()),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    error: (_, __) => const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                  );
                },
              ),

              SettingsItem(
                title: 'Personal Details',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PersonalDetailsScreen()),
                ),
              ),
              SettingsItem(
                title: 'KYC Verification',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const KycVerificationScreen()),
                ),
              ),
              SettingsItem(
                title: 'Payment Methods',
                onTap: () {},
              ),

              // 3. Security Section
              _buildSectionHeader('Security'),
              SettingsItem(
                title: 'Reset Password',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                ),
              ),

              // 2FA Toggle
              Consumer(
                builder: (context, ref, _) {
                  final securitySettings = ref.watch(securitySettingsProvider);
                  return SettingsItem(
                    title: 'Two Factor Authentication',
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: securitySettings.twoFactorEnabled,
                        onChanged: (value) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TwoFactorScreen(),
                            ),
                          );
                        },
                        activeThumbColor: AppColors.backgroundCard,
                        activeTrackColor: AppColors.textTertiary,
                        inactiveThumbColor: AppColors.textTertiary,
                        inactiveTrackColor: AppColors.backgroundElevated,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TwoFactorScreen(),
                      ),
                    ),
                  );
                },
              ),

              // Biometric Toggle
              Consumer(
                builder: (context, ref, _) {
                  final securitySettings = ref.watch(securitySettingsProvider);
                  return SettingsItem(
                    title: 'Biometric Authentication',
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: securitySettings.biometricEnabled,
                        onChanged: (value) async {
                          if (value) {
                            // Check if biometric is available
                            final localAuth = ref.read(biometricAuthProvider);
                            final isAvailable =
                                await localAuth.canCheckBiometrics;
                            final isDeviceSupported =
                                await localAuth.isDeviceSupported();

                            if (!isAvailable || !isDeviceSupported) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Biometric authentication not available'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            // Authenticate
                            try {
                              final authenticated =
                                  await localAuth.authenticate(
                                localizedReason: 'Enable biometric login',
                                options: const AuthenticationOptions(
                                  biometricOnly: true,
                                  stickyAuth: true,
                                ),
                              );

                              if (authenticated) {
                                await ref
                                    .read(securitySettingsProvider.notifier)
                                    .setBiometricEnabled(true);
                              }
                            } catch (e) {
                              // Handle error
                            }
                          } else {
                            await ref
                                .read(securitySettingsProvider.notifier)
                                .setBiometricEnabled(false);
                          }
                        },
                        activeThumbColor: AppColors.primaryOrange,
                        activeTrackColor:
                            AppColors.primaryOrange.withValues(alpha: 0.3),
                        inactiveThumbColor: AppColors.textTertiary,
                        inactiveTrackColor: AppColors.backgroundElevated,
                      ),
                    ),
                  );
                },
              ),

              // 4. Account Setting Section
              _buildSectionHeader('Account Setting'),
              SettingsItem(
                title: 'Notifications',
                onTap: () {},
              ),
              SettingsItem(
                title: 'Theme',
                trailing: Row(
                  children: [
                    Text('Dark',
                        style: AppTextStyles.bodySmall(context)
                            .copyWith(color: AppColors.textTertiary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textTertiary, size: 20),
                  ],
                ),
                hasArrow: false, // Custom Arrow provided in trailing
                onTap: () {},
              ),
              SettingsItem(
                title: 'Currency',
                trailing: Row(
                  children: [
                    Text('USD',
                        style: AppTextStyles.bodySmall(context)
                            .copyWith(color: AppColors.textTertiary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textTertiary, size: 20),
                  ],
                ),
                hasArrow: false,
                onTap: () {},
              ),

              const SizedBox(height: 32),

              // Log Out Button (Text Only style as per design, or subtle button)
              // The design doesn't explicitly show the bottom, assuming a clean list.
              // But usually Settings has logout. I'll make it a clean red text item.
              Center(
                child: TextButton(
                  onPressed: () => _showLogoutDialog(context),
                  child: Text(
                    'Log Out',
                    style: AppTextStyles.titleSmall(context).copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout(context);
            },
            child:
                const Text('Log Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
