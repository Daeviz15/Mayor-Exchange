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

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    child: BalanceCard(
                      balance: balanceState.totalBalance,
                      changePercent: balanceState.changePercent24h,
                      onViewPortfolio: () {
                        // Note: This pushes a new Portfolio Screen on top
                        // If user wants to switch tab instead, we would need to access navigationProvider
                        // For now, keeping as push for specific "View Portfolio" action,
                        // or we can switch tab. Let's switch tab for consistency if requested.
                        // But for now, let's keep push to avoid circular dependency or complex callback passing.
                        Navigator.push(
                          context,
                          SlidePageRoute(page: const PortfolioScreen()),
                        );
                      },
                    ),
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
                              // Navigate to trade tab? Or distinct screen?
                              // Usually Trade Tab index 2
                              // We can' easily switch tab here without ref access to nav provider
                              // inside a purely stateless composition unless we pass it.
                              // For now, let's leave as placeholder or push screen.
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
