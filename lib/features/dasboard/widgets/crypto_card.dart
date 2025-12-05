import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/crypto_data.dart';

/// Crypto Card Widget
/// Displays cryptocurrency information with chart
class CryptoCard extends StatelessWidget {
  final CryptoData crypto;
  final VoidCallback? onTap;

  const CryptoCard({super.key, required this.crypto, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPositive = crypto.changePercent >= 0;
    final chartColor = isPositive ? AppColors.chartGreen : AppColors.chartRed;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Crypto Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: crypto.iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: crypto.iconUrl != null && crypto.iconUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: crypto.iconUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          memCacheWidth: 96, // Reduce memory usage
                          memCacheHeight: 96,
                          maxWidthDiskCache: 200,
                          maxHeightDiskCache: 200,
                          cacheKey: 'crypto_icon_${crypto.symbol}',
                          placeholder: (context, url) => Container(
                            color: crypto.iconColor,
                            child: Center(
                              child: Text(
                                crypto.iconLetter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: crypto.iconColor,
                            child: Center(
                              child: Text(
                                crypto.iconLetter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: crypto.iconColor,
                          child: Center(
                            child: Text(
                              crypto.iconLetter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Crypto Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(crypto.name, style: AppTextStyles.titleSmall(context)),
                    const SizedBox(height: 4),
                    Text(
                      crypto.symbol,
                      style: AppTextStyles.bodySmall(context),
                    ),
                  ],
                ),
              ),
              // Chart
              SizedBox(
                width: 60,
                height: 30,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generateSpots(crypto.chartData),
                        isCurved: true,
                        color: chartColor,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: chartColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                    minY:
                        crypto.chartData.reduce((a, b) => a < b ? a : b) * 0.95,
                    maxY:
                        crypto.chartData.reduce((a, b) => a > b ? a : b) * 1.05,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Price and Change
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${crypto.price.toStringAsFixed(2)}',
                    style: AppTextStyles.cryptoPrice(context),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: chartColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${isPositive ? '+' : ''}${crypto.changePercent.toStringAsFixed(2)}%',
                        style: AppTextStyles.percentageChange(
                          context,
                          isPositive,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots(List<double> data) {
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }
}
