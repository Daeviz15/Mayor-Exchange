import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../Widgets/formWdiget.dart';
import '../../../Widgets/buttonWidget.dart';
import '../providers/security_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref.read(changePasswordProvider.notifier).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(changePasswordProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Change Password',
          style: AppTextStyles.titleLarge(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            FormWidget(
              controller: _currentPasswordController,
              hintText: 'Enter current password',
              labelText: 'Current Password',
              icon: const Icon(Icons.lock),
              obscureText: true,
              hidePasswordIcon: const Icon(Icons.visibility_off),
            ),
            const SizedBox(height: 20),
            FormWidget(
              controller: _newPasswordController,
              hintText: 'Enter new password',
              labelText: 'New Password',
              icon: const Icon(Icons.lock_outline),
              obscureText: true,
              hidePasswordIcon: const Icon(Icons.visibility_off),
            ),
            const SizedBox(height: 20),
            FormWidget(
              controller: _confirmPasswordController,
              hintText: 'Confirm new password',
              labelText: 'Confirm New Password',
              icon: const Icon(Icons.lock_outline),
              obscureText: true,
              hidePasswordIcon: const Icon(Icons.visibility_off),
            ),
            const SizedBox(height: 30),
            Buttonwidget(
              signText: isLoading ? 'Changing Password...' : 'Change Password',
              onPressed: isLoading ? null : _handleChangePassword,
            ),
          ],
        ),
      ),
    );
  }
}

