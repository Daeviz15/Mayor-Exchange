import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../Widgets/buttonWidget.dart';
import '../providers/security_provider.dart';
import '../providers/auth_providers.dart';
import 'verify_2fa_screen.dart';

class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  String? _secret;
  String? _qrCodeData;

  @override
  void initState() {
    super.initState();
    _generateSecret();
  }

  void _generateSecret() {
    // Generate a Base32 secret (required by Google Authenticator and others)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random();
    final secret =
        List.generate(16, (index) => chars[random.nextInt(chars.length)])
            .join();

    final user = ref.read(authControllerProvider).value;
    final email = user?.email ?? 'user@example.com';

    // TOTP URI format: otpauth://totp/Issuer:AccountName?secret=SECRET&issuer=Issuer
    final qrData =
        'otpauth://totp/Mayor%20Exchange:$email?secret=$secret&issuer=Mayor%20Exchange';

    setState(() {
      _secret = secret;
      _qrCodeData = qrData;
    });
  }

  void _enable2FA() {
    if (_secret == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Verify2FAScreen(secret: _secret!),
      ),
    );
  }

  Future<void> _disable2FA() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Disable 2FA?', style: AppTextStyles.titleLarge(context)),
        content: Text(
          'Are you sure you want to disable Two-Factor Authentication? This will make your account less secure.',
          style: AppTextStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: AppTextStyles.titleSmall(context)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Disable',
              style: AppTextStyles.titleSmall(context).copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(securitySettingsProvider.notifier).disableTwoFactor();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-Factor Authentication disabled'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disable 2FA: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final securitySettings = ref.watch(securitySettingsProvider);
    final isEnabled = securitySettings.twoFactorEnabled;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Two-Factor Authentication',
          style: AppTextStyles.titleLarge(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isEnabled) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Two-Factor Authentication is enabled',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Buttonwidget(
                signText: 'Disable 2FA',
                onPressed: _disable2FA,
              ),
            ] else ...[
              Text(
                'Scan the QR code with your authenticator app (Google Authenticator, Authy, etc.)',
                style: AppTextStyles.bodyMedium(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (_qrCodeData != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _qrCodeData!,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _secret ?? '',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Or enter this code manually',
                        style: AppTextStyles.bodySmall(context),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),
              Buttonwidget(
                signText: 'Enable 2FA',
                onPressed: _enable2FA,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
