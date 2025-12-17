import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../portfolio/providers/portfolio_provider.dart';

class AssetList extends StatelessWidget {
  final List<PortfolioItem> items;

  const AssetList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Assets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _AssetTile(item: item);
          },
        ),
      ],
    );
  }
}

class _AssetTile extends StatelessWidget {
  final PortfolioItem item;

  const _AssetTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Icon / Emoji
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.isFiat
                  ? const Color(0xFFE8F5E9)
                  : AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: item.isFiat
                ? const Text(
                    '🇳🇬', // Nigeria Flag for Naira
                    style: TextStyle(fontSize: 24),
                  )
                : (item.iconUrl != null
                    ? Image.network(item.iconUrl!, width: 24, height: 24)
                    : const Icon(Icons.currency_bitcoin,
                        color: AppColors.primaryOrange)),
          ),
          const SizedBox(width: 16),

          // Name and Quantity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity.toStringAsFixed(item.isFiat ? 2 : 6)} ${item.symbol}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦${item.valueInNaira.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Mock 24h change
              Text(
                item.isFiat ? 'Stable' : '+1.2%',
                style: TextStyle(
                  fontSize: 12,
                  color: item.isFiat
                      ? AppColors.textSecondary
                      : Colors.greenAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
