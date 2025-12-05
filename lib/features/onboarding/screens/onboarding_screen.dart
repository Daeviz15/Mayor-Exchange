import 'package:flutter/material.dart';
import 'package:mayor_exchange/core/theme/app_colors.dart';
import 'package:mayor_exchange/features/auth/screens/signup_screen.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Welcome to\nMayor Exchange',
      description:
          'The most secure and fastest way to trade cryptocurrencies and gift cards.',
      icon: Icons.security,
    ),
    OnboardingContent(
      title: 'Trade Crypto\nInstantly',
      description:
          'Buy and sell Bitcoin, Ethereum, Solana and more with competitive rates.',
      icon: Icons.currency_bitcoin,
    ),
    OnboardingContent(
      title: 'Best Rates for\nGift Cards',
      description:
          'Exchange your unused gift cards for cash instantly at the best market rates.',
      icon: Icons.card_giftcard,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(content: _contents[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _contents.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryOrange
                              : AppColors.textSecondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Buttons
                  if (_currentPage == _contents.length - 1)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToRegistration();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            _navigateToRegistration();
                          },
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRegistration() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ____) => const RegistrationScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  const _OnboardingPage({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(content.icon, size: 80, color: AppColors.primaryOrange),
          ),
          const SizedBox(height: 48),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
