import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:pinput/pinput.dart';
import 'package:otp/otp.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../Widgets/buttonWidget.dart';
import '../../../core/providers/supabase_provider.dart';
import '../providers/auth_providers.dart';
import '../../dasboard/screens/home_screen.dart';
import '../../../core/utils/security_utils.dart';

// Provider to track if 2FA has been verified in the current app session
final is2faVerifiedProvider = StateProvider<bool>((ref) => false);

class Login2FAScreen extends ConsumerStatefulWidget {
  final String userId;
  final String email;

  const Login2FAScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  ConsumerState<Login2FAScreen> createState() => _Login2FAScreenState();
}

class _Login2FAScreenState extends ConsumerState<Login2FAScreen> {
  final _pinController = TextEditingController();
  final _recoveryController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isUsingRecoveryCode = false;
  String? _errorText;
  String? _secret;

  @override
  void initState() {
    super.initState();
    _fetchSecret();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _recoveryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchSecret() async {
    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);

      final response = await supabase
          .from('user_2fa_secrets')
          .select('secret')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (response != null && response['secret'] != null) {
        setState(() {
          _secret = response['secret'] as String;
          _isLoading = false;
        });
      } else {
        // If secret is missing but 2FA is enabled, user might need to use recovery code
        setState(() {
          _isLoading = false;
          // Don't show error yet, let them try recovery code
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Error fetching 2FA settings: ${e.toString()}';
      });
    }
  }

  bool _verifyCode(String code) {
    if (_secret == null) return false;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      final current = OTP.generateTOTPCodeString(
        _secret!,
        now,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      final prev = OTP.generateTOTPCodeString(
        _secret!,
        now - 30000,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      final next = OTP.generateTOTPCodeString(
        _secret!,
        now + 30000,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      return code == current || code == prev || code == next;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _verifyRecoveryCode(String code) async {
    try {
      final supabase = ref.read(supabaseClientProvider);

      final response = await supabase
          .from('user_2fa_recovery_codes')
          .select()
          .eq('user_id', widget.userId)
          .eq('code_hash', SecurityUtils.hashString(code.toUpperCase()))
          .isFilter('used_at', null)
          .maybeSingle();

      if (response != null) {
        // Mark code as used
        await supabase
            .from('user_2fa_recovery_codes')
            .update({'used_at': DateTime.now().toIso8601String()}).eq(
                'id', response['id']);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error verifying recovery code: $e');
      return false;
    }
  }

  Future<void> _handleVerify() async {
    final code = _isUsingRecoveryCode
        ? _recoveryController.text.trim()
        : _pinController.text;

    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    bool isValid = false;
    if (_isUsingRecoveryCode) {
      isValid = await _verifyRecoveryCode(code);
    } else {
      isValid = _verifyCode(code);
    }

    if (isValid) {
      ref.read(is2faVerifiedProvider.notifier).state = true;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorText = _isUsingRecoveryCode
            ? 'Invalid or already used recovery code.'
            : 'Invalid verification code. Please try again.';
        _pinController.clear();
        _recoveryController.clear();
      });
    }
  }

  Future<void> _handleCancel() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: AppTextStyles.titleLarge(context).copyWith(
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(height: 32),
              Text(
                'Two-Factor Authentication',
                style: AppTextStyles.titleLarge(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _isUsingRecoveryCode
                    ? 'Enter one of your 10-character recovery codes.'
                    : 'Enter the 6-digit code from your authenticator app to complete sign-in.',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Center(
                child: _isLoading && _secret == null && !_isUsingRecoveryCode
                    ? const CircularProgressIndicator(
                        color: AppColors.primaryOrange)
                    : _isUsingRecoveryCode
                        ? TextField(
                            controller: _recoveryController,
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'ABCDEF1234',
                              hintStyle:
                                  TextStyle(color: AppColors.textTertiary),
                              filled: true,
                              fillColor: AppColors.backgroundCard,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _handleVerify(),
                          )
                        : Pinput(
                            length: 6,
                            controller: _pinController,
                            focusNode: _focusNode,
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: defaultPinTheme.copyWith(
                              decoration: defaultPinTheme.decoration!.copyWith(
                                border:
                                    Border.all(color: AppColors.primaryOrange),
                              ),
                            ),
                            errorPinTheme: defaultPinTheme.copyWith(
                              decoration: defaultPinTheme.decoration!.copyWith(
                                border: Border.all(color: AppColors.error),
                              ),
                            ),
                            onCompleted: (_) => _handleVerify(),
                            autofocus: true,
                          ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => setState(() {
                  _isUsingRecoveryCode = !_isUsingRecoveryCode;
                  _errorText = null;
                }),
                child: Text(
                  _isUsingRecoveryCode
                      ? 'Use Authenticator Code'
                      : 'Try Recovery Code',
                  style: const TextStyle(color: AppColors.primaryOrange),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 24),
                Text(
                  _errorText!,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 48),
              Buttonwidget(
                signText: _isLoading ? 'Verifying...' : 'Verify & Sign In',
                onPressed: _isLoading ? () {} : _handleVerify,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _handleCancel,
                child: Text(
                  'Back to Login',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
