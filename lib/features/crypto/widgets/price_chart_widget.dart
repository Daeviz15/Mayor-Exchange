import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../models/crypto_details.dart';
import '../providers/crypto_providers.dart';

/// Price Chart Widget
/// Displays cryptocurrency price chart with time range selectors
class PriceChartWidget extends ConsumerWidget {
  final String cryptoSymbol;
  final TimeRange selectedRange;
  final Function(TimeRange) onRangeChanged;

  const PriceChartWidget({
    super.key,
    required this.cryptoSymbol,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(
      chartDataProvider(ChartDataParams(
        symbol: cryptoSymbol,
        range: selectedRange,
      )),
    );

    return chartDataAsync.when(
      data: (priceHistory) {
        if (priceHistory.isEmpty) {
          return const Center(
            child: Text(
              'No chart data available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final isPositive = priceHistory.isNotEmpty &&
            priceHistory.last.price >= priceHistory.first.price;
        final chartColor = isPositive ? AppColors.chartGreen : AppColors.chartRed;
        final chartData = _convertToFlSpots(priceHistory);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            children: [
              // Chart
              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppColors.divider,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '\$${value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData,
                        isCurved: true,
                        color: chartColor,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: chartColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                    minY: chartData.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.98,
                    maxY: chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.02,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Time Range Selectors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TimeRangeButton(
                    label: '1H',
                    range: TimeRange.oneHour,
                    isSelected: selectedRange == TimeRange.oneHour,
                    onTap: () => onRangeChanged(TimeRange.oneHour),
                  ),
                  _TimeRangeButton(
                    label: '24H',
                    range: TimeRange.twentyFourHours,
                    isSelected: selectedRange == TimeRange.twentyFourHours,
                    onTap: () => onRangeChanged(TimeRange.twentyFourHours),
                  ),
                  _TimeRangeButton(
                    label: '1W',
                    range: TimeRange.oneWeek,
                    isSelected: selectedRange == TimeRange.oneWeek,
                    onTap: () => onRangeChanged(TimeRange.oneWeek),
                  ),
                  _TimeRangeButton(
                    label: '1M',
                    range: TimeRange.oneMonth,
                    isSelected: selectedRange == TimeRange.oneMonth,
                    onTap: () => onRangeChanged(TimeRange.oneMonth),
                  ),
                  _TimeRangeButton(
                    label: '1Y',
                    range: TimeRange.oneYear,
                    isSelected: selectedRange == TimeRange.oneYear,
                    onTap: () => onRangeChanged(TimeRange.oneYear),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryOrange,
          ),
        ),
      ),
      error: (error, stack) => Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load chart',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _convertToFlSpots(List<PricePoint> priceHistory) {
    return priceHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();
  }
}

class _TimeRangeButton extends StatelessWidget {
  final String label;
  final TimeRange range;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeRangeButton({
    required this.label,
    required this.range,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange
              : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

