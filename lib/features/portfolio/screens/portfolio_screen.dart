import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animations/fade_in_slide.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/portfolio_summary_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../../transactions/services/forex_service.dart';
import '../../wallet/screens/withdrawal_screen.dart';
import '../../dasboard/widgets/transaction_short_list.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final portfolioState = ref.watch(portfolioProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value;

    const currency = 'NGN'; // Hardcoded - country selection coming in v2.0
    // Use ForexService for conversion
    final forexService = ref.read(forexServiceProvider);
    final convertedBalance =
        forexService.convert(portfolioState.totalValue, currency);

    String symbol = '₦';

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

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Portfolio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Worth Card
            FadeInSlide(
              duration: const Duration(milliseconds: 600),
              child: PortfolioSummaryCard(
                totalBalance: convertedBalance,
                symbol: symbol,
                isVisible: _isBalanceVisible,
                onToggleVisibility: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                },
              ),
            ),

            const SizedBox(height: 32),

            // Wallet Actions (Withdraw Only)
            FadeInSlide(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
              child: _buildWalletActionButton(
                context,
                label: 'Withdraw Funds',
                icon: Icons.arrow_outward_rounded,
                color: AppColors
                    .primaryOrange, // Use primary color for main action
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WithdrawalScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // text "Recent Activity" is removed here because TransactionShortList likely has its own or we rely on the list's header.
            // Actually, TransactionShortList has "Recent Transactions" and "View all".
            // So we don't need a text header here.

            // Transaction List
            const FadeInSlide(
              duration: Duration(milliseconds: 600),
              delay: Duration(milliseconds: 400),
              child: TransactionShortList(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20), // More height
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          // Changed to Row for expanded button look
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.titleMedium(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
