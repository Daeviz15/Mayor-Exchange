import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pinput/pinput.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_handler_utils.dart';

import '../providers/forgot_password_controller.dart';
import 'create_new_password_screen.dart';

class VerifyResetCodeScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyResetCodeScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<VerifyResetCodeScreen> createState() =>
      _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends ConsumerState<VerifyResetCodeScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _resendTimer = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendTimer = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  void _resendCode() {
    // Logic to resend code
    ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetCode(widget.email);
    _startTimer();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pinController.text.length != 6) return;

    final controller = ref.read(forgotPasswordControllerProvider.notifier);

    // Verify code
    await controller.verifyCode(widget.email, _pinController.text);

    if (!mounted) return;

    // Check state
    final state = ref.read(forgotPasswordControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString())),
      );
    } else {
      // Navigate to create new password
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CreateNewPasswordScreen(
            email: widget.email,
            code: _pinController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final isLoading = state.isLoading;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: TextStyle(
        fontFamily: 'Host Grotesk',
        fontFamilyFallback: ['Roboto', 'Noto Sans'],
        fontSize: 20,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent, // Design shows dark boxes
        border: Border.all(color: AppColors.textTertiary.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primaryOrange),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Enter Reset Code',
                style: TextStyle(
                  fontFamily: 'Host Grotesk',
                  fontFamilyFallback: ['Roboto', 'Noto Sans'],
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Input the six-digit code sent to ${widget.email}', // Using real email as user requested email flow
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Host Grotesk',
                  fontFamilyFallback: ['Roboto', 'Noto Sans'],
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Pinput(
                  controller: _pinController,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  cursor: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        width: 22,
                        height: 1,
                        color: AppColors.primaryOrange,
                      ),
                    ],
                  ),
                  onCompleted: (pin) {
                    // Optional: auto submit
                  },
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const RocketLoader(
                          size: 24,
                          color: Colors.white,
                        )
                      : state.hasError
                          ? Text(
                              ErrorHandlerUtils.getUserFriendlyErrorMessage(
                                  state.error),
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : Text(
                              'Continue',
                              style: TextStyle(
                                fontFamily: 'Host Grotesk',
                                fontFamilyFallback: ['Roboto', 'Noto Sans'],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                text: TextSpan(
                  text: "Didn't receive code? ",
                  style: TextStyle(
                    fontFamily: 'Host Grotesk',
                    fontFamilyFallback: ['Roboto', 'Noto Sans'],
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  children: [
                    if (_resendTimer > 0)
                      TextSpan(
                        text: 'Resend in ${_resendTimer}s',
                        style: TextStyle(
                          fontFamily: 'Host Grotesk',
                          fontFamilyFallback: ['Roboto', 'Noto Sans'],
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      TextSpan(
                        text: 'Resend',
                        style: TextStyle(
                          fontFamily: 'Host Grotesk',
                          fontFamilyFallback: ['Roboto', 'Noto Sans'],
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = _resendCode,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
