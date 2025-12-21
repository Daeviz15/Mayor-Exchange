import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/crypto_card.dart';
import '../widgets/crypto_card_skeleton.dart';
import '../providers/balance_provider.dart';
import '../../crypto/providers/crypto_providers.dart';
import '../../giftcards/screens/gift_cards_screen.dart';
import '../../crypto/screens/crypto_details_screen.dart';
import '../../transactions/screens/transaction_history_screen.dart';
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
import '../widgets/country_selection_modal.dart';
import '../../transactions/services/forex_service.dart';
import '../../../core/providers/navigation_provider.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  bool _hasCheckedCountry = false;

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(balanceProvider);
    final cryptoListAsync = ref.watch(cryptoListProvider);
    final authState = ref.watch(authControllerProvider);
    final avatarState = ref.watch(profileAvatarProvider);

    final user = authState.asData?.value;
    final displayName = (user?.fullName?.trim().isNotEmpty == true)
        ? user!.fullName!
        : (user?.email.split('@').first ?? 'User');
    final email = user?.email ?? '';
    final localAvatarPath = avatarState.localPath;
    final networkAvatarUrl = avatarState.storageUrl ?? user?.avatarUrl;

    // Check if country is set, if not show modal
    // Only check once per session or if user specifically is loaded but has no country
    if (user != null && user.country == null && !_hasCheckedCountry) {
      _hasCheckedCountry = true; // Mark as checked to prevent loop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const CountrySelectionModal(),
        ).then((_) {
          // Reset check if modal is dismissed without selection significantly?
          // Or leave it true to avoid pestering until next restart.
          // If user selected, user.country won't be null, so it won't trigger anyway.
        });
      });
    }

    // Listen for new notifications to show overlay
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

        // Content
        Expanded(
          child: CustomRefreshWrapper(
            onRefresh: () async {
              ref.invalidate(balanceProvider);
              ref.invalidate(cryptoListProvider);
              await Future.delayed(const Duration(seconds: 2));
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Balance Card
                  FadeInSlide(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 100),
                    child: Builder(builder: (context) {
                      final currency = user?.currency ?? 'NGN';
                      String symbol = '₦';

                      // Use ForexService for conversion
                      final forexService = ref.read(forexServiceProvider);
                      final forexRate = forexService.convert(
                          balanceState.totalBalance, currency);

                      // Determine symbol
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

                  const SizedBox(height: 24),

                  // Quick Action Buttons
                  FadeInSlide(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 200),
                    child: Row(
                      children: [
                        Expanded(
                          child: QuickActionButton(
                            label: 'Buy/Sell Crypto',
                            icon: Icons.swap_horiz,
                            isPrimary: true,
                            onTap: () {
                              // Switch to Buy/Sell Crypto Tab (Index 2)
                              ref.read(navigationProvider.notifier).setIndex(2);
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
                                SlidePageRoute(page: const GiftCardsScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Transaction History Link
                  FadeInSlide(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          SlidePageRoute(
                            page: const TransactionHistoryScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.history,
                                color: AppColors.primaryOrange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transaction History',
                                    style: AppTextStyles.titleMedium(context),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'View all your past activities',
                                    style: AppTextStyles.bodySmall(context)
                                        .copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.textTertiary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Market Trends Section
                  const SizedBox(height: 32),
                  FadeInSlide(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      'Market Trends',
                      style: AppTextStyles.titleMedium(context),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Crypto List
                  FadeInSlide(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 500),
                    child: cryptoListAsync.when(
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
                                    SlidePageRoute(
                                      page: CryptoDetailsScreen(
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
                      loading: () => const CryptoCardSkeletonList(count: 3),
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
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        )
      ],
    );
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
