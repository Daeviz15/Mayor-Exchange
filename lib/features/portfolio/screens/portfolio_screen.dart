import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animations/fade_in_slide.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/asset_allocation_chart.dart';
import '../widgets/asset_list.dart';
import '../widgets/portfolio_summary_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../../transactions/services/forex_service.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    // Use mock provider for demonstration of "sleek UI" if real data is empty
    // But ideally we use portfolioProvider. Let's use mockPortfolioProvider to ensure
    // the user sees the charts populated as they requested "make it excellent".
    // Switches to portfolioProvider later.
    final portfolioState = ref.watch(portfolioProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value;

    final currency = user?.currency ?? 'NGN';
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

            const SizedBox(height: 24),

            // Allocation Chart
            FadeInSlide(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
              child: AssetAllocationChart(
                fiatPercentage: portfolioState.fiatPercentage,
                cryptoPercentage: portfolioState.cryptoPercentage,
              ),
            ),

            const SizedBox(height: 32),

            // Asset List
            FadeInSlide(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 400),
              direction: SlideDirection.right,
              child: AssetList(items: portfolioState.items),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
