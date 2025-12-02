import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Balance Card Widget
/// Displays user's total balance with percentage change
class BalanceCard extends StatelessWidget {
  final double balance;
  final double changePercent;
  final VoidCallback? onViewPortfolio;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.changePercent,
    this.onViewPortfolio,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = changePercent >= 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Balance',
                  style: AppTextStyles.labelMedium(context),
                ),
                if (onViewPortfolio != null)
                  TextButton(
                    onPressed: onViewPortfolio,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View Portfolio',
                      style: AppTextStyles.labelMedium(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: balance),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) {
                return Text(
                  '\$${animatedValue.toStringAsFixed(2)}',
                  style: AppTextStyles.balanceAmount(context),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}% in last 24h',
                  style: AppTextStyles.percentageChange(context, isPositive),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
