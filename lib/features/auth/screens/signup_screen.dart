import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mayor_exchange/Widgets/buttonWidget.dart';
import 'package:mayor_exchange/Widgets/formWdiget.dart';
import 'package:mayor_exchange/Widgets/textWidget.dart';
import 'package:mayor_exchange/features/auth/providers/auth_providers.dart';
import 'package:mayor_exchange/features/auth/screens/login_screen.dart';
import 'package:mayor_exchange/features/dasboard/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _hasNavigated = false;

  @override
  void dispose() {
    _authStateSubscription.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
  }

  Future<void> _handleEmailSignUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (fullName.isEmpty ||
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

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signUpWithEmail(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            fullName: fullName,
          );
      
      if (!mounted) return;
      
      // Check if sign-up was successful
      final authState = ref.read(authControllerProvider);
      if (authState.hasValue && authState.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please check your email to verify your account.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        _navigateToDashboard();
      } else if (authState.hasError) {
        throw authState.error!;
      }
    } catch (e) {
      if (!mounted) return;
      // Extract error message
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

  Future<void> _navigateToDashboard() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (!mounted || _hasNavigated || session == null) return;
    _hasNavigated = true;
    
    // Refresh auth controller to get latest user data immediately
    // This ensures user details are available right away
    await ref.read(authControllerProvider.notifier).refresh();
    
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      if (!mounted) return;
      // Google OAuth will redirect to browser, so we don't need to show success here
      // The auth state will update when user returns to app
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

  @override
  Widget build(BuildContext context) {
    final isLoading = _isSubmitting ||
        ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF221910),
      appBar: AppBar(
        backgroundColor: const Color(0xFF221910),
        title: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Mayor Exchange',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const TextWidget(
                  title: 'Create Your Account',
                  subtitle:
                      'Sign up to start trading crypto and gift cards securely',
                ),
                const SizedBox(height: 50),
                FormWidget(
                  controller: _fullNameController,
                  hintText: 'Jane Doe',
                  labelText: 'Full Name',
                  icon: const Icon(Icons.person),
                  keyboardType: TextInputType.name,
                  hidePasswordIcon: null,
                ),
                const SizedBox(height: 20),
                FormWidget(
                  controller: _emailController,
                  hintText: 'you@gmail.com',
                  labelText: 'Email',
                  icon: const Icon(Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  hidePasswordIcon: null,
                ),
                const SizedBox(height: 20),
                FormWidget(
                  controller: _passwordController,
                  hintText: 'Enter your password',
                  labelText: 'Password',
                  icon: const Icon(Icons.lock),
                  obscureText: true,
                  hidePasswordIcon: const Icon(Icons.visibility_off),
                ),
                const SizedBox(height: 20),
                FormWidget(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm your password',
                  labelText: 'Confirm Password',
                  icon: const Icon(Icons.lock),
                  obscureText: true,
                  hidePasswordIcon: const Icon(Icons.visibility_off),
                ),
                const SizedBox(height: 30),
                Buttonwidget(
                  signText: isLoading ? 'Creating Account...' : 'Sign Up',
                  onPressed: isLoading ? null : _handleEmailSignUp,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, right: 10),
                        child: Divider(
                          color:
                              const Color.fromARGB(66, 158, 158, 158),
                          thickness: 1.0,
                        ),
                      ),
                    ),
                    Text(
                      'Or',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 20),
                        child: Divider(
                          color:
                              const Color.fromARGB(66, 158, 158, 158),
                          thickness: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: isLoading ? null : _handleGoogleSignUp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color:
                            const Color.fromARGB(57, 158, 158, 158),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 24,
                          width: 24,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.google,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Sign up with Google',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 0.0,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                      child: Text(
                        'Login',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
