import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../models/crypto_details.dart';
import '../providers/crypto_providers.dart';
import 'price_chart_skeleton.dart';

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
      chartDataProvider(
        ChartDataParams(symbol: cryptoSymbol, range: selectedRange),
      ),
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

        final isPositive =
            priceHistory.isNotEmpty &&
            priceHistory.last.price >= priceHistory.first.price;
        final chartColor = isPositive
            ? AppColors.chartGreen
            : AppColors.chartRed;
        final chartData = _convertToFlSpots(priceHistory);

        // Calculate min and max for Y axis to add some padding
        final minY = chartData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
        final maxY = chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
        final padding = (maxY - minY) * 0.1;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
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
          child: Column(
            children: [
              // Chart
              Container(
                height: 280, // Increased height for better visibility
                padding: const EdgeInsets.fromLTRB(0, 24, 16, 0),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (maxY - minY) / 4,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppColors.divider.withValues(alpha: 0.05),
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
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            if (value == minY || value == maxY)
                              return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                '\$${value.toStringAsFixed(value < 1 ? 4 : 0)}',
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData,
                        isCurved: true,
                        curveSmoothness: 0.2,
                        color: chartColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              chartColor.withValues(alpha: 0.25),
                              chartColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) =>
                            AppColors.backgroundCard,
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: const EdgeInsets.all(12),
                        tooltipBorder: BorderSide(
                          color: AppColors.divider,
                          width: 1,
                        ),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final date = DateTime.fromMillisecondsSinceEpoch(
                              touchedSpot.x.toInt(),
                            );
                            return LineTooltipItem(
                              '\$${touchedSpot.y.toStringAsFixed(2)}\n',
                              const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                      getTouchedSpotIndicator:
                          (LineChartBarData barData, List<int> spotIndexes) {
                            return spotIndexes.map((spotIndex) {
                              return TouchedSpotIndicatorData(
                                FlLine(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                ),
                                FlDotData(
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 6,
                                          color: AppColors.backgroundCard,
                                          strokeWidth: 3,
                                          strokeColor: chartColor,
                                        );
                                      },
                                ),
                              );
                            }).toList();
                          },
                    ),
                    minY: minY - padding,
                    maxY: maxY + padding,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Time Range Selectors
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ),
            ],
          ),
        );
      },
      loading: () => const PriceChartSkeleton(),
      error: (error, stack) => Container(
        height: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 32),
              const SizedBox(height: 8),
              Text(
                'Failed to load chart',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _convertToFlSpots(List<PricePoint> priceHistory) {
    return priceHistory.map((point) {
      return FlSpot(point.time.millisecondsSinceEpoch.toDouble(), point.price);
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
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
