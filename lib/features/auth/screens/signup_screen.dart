import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayor_exchange/core/theme/app_colors.dart';
import 'package:mayor_exchange/core/widgets/rocket_loader.dart';
import 'package:mayor_exchange/core/theme/app_text_styles.dart';
import 'package:mayor_exchange/features/auth/providers/auth_providers.dart';
import 'package:mayor_exchange/features/auth/screens/login_screen.dart';
import 'package:mayor_exchange/features/auth/screens/email_verification_screen.dart';
import 'package:mayor_exchange/features/dasboard/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Password strength enumeration
enum PasswordStrength { none, weak, medium, strong }

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _hasNavigated = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  PasswordStrength _passwordStrength = PasswordStrength.none;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();

    // Listen for Supabase auth changes
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      if (session != null &&
          (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed)) {
        _navigateToDashboard();
      }
    });

    // Listen to password changes for strength calculation
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _animController.dispose();
    _authStateSubscription.cancel();
    _firstNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    PasswordStrength strength = PasswordStrength.none;

    if (password.isEmpty) {
      strength = PasswordStrength.none;
    } else if (password.length < 6) {
      strength = PasswordStrength.weak;
    } else if (password.length < 8) {
      strength = PasswordStrength.medium;
    } else {
      // Check for complexity
      final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      final hasLowerCase = password.contains(RegExp(r'[a-z]'));
      final hasDigits = password.contains(RegExp(r'\d'));
      final hasSpecialChars =
          password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      if ((hasUpperCase || hasLowerCase) && hasDigits && hasSpecialChars) {
        strength = PasswordStrength.strong;
      } else if ((hasUpperCase || hasLowerCase) && hasDigits) {
        strength = PasswordStrength.medium;
      } else {
        strength = PasswordStrength.medium;
      }
    }

    setState(() => _passwordStrength = strength);
  }

  Future<void> _handleEmailSignUp() async {
    final firstName = _firstNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final termsAccepted = _termsAccepted;

    if (firstName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!termsAccepted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signUpWithEmail(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            fullName: firstName,
          );

      if (!mounted) return;

      final authState = ref.read(authControllerProvider);
      if (authState.hasValue && authState.value != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
          ),
        );
      } else if (authState.hasError) {
        throw authState.error!;
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Failed to create account';
      if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Failed to sign up with Google';
      if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _navigateToDashboard() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (!mounted || _hasNavigated || session == null) return;
    _hasNavigated = true;

    await ref.read(authControllerProvider.notifier).refresh();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        _isSubmitting || ref.watch(authControllerProvider).isLoading;
    final passwordStrength = _passwordStrength;
    final termsAccepted = _termsAccepted;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),

                // Sign Up title
                Text(
                  'Sign Up',
                  style: AppTextStyles.displayMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 40),

                // Firstname field
                _buildFormField(
                  label: 'Firstname',
                  controller: _firstNameController,
                  hintText: 'Placeholder Here',
                ),

                const SizedBox(height: 20),

                // Email field (hidden in mockup but needed)
                _buildFormField(
                  label: 'Email Address',
                  controller: _emailController,
                  hintText: 'you@email.com',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // Password field
                _buildFormField(
                  label: 'Password',
                  controller: _passwordController,
                  hintText: 'Enter Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Password strength indicator
                _buildPasswordStrengthIndicator(passwordStrength),

                const SizedBox(height: 16),

                // Confirm Password field
                _buildFormField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  hintText: 'Enter Password',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Terms checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: termsAccepted,
                        onChanged: (value) {
                          setState(() => _termsAccepted = value ?? false);
                        },
                        activeColor: AppColors.primaryOrange,
                        side: const BorderSide(color: AppColors.textSecondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(
                                text:
                                    'I certify that I am 18 years of age or older and I agree to the '),
                            TextSpan(
                              text: 'User agreement',
                              style: TextStyle(color: AppColors.primaryOrange),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // TODO: Open user agreement
                                },
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(color: AppColors.primaryOrange),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // TODO: Open privacy policy
                                },
                            ),
                            const TextSpan(text: ' of Mayor Exchange'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Create My Account button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleEmailSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const RocketLoader(
                            size: 24,
                            color: Colors.white,
                          )
                        : Text(
                            'Create My Account',
                            style: AppTextStyles.titleSmall(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Already have an account? Log in
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Log in',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // OR divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),

                const SizedBox(height: 24),

                // Register with Google button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _handleGoogleSignUp,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/icons/google.png',
                      width: 20,
                      height: 20,
                    ),
                    label: Text(
                      'Register with Google',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: AppTextStyles.bodyLarge(context),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.backgroundCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator(PasswordStrength strength) {
    return Row(
      children: [
        _buildStrengthBar(
          isActive: strength == PasswordStrength.weak ||
              strength == PasswordStrength.medium ||
              strength == PasswordStrength.strong,
          color: strength == PasswordStrength.weak
              ? Colors.red
              : strength == PasswordStrength.medium
                  ? Colors.orange
                  : Colors.green,
        ),
        const SizedBox(width: 8),
        _buildStrengthBar(
          isActive: strength == PasswordStrength.medium ||
              strength == PasswordStrength.strong,
          color: strength == PasswordStrength.medium
              ? Colors.orange
              : Colors.green,
        ),
        const SizedBox(width: 8),
        _buildStrengthBar(
          isActive: strength == PasswordStrength.strong,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStrengthBar({required bool isActive, required Color color}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 4,
        decoration: BoxDecoration(
          color: isActive ? color : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
