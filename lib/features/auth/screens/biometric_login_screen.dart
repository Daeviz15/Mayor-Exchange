import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/security_provider.dart';
import '../providers/auth_providers.dart';
import '../../dasboard/screens/home_screen.dart';
import 'login_screen.dart';
import '../../../core/widgets/rocket_loader.dart';

/// Biometric Login Screen
/// Shown when user has biometric login enabled
class BiometricLoginScreen extends ConsumerStatefulWidget {
  final String email;
  final String? avatarUrl;
  final String? displayName;

  const BiometricLoginScreen({
    super.key,
    required this.email,
    this.avatarUrl,
    this.displayName,
  });

  @override
  ConsumerState<BiometricLoginScreen> createState() =>
      _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends ConsumerState<BiometricLoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for fingerprint icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Glow animation for fingerprint container
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  /// Mask email for privacy display
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) {
      return '${name[0]}${'*' * 5}@$domain';
    }

    final visiblePart = name.substring(0, 2);
    final maskedPart = '*' * 6;
    return '$visiblePart$maskedPart@$domain';
  }

  /// Authenticate with biometrics
  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    try {
      setState(() => _isAuthenticating = true);

      final localAuth = ref.read(biometricAuthProvider);

      // 1. Check if device supports biometrics
      final isDeviceSupported = await localAuth.isDeviceSupported();
      final canCheck = await localAuth
          .canCheckBiometrics; // Use as getter if method fails, or check if it is a method.

      if (!isDeviceSupported || !canCheck) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Biometric authentication is not available on this device'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 2. Authenticate
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/Pattern backup if biometrics fail
        ),
      );

      if (!mounted) return;

      if (authenticated) {
        // ... (Existing success logic)
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          // Session exists, refresh auth state
          await ref.read(authControllerProvider.notifier).refresh();

          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else {
          // No session - try to login with stored password
          final password =
              await ref.read(lastLoggedInUserProvider.notifier).getPassword();

          if (password != null) {
            await ref.read(authControllerProvider.notifier).signInWithEmail(
                  email: widget.email,
                  password: password,
                );

            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Credentials expired. Please login with your password.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const LoginScreen(skipBiometricCheck: true),
              ),
            );
          }
        }
      } else {
        // User cancelled or failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication cancelled or failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Debug removed
      if (!mounted) return;

      String errorMessage = 'Authentication failed. Please use password.';
      final errorStr = e.toString();

      if (errorStr.contains('NotAvailable')) {
        errorMessage = 'Biometric authentication is not available';
      } else if (errorStr.contains('NotEnrolled')) {
        errorMessage = 'No biometrics enrolled on this device';
      } else if (errorStr.contains('LockedOut')) {
        errorMessage = 'Too many failed attempts. Try again later';
      } else if (errorStr.contains('PermanentlyLockedOut')) {
        errorMessage = 'Biometrics disabled due to many failures. Use password';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Use Password',
            textColor: Colors.white,
            onPressed: _navigateToPasswordLogin,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  /// Navigate to password login
  void _navigateToPasswordLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(skipBiometricCheck: true),
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.avatarUrl!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.backgroundElevated,
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
    final initials = (widget.displayName ?? widget.email)
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Container(
      width: 100,
      height: 100,
      color: AppColors.primaryOrange.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : widget.email[0].toUpperCase(),
          style: AppTextStyles.displayMedium(context).copyWith(
            color: AppColors.primaryOrange,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail = _maskEmail(widget.email);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Spacer for top
            const SizedBox(height: 80),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Welcome text with animation
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
                      child: Text(
                        'Welcome Back!',
                        style: AppTextStyles.displayLarge(context).copyWith(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 34,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Avatar with animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.backgroundElevated,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildAvatar(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Email with animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 700),
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
                      child: Text(
                        maskedEmail,
                        style: AppTextStyles.titleMedium(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Fingerprint icon with pulse animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: _isAuthenticating
                            ? null
                            : _authenticateWithBiometrics,
                        child: AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryOrange
                                    .withValues(alpha: 0.1),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryOrange.withValues(
                                      alpha: _glowAnimation.value,
                                    ),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Icon(
                                      Icons.fingerprint,
                                      size: 64,
                                      color: _isAuthenticating
                                          ? AppColors.primaryOrange
                                              .withValues(alpha: 0.5)
                                          : AppColors.primaryOrange,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Instruction text
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: child,
                        );
                      },
                      child: Text(
                        'Click to log in with Fingerprint',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Verify Fingerprint button
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
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
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isAuthenticating
                              ? null
                              : _authenticateWithBiometrics,
                          child: _isAuthenticating
                              ? const RocketLoader(
                                  size: 24,
                                  color: Colors.white,
                                )
                              : Text(
                                  'Verify Fingerprint',
                                  style: AppTextStyles.titleSmall(context)
                                      .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Login with Password link at bottom
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: GestureDetector(
                  onTap: _navigateToPasswordLogin,
                  child: Text(
                    'Login with Password',
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
