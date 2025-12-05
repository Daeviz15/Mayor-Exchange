import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mayor_exchange/Widgets/buttonWidget.dart';
import 'package:mayor_exchange/Widgets/formWdiget.dart';
import 'package:mayor_exchange/Widgets/signInComponent.dart';
import 'package:mayor_exchange/Widgets/textWidget.dart';
import 'package:mayor_exchange/features/auth/providers/auth_providers.dart';
import 'package:mayor_exchange/features/auth/screens/signup_screen.dart';
import 'package:mayor_exchange/features/dasboard/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _hasNavigated = false;

  @override
  void dispose() {
    _authStateSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Listen for Supabase auth changes so Google OAuth and email sign-in
    // both route back into the app cleanly.
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
      
      final authState = ref.read(authControllerProvider);
      if (authState.hasValue && authState.value != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed in successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _navigateToDashboard();
      } else if (authState.hasError) {
        throw authState.error!;
      }
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

  @override
  Widget build(BuildContext context) {
    final isLoading = _isSubmitting ||
        ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF221910),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 60,
                  alignment: Alignment.center,
                  width: 60,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(44, 230, 70, 30),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'M',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                  ),
                ),
                const SizedBox(height: 30),
                const TextWidget(
                  title: 'Welcome Back',
                  subtitle: 'Sign in to your mayor exchange account',
                ),
                const SizedBox(height: 50),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Text(
                        'Forgot Password?',
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.deepOrange,
                                  decoration: TextDecoration.underline,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Buttonwidget(
                  signText: isLoading ? 'Signing In...' : 'Sign In',
                  onPressed: isLoading ? null : _handleEmailSignIn,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      'Or sign in with ',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    Signincomponent(
                      icon: Image.asset(
                        'assets/icons/google.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                      onTap: isLoading ? null : _handleGoogleSignIn,
                    ),
                    const Signincomponent(
                      icon: FaIcon(
                        FontAwesomeIcons.apple,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 0.0,
                  children: [
                    Text(
                      "New to Mayor Exchange?",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) {
                              return const RegistrationScreen();
                            },
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 16,
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
