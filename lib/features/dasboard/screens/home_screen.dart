import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/crypto_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/balance_provider.dart';
import '../../crypto/providers/crypto_providers.dart';
import '../../giftcards/screens/gift_cards_screen.dart';
import '../../crypto/screens/crypto_details_screen.dart';
import 'settings_screen.dart';
import '../../../core/providers/navigation_provider.dart';

/// Home Screen (Dashboard)
/// Main dashboard screen for Mayor Exchange
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(balanceProvider);
    final cryptoListAsync = ref.watch(cryptoListProvider);
    final currentNavIndex = ref.watch(navigationProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            DashboardHeader(
              onAvatarTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Balance Card
                    BalanceCard(
                      balance: balanceState.totalBalance,
                      changePercent: balanceState.changePercent24h,
                      onViewPortfolio: () {
                        // Navigate to portfolio
                      },
                    ),

                    const SizedBox(height: 24),

                    // Quick Action Buttons
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            Expanded(
                              child: QuickActionButton(
                                label: 'Buy/Sell Crypto',
                                icon: Icons.swap_horiz,
                                isPrimary: true,
                                onTap: () {
                                  // Navigate to crypto trade
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: QuickActionButton(
                                label: 'Trade Gift Cards',
                                icon: Icons.card_giftcard,
                                isPrimary: false,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const GiftCardsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Market Trends Section
                    Text(
                      'Market Trends',
                      style: AppTextStyles.titleMedium(context),
                    ),

                    const SizedBox(height: 16),

                    // Crypto List
                    cryptoListAsync.when(
                      data: (cryptoList) {
                        if (cryptoList.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                'No crypto data available',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            ...cryptoList.map(
                              (crypto) => CryptoCard(
                                crypto: crypto,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CryptoDetailsScreen(
                                        cryptoSymbol: crypto.symbol,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ),
                      error: (error, stack) => Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load crypto data',
                                style: AppTextStyles.bodySmall(context),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  ref.invalidate(cryptoListProvider);
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentNavIndex,
        onTap: (index) {
          ref.read(navigationProvider.notifier).setIndex(index);
          // Handle navigation
          if (index == 3) {
            // Gift Cards tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GiftCardsScreen()),
            ).then((_) {
              // Reset to home when coming back
              ref.read(navigationProvider.notifier).setIndex(0);
            });
          } else if (index == 4) {
            // Settings tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ).then((_) {
              // Reset to home when coming back
              ref.read(navigationProvider.notifier).setIndex(0);
            });
          }
        },
      ),
    );
  }
}
