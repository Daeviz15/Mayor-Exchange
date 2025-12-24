import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/balance_card.dart';
import '../../../core/widgets/offline_status_banner.dart';

import '../widgets/crypto_card.dart';
import '../widgets/crypto_card_skeleton.dart';
import '../providers/balance_provider.dart';
import '../../crypto/providers/crypto_providers.dart';
import '../../crypto/screens/crypto_details_screen.dart';
import '../../crypto/screens/crypto_market_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/widgets/in_app_notification.dart';
import '../../../core/widgets/custom_refresh_wrapper.dart';
import 'settings_screen.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/profile_avatar_provider.dart';
import '../../../core/widgets/animations/fade_in_slide.dart';
import '../../../core/widgets/animations/page_transitions.dart';
import '../../portfolio/screens/portfolio_screen.dart';
import '../../wallet/screens/withdrawal_screen.dart';
import '../widgets/country_selection_modal.dart';
import '../../transactions/services/forex_service.dart';
import '../../giftcards/providers/gift_cards_providers.dart';
import '../../transactions/providers/transaction_service.dart';
import '../../../core/providers/navigation_provider.dart';
import '../widgets/transaction_short_list.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  bool _hasCheckedCountry = false;
  int _selectedTabIndex = 0; // 0: Cryptocurrency, 1: Gift Cards

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(balanceProvider);
    final cryptoListAsync = ref.watch(cryptoListProvider);
    final authState = ref.watch(authControllerProvider);
    final avatarState = ref.watch(profileAvatarProvider);
    // Needed for gift cards
    final allGiftCards = ref.watch(allGiftCardsProvider);

    final user = authState.asData?.value;
    final displayName = (user?.fullName?.trim().isNotEmpty == true)
        ? user!.fullName!
        : (user?.email.split('@').first ?? 'User');
    final email = user?.email ?? '';
    final localAvatarPath = avatarState.localPath;
    final networkAvatarUrl = avatarState.storageUrl ?? user?.avatarUrl;

    // Check if country is set
    if (user != null && user.country == null && !_hasCheckedCountry) {
      _hasCheckedCountry = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const CountrySelectionModal(),
        ).then((_) {});
      });
    }

    // Listen for new notifications
    ref.listen(notificationsProvider, (previous, next) {
      if (previous != null && next.length > previous.length) {
        final newNotification = next.first;
        if (!newNotification.isRead) {
          _showNotificationOverlay(context, newNotification);
        }
      }
    });

    return Column(
      children: [
        // Header
        FadeInSlide(
          duration: const Duration(milliseconds: 800),
          direction: SlideDirection.down,
          child: DashboardHeader(
            displayName: displayName,
            email: email,
            localAvatarPath: localAvatarPath,
            networkAvatarUrl: networkAvatarUrl,
            onAvatarTap: () {
              Navigator.push(
                context,
                SlidePageRoute(page: const SettingsScreen()),
              );
            },
            onNotificationTap: () {
              Navigator.push(
                context,
                SlidePageRoute(page: const NotificationScreen()),
              );
            },
          ),
        ),

        // Offline Status Banner
        const OfflineStatusBanner(),

        // Content
        Expanded(
          child: CustomRefreshWrapper(
            onRefresh: () async {
              ref.invalidate(balanceProvider);
              await ref
                  .read(cryptoListProvider.notifier)
                  .refresh(); // Force refresh crypto
              ref.invalidate(
                  userTransactionsProvider); // Also refresh transactions
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Balance Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FadeInSlide(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 100),
                      child: Builder(builder: (context) {
                        final currency = user?.currency ?? 'NGN';
                        String symbol = '₦';

                        final forexService = ref.read(forexServiceProvider);
                        final forexRate = forexService.convert(
                            balanceState.totalBalance, currency);

                        switch (currency) {
                          case 'USD':
                            symbol = '\$';
                            break;
                          case 'GBP':
                            symbol = '£';
                            break;
                          case 'EUR':
                            symbol = '€';
                            break;
                          case 'CAD':
                            symbol = 'C\$';
                            break;
                          case 'GHS':
                            symbol = '₵';
                            break;
                          default:
                            symbol = '₦';
                        }

                        return BalanceCard(
                          balance: forexRate,
                          changePercent: balanceState.changePercent24h,
                          symbol: symbol,
                          onViewPortfolio: () {
                            Navigator.push(
                              context,
                              SlidePageRoute(page: const PortfolioScreen()),
                            );
                          },
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Action Buttons (Row of 4 icons)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FadeInSlide(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickActionItem(
                            context,
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Buy',
                            onTap: () {
                              ref
                                  .read(navigationProvider.notifier)
                                  .setIndex(1); // Trade Tab
                            },
                          ),
                          _buildQuickActionItem(
                            context,
                            icon: Icons.sell_outlined,
                            label: 'Sell',
                            onTap: () {
                              ref
                                  .read(navigationProvider.notifier)
                                  .setIndex(1); // Trade Tab
                            },
                          ),
                          _buildQuickActionItem(
                            context,
                            icon: Icons.arrow_downward,
                            label: 'Withdraw',
                            onTap: () {
                              // Navigate to Withdrawal Screen
                              Navigator.push(
                                context,
                                SlidePageRoute(page: const WithdrawalScreen()),
                              );
                            },
                          ),
                          _buildQuickActionItem(
                            context,
                            icon: Icons.swap_horiz,
                            label: 'Trade',
                            onTap: () {
                              ref
                                  .read(navigationProvider.notifier)
                                  .setIndex(1); // Trade Tab
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Segmented Control / Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FadeInSlide(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                child: _buildTabButton(0, 'Cryptocurrency')),
                            Expanded(child: _buildTabButton(1, 'Gift Cards')),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Selected Tab Content (Market Trends / Gift Cards)
                  FadeInSlide(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTabIndex == 0
                                    ? 'Market Trends'
                                    : 'Popular Gift Cards',
                                style: AppTextStyles.titleMedium(context),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (_selectedTabIndex == 0) {
                                    // Navigate to full crypto list
                                    Navigator.push(
                                      context,
                                      SlidePageRoute(
                                          page: const CryptoMarketScreen()),
                                    );
                                  } else {
                                    ref
                                        .read(navigationProvider.notifier)
                                        .setIndex(2); // Giftcards tab
                                  }
                                },
                                child: Text('View all',
                                    style: TextStyle(
                                        color: AppColors.primaryOrange)),
                              )
                            ],
                          ),
                        ),
                        // Content Body
                        if (_selectedTabIndex == 0)
                          // Crypto List
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: cryptoListAsync.when(
                              data: (cryptoList) {
                                if (cryptoList.isEmpty) {
                                  return const Center(
                                      child: Text('No crypto data'));
                                }
                                // Show top 3
                                return Column(
                                  children: cryptoList
                                      .take(3)
                                      .map(
                                        (crypto) => CryptoCard(
                                          crypto: crypto,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              SlidePageRoute(
                                                page: CryptoDetailsScreen(
                                                  cryptoSymbol: crypto.symbol,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                              loading: () =>
                                  const CryptoCardSkeletonList(count: 3),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          )
                        else
                          // Gift Cards Grid/List
                          // Show top 4 popular cards in a grid 2x2
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.5,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: allGiftCards.take(4).length,
                              itemBuilder: (context, index) {
                                final card = allGiftCards[index];
                                return GestureDetector(
                                  onTap: () {
                                    // Navigate to Gift Card detail - Reusing GiftCardsScreen flow?
                                    // Ideally navigate to a detail/buy screen.
                                    // For now just route to GiftCardsScreen tab
                                    ref
                                        .read(navigationProvider.notifier)
                                        .setIndex(2);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundCard,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.card_giftcard,
                                            color: _getCardColor(index),
                                            size: 32),
                                        const SizedBox(height: 8),
                                        Text(card.name,
                                            style: AppTextStyles.bodyMedium(
                                                context)),
                                        Text('\$1 = \$0.85',
                                            style: AppTextStyles.bodySmall(
                                                    context)
                                                .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 10)), // Mock rate
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent Transactions
                  const TransactionShortList(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.backgroundElevated
              : Colors.transparent, // Slightly lighter for active
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.primaryOrange
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75, // Fixed width for alignment
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Color _getCardColor(int index) {
    const colors = [Colors.orange, Colors.pink, Colors.blue, Colors.purple];
    return colors[index % colors.length];
  }

  void _showNotificationOverlay(
      BuildContext context, NotificationModel notification) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => InAppNotificationOverlay(
        title: notification.title,
        message: notification.message,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }
}
