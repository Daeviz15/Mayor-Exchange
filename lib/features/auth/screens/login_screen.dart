import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mayor_exchange/core/theme/app_colors.dart';
import 'package:mayor_exchange/core/theme/app_text_styles.dart';
import 'package:mayor_exchange/core/widgets/rocket_loader.dart';
import 'package:mayor_exchange/features/auth/providers/auth_providers.dart';
import 'package:mayor_exchange/features/auth/providers/security_provider.dart';
import 'package:mayor_exchange/features/auth/screens/signup_screen.dart';
import 'package:mayor_exchange/features/auth/screens/biometric_login_screen.dart';
import 'package:mayor_exchange/features/dasboard/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mayor_exchange/features/auth/screens/forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// When true, skips the automatic redirect to biometric login
  final bool skipBiometricCheck;

  /// If provided, pre-fills the email field and suppresses cached user "Welcome Back" screen
  final String? initialEmail;

  const LoginScreen({
    super.key,
    this.skipBiometricCheck = false,
    this.initialEmail,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _hasNavigated = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Pre-fill email if provided
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }

    // Animation controller for fade-in effects
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

    // Check if biometric login is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricLogin();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _authStateSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricLogin() async {
    // Skip if explicitly requested (e.g., coming from biometric login screen)
    // Also skip if we have an initialEmail, because we want to login as THAT user, not the cached one.
    if (widget.skipBiometricCheck || widget.initialEmail != null) return;

    final securitySettings = ref.read(securitySettingsProvider);
    final lastUser = ref.read(lastLoggedInUserProvider);

    // FIX: strict check for biometricEnabled
    if (securitySettings.biometricEnabled &&
        lastUser != null &&
        Supabase.instance.client.auth.currentSession == null) {
      // Ensure we have a stored password before trying biometric login
      final password =
          await ref.read(lastLoggedInUserProvider.notifier).getPassword();
      if (password == null) return;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BiometricLoginScreen(
            email: lastUser.email,
            avatarUrl: lastUser.avatarUrl,
            displayName: lastUser.displayName,
          ),
        ),
      );
    }
  }

  /// Mask email for privacy display
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) {
      return '${name[0]}${'*' * 6}@$domain';
    }
    final visiblePart = name.substring(0, 2);
    return '$visiblePart${'*' * 6}@$domain';
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(email: email, password: password);

      if (!mounted) return;

      // Navigation is primarily handled by _authStateSubscription,
      // but we can also check immediate result or catch errors here.
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Failed to sign in';
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

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Failed to sign in with Google';
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

    // Store user info for biometric login
    final user = ref.read(authControllerProvider).asData?.value;
    if (user != null) {
      // Only store password if we have one and it matches the current user
      // (This handles the case where user might be logging in via Google)
      String? password;
      if (_emailController.text.trim().toLowerCase() ==
          user.email.toLowerCase()) {
        password = _passwordController.text;
      }

      await ref.read(lastLoggedInUserProvider.notifier).setUser(
            email: user.email,
            avatarUrl: user.avatarUrl,
            displayName: user.fullName,
            password: password,
          );
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _navigateToBiometricLogin() async {
    final lastUser = ref.read(lastLoggedInUserProvider);
    if (lastUser != null) {
      // Check for password availability
      final password =
          await ref.read(lastLoggedInUserProvider.notifier).getPassword();

      if (!mounted) return;

      if (password != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BiometricLoginScreen(
              email: lastUser.email,
              avatarUrl: lastUser.avatarUrl,
              displayName: lastUser.displayName,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login with password to re-enable biometrics'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login once to enable fingerprint login'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildUserAvatar() {
    final lastUser = ref.watch(lastLoggedInUserProvider);
    if (lastUser?.avatarUrl != null && lastUser!.avatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: lastUser.avatarUrl!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.backgroundCard,
          child: const Center(
            child: RocketLoader(size: 24, color: AppColors.primaryOrange),
          ),
        ),
        errorWidget: (context, url, error) => _buildDefaultAvatar(),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 40,
        color: AppColors.primaryOrange.withValues(alpha: 0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        _isSubmitting || ref.watch(authControllerProvider).isLoading;
    final lastUser = ref.watch(lastLoggedInUserProvider);
    // Show welcome back only if we have a last user AND we are not explicitly trying to login as someone else
    final showWelcomeBack = lastUser != null && widget.initialEmail == null;

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
                const SizedBox(height: 60),

                // Welcome Back title
                if (showWelcomeBack) ...[
                  Text(
                    'Welcome Back!',
                    style: AppTextStyles.displayLarge(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundCard,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(child: _buildUserAvatar()),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _maskEmail(lastUser.email),
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  // Standard header when not welcome back
                  Text(
                    'Log In',
                    style: AppTextStyles.displayLarge(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],

                // Email field
                _buildFormField(
                  label: 'Email Address',
                  controller: _emailController,
                  hintText: 'example@gmail.com',
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

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Log In button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleEmailSignIn,
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
                        // USE THE NEW ROCKET LOADER HERE
                        ? const RocketLoader(
                            size: 24,
                            color: Colors.white,
                          )
                        : Text(
                            'Log In',
                            style: AppTextStyles.titleSmall(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Don't have an account? Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegistrationScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
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

                // Google Sign In button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _handleGoogleSignIn,
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
                      'Log In with Google',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Login with Fingerprint - Only show if enabled in settings
                Consumer(
                  builder: (context, ref, child) {
                    final biometricEnabled =
                        ref.watch(securitySettingsProvider).biometricEnabled;

                    // HIDE BUTTON IF DISABLED
                    if (!biometricEnabled) {
                      return const SizedBox(height: 16);
                    }

                    return GestureDetector(
                      onTap: _navigateToBiometricLogin,
                      child: Text(
                        'Login with Fingerprint',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
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
}
