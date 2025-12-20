import 'package:flutter/material.dart';
import 'package:mayor_exchange/core/theme/app_colors.dart';
import 'package:mayor_exchange/features/onboarding/screens/onboarding_screen.dart';
import 'package:mayor_exchange/features/dasboard/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mayor_exchange/features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Navigate after delay
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final session = Supabase.instance.client.auth.currentSession;

      Widget target;
      if (session != null) {
        target = const HomeScreen();
      } else {
        final prefs = await SharedPreferences.getInstance();
        final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
        target =
            seenOnboarding ? const LoginScreen() : const OnboardingScreen();
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => target,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        // Removed BoxShape.circle to prevent cutting off square logos
                        shape: BoxShape.rectangle,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.contain,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryOrange.withValues(alpha: 0.25),
                            blurRadius: 60,
                            spreadRadius: 10,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'MAYOR EXCHANGE',
                      style: TextStyle(
                        fontFamily: 'Outfit', // Ensure premium font
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color:
                                AppColors.primaryOrange.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
