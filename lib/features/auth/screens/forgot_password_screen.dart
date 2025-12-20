import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../providers/forgot_password_controller.dart';
import 'verify_reset_code_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _copyEmailAndNavigate() {
    // Navigate to verify code screen with the email
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            VerifyResetCodeScreen(email: _emailController.text.trim()),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(forgotPasswordControllerProvider.notifier);

    // Call controller to send reset code
    await controller.sendResetCode(_emailController.text.trim());

    if (!mounted) return;

    // Check for success (you might want to listen to state changes instead or check result)
    final state = ref.read(forgotPasswordControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString())),
      );
    } else {
      _copyEmailAndNavigate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final isLoading = state.isLoading;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Reset Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your registered email to receive a verification code',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Address',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'example@gmail.com',
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.backgroundCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppColors.textTertiary.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppColors.textTertiary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primaryOrange),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                      : Text(
                          'Send Reset Code',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const Spacer(),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Remember your password? ',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: 'Log In',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).pop();
                          },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
