import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/settings_item.dart';
import '../widgets/settings_section_header.dart';

/// Settings Screen
/// User settings and profile management screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = true;

  @override
  Widget build(BuildContext context) {
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
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundElevated,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.textSecondary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Name and Email
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'John Mayor',
                                    style: AppTextStyles.headlineSmall(context),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'john.mayor@exchange.com',
                                    style: AppTextStyles.bodyMedium(context),
                                  ),
                                  const SizedBox(height: 8),
                                  // Verified Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: AppColors.textPrimary,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified',
                                          style:
                                              AppTextStyles.labelSmall(
                                                context,
                                              ).copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
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
                        // Navigate to change password
                      },
                    ),
                    SettingsItem(
                      icon: Icons.security,
                      title: 'Two-Factor Authentication',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Enabled',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.success,
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
                        // Navigate to 2FA settings
                      },
                    ),
                    SettingsItem(
                      icon: Icons.fingerprint,
                      title: 'Biometric Login',
                      trailing: Switch(
                        value: _biometricEnabled,
                        onChanged: (value) {
                          setState(() {
                            _biometricEnabled = value;
                          });
                        },
                        activeThumbColor: AppColors.primaryOrange,
                      ),
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
                                style: AppTextStyles.titleSmall(context)
                                    .copyWith(
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
              // Handle logout logic here
            },
            child: Text(
              'Log Out',
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
