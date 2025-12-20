import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import 'dashboard_tab.dart'; // Import extracted tab
import '../../portfolio/screens/portfolio_screen.dart';
import '../../transactions/screens/buy_sell_crypto_screen.dart';
import '../../giftcards/screens/gift_cards_screen.dart';
import 'settings_screen.dart';
import '../../../core/providers/navigation_provider.dart';

/// Home Screen (Shell)
/// Main shell that holds the Bottom Navigation Bar and persistent tabs
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNavIndex = ref.watch(navigationProvider);

    // List of persistent screens
    final List<Widget> screens = [
      const DashboardTab(), // Index 0
      const PortfolioScreen(), // Index 1
      const BuySellCryptoScreen(), // Index 2
      const GiftCardsScreen(), // Index 3
      const SettingsScreen(), // Index 4
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: IndexedStack(
          index: currentNavIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentNavIndex,
        onTap: (index) {
          // Just update provider, IndexedStack handles the rest
          ref.read(navigationProvider.notifier).setIndex(index);
        },
      ),
    );
  }
}
