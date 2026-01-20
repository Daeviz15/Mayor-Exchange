import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_handler_utils.dart';
import '../providers/crypto_providers.dart';
import '../widgets/price_chart_widget.dart';
import '../widgets/crypto_data_card.dart';
import '../widgets/crypto_details_skeleton.dart';
import '../../transactions/screens/buy_sell_crypto_screen.dart';
import '../../transactions/models/transaction.dart';
import '../../dasboard/screens/settings_screen.dart';

/// Crypto Details Screen
/// Detailed view and trading interface for a cryptocurrency
class CryptoDetailsScreen extends ConsumerStatefulWidget {
  final String cryptoSymbol;

  const CryptoDetailsScreen({
    super.key,
    required this.cryptoSymbol,
  });

  @override
  ConsumerState<CryptoDetailsScreen> createState() =>
      _CryptoDetailsScreenState();
}

class _CryptoDetailsScreenState extends ConsumerState<CryptoDetailsScreen> {
  bool _isBuyOrder = true;

  @override
  Widget build(BuildContext context) {
    final cryptoDetailsAsync =
        ref.watch(cryptoDetailsProvider(widget.cryptoSymbol));
    final selectedTimeRange = ref.watch(selectedTimeRangeProvider);

    return cryptoDetailsAsync.when(
      data: (cryptoDetails) {
        final isPositive = cryptoDetails.change24h >= 0;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button & Pair Selector
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              // Show crypto pair selector
                            },
                            child: Row(
                              children: [
                                Text(
                                  cryptoDetails.pair,
                                  style: AppTextStyles.titleLarge(context),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Profile Icon
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Price and Change
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, -10 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$${cryptoDetails.currentPrice.toStringAsFixed(2)}',
                                style: AppTextStyles.displayLarge(context)
                                    .copyWith(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    isPositive
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    size: 16,
                                    color: isPositive
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isPositive ? '+' : ''}\$${cryptoDetails.change24h.toStringAsFixed(2)} (${isPositive ? '+' : ''}${cryptoDetails.changePercent24h.toStringAsFixed(2)}%) 24H',
                                    style: AppTextStyles.percentageChange(
                                      context,
                                      isPositive,
                                    ).copyWith(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Price Chart
                        PriceChartWidget(
                          cryptoSymbol: widget.cryptoSymbol,
                          selectedRange: selectedTimeRange,
                          onRangeChanged: (range) {
                            ref.read(selectedTimeRangeProvider.notifier).state =
                                range;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Data Cards
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            CryptoDataCard(
                              label: '24h High',
                              value:
                                  '\$${cryptoDetails.high24h.toStringAsFixed(2)}',
                              icon: Icons.arrow_upward,
                            ),
                            CryptoDataCard(
                              label: '24h Low',
                              value:
                                  '\$${cryptoDetails.low24h.toStringAsFixed(2)}',
                              icon: Icons.arrow_downward,
                            ),
                            CryptoDataCard(
                              label: 'Volume (${cryptoDetails.symbol})',
                              value:
                                  '${_formatNumber(cryptoDetails.volumeBTC)} ${cryptoDetails.symbol}',
                              icon: Icons.bar_chart,
                            ),
                            CryptoDataCard(
                              label: 'Volume (USD)',
                              value:
                                  '\$${_formatVolume(cryptoDetails.volumeUSD)}',
                              icon: Icons.attach_money,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Buy/Sell Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                label: 'Buy',
                                isPrimary: true,
                                isSelected: _isBuyOrder,
                                onTap: () {
                                  setState(() {
                                    _isBuyOrder = true;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                label: 'Sell',
                                isPrimary: false,
                                isSelected: !_isBuyOrder,
                                onTap: () {
                                  setState(() {
                                    _isBuyOrder = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Order Form
                        // Trade Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BuySellCryptoScreen(
                                    initialType: _isBuyOrder
                                        ? TransactionType.buyCrypto
                                        : TransactionType.sellCrypto,
                                    initialAsset: cryptoDetails.symbol,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              _isBuyOrder
                                  ? 'Buy ${cryptoDetails.symbol}'
                                  : 'Sell ${cryptoDetails.symbol}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
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
        );
      },
      loading: () => const CryptoDetailsSkeleton(),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load crypto data',
                style: AppTextStyles.titleMedium(context),
              ),
              const SizedBox(height: 8),
              Text(
                ErrorHandlerUtils.getUserFriendlyErrorMessage(error),
                style: AppTextStyles.bodySmall(context)
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(cryptoDetailsProvider(widget.cryptoSymbol));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(1)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toStringAsFixed(0);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPrimary ? AppColors.success : AppColors.error)
              : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.titleMedium(context).copyWith(
              fontWeight: FontWeight.w700,
              color:
                  isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
