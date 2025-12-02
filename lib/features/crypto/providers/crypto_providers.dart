import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:math';
import '../models/crypto_details.dart';
import '../services/coingecko_service.dart';
import '../../dasboard/models/crypto_data.dart';
import '../../../core/theme/app_colors.dart';

/// Crypto List Provider
/// Provides real-time list of cryptocurrencies for dashboard
final cryptoListProvider = FutureProvider<List<CryptoData>>((ref) async {
  try {
    debugPrint('🔍 CryptoListProvider: Fetching crypto market data...');
    final marketData = await CoinGeckoService.getMarketData();
    debugPrint(
      '✅ CryptoListProvider: Received ${marketData.length} coins from API',
    );

    // Generate chart data for each coin (no historical API call needed)
    final List<CryptoData> cryptoList = [];

    for (final data in marketData) {
      debugPrint(
        '📊 CryptoListProvider: Generating chart data for ${data.symbol}...',
      );

      // Generate 7 price points for mini chart based on current price and 24h change
      final chartPoints = _generateChartData(
        data.currentPrice,
        data.priceChangePercent24h,
      );

      debugPrint(
        '✅ CryptoListProvider: Generated ${chartPoints.length} price points for ${data.symbol}',
      );

      cryptoList.add(
        CryptoData(
          symbol: data.symbol,
          name: data.name,
          price: data.currentPrice,
          changePercent: data.priceChangePercent24h,
          iconColor: _getIconColor(data.symbol),
          iconLetter: _getIconLetter(data.symbol),
          chartData: chartPoints,
        ),
      );
    }

    debugPrint(
      '🎉 CryptoListProvider: Successfully loaded ${cryptoList.length} cryptocurrencies',
    );
    return cryptoList;
  } catch (e, stackTrace) {
    // Log the actual error for debugging
    debugPrint('❌ CryptoListProvider ERROR: $e');
    debugPrint('📍 Stack trace: $stackTrace');

    // Return empty list to prevent app crash, but error is now visible in console
    debugPrint(
      '⚠️  Returning empty list due to error. Check the error above for details.',
    );
    return [];
  }
});

/// Generate realistic chart data based on current price and 24h change
List<double> _generateChartData(double currentPrice, double changePercent24h) {
  final random = Random();
  final List<double> chartPoints = [];

  // Calculate the starting price (24 hours ago)
  final startPrice = currentPrice / (1 + (changePercent24h / 100));

  // Generate 7 points showing progression from start to current price
  for (int i = 0; i < 7; i++) {
    // Linear progression with some randomness for realistic look
    final progress = i / 6; // 0.0 to 1.0
    final basePrice = startPrice + (currentPrice - startPrice) * progress;

    // Add small random variation (±2%)
    final variation = (random.nextDouble() - 0.5) * 0.04 * basePrice;
    final price = basePrice + variation;

    chartPoints.add(price);
  }

  return chartPoints;
}

/// Crypto Details Provider
/// Provides detailed real-time crypto information by symbol
final cryptoDetailsProvider = FutureProvider.family<CryptoDetails, String>((
  ref,
  symbol,
) async {
  try {
    final coinDetails = await CoinGeckoService.getCoinDetails(symbol);

    // Generate chart data (7 points for detailed view)
    final chartPrices = _generateChartData(
      coinDetails.currentPrice,
      coinDetails.priceChangePercent24h,
    );

    // Convert to PricePoint list with timestamps
    final now = DateTime.now();
    final priceHistory = <PricePoint>[];
    for (int i = 0; i < chartPrices.length; i++) {
      priceHistory.add(
        PricePoint(
          time: now.subtract(Duration(hours: chartPrices.length - i)),
          price: chartPrices[i],
        ),
      );
    }

    return CryptoDetails(
      symbol: coinDetails.symbol,
      name: coinDetails.name,
      pair: '${coinDetails.symbol}/USD',
      currentPrice: coinDetails.currentPrice,
      change24h: coinDetails.priceChange24h,
      changePercent24h: coinDetails.priceChangePercent24h,
      high24h: coinDetails.high24h,
      low24h: coinDetails.low24h,
      volumeBTC:
          coinDetails.volume24h / coinDetails.currentPrice, // Approximate
      volumeUSD: coinDetails.volume24h,
      accentColor: _getIconColor(coinDetails.symbol),
      priceHistory: priceHistory,
    );
  } catch (e) {
    // Return a default/error state or rethrow
    rethrow;
  }
});

/// Historical Chart Data Provider
/// Provides chart data for a specific symbol and time range
final chartDataProvider =
    FutureProvider.family<List<PricePoint>, ChartDataParams>((
      ref,
      params,
    ) async {
      try {
        // Generate chart data instead of fetching
        final chartPrices = _generateChartData(
          params.symbol == 'BTC'
              ? 90000.0
              : params.symbol == 'ETH'
              ? 3000.0
              : 140.0, // Approximate current price
          params.symbol == 'BTC'
              ? 5.0
              : params.symbol == 'ETH'
              ? 7.0
              : 10.0, // Approximate 24h change
        );

        return chartPrices
            .map(
              (price) => PricePoint(
                time: DateTime.now().subtract(
                  Duration(
                    hours: chartPrices.length - chartPrices.indexOf(price),
                  ),
                ),
                price: price,
              ),
            )
            .toList();
      } catch (e) {
        return [];
      }
    });

/// Chart Data Parameters
class ChartDataParams {
  final String symbol;
  final TimeRange range;

  ChartDataParams({required this.symbol, required this.range});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartDataParams &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          range == other.range;

  @override
  int get hashCode => symbol.hashCode ^ range.hashCode;
}

/// Helper function to get icon color
Color _getIconColor(String symbol) {
  switch (symbol.toUpperCase()) {
    case 'BTC':
      return AppColors.btcBackground;
    case 'ETH':
      return AppColors.ethBackground;
    case 'SOL':
      return AppColors.solBackground;
    default:
      return AppColors.primaryOrange;
  }
}

/// Helper function to get icon letter
String _getIconLetter(String symbol) {
  return symbol.substring(0, 1).toUpperCase();
}

/// Selected Time Range Provider
final selectedTimeRangeProvider =
    StateNotifierProvider<TimeRangeNotifier, TimeRange>((ref) {
      return TimeRangeNotifier();
    });

class TimeRangeNotifier extends StateNotifier<TimeRange> {
  TimeRangeNotifier() : super(TimeRange.twentyFourHours);

  void setRange(TimeRange range) {
    state = range;
  }
}

/// Order Type Provider
final orderTypeProvider = StateNotifierProvider<OrderTypeNotifier, OrderType>((
  ref,
) {
  return OrderTypeNotifier();
});

class OrderTypeNotifier extends StateNotifier<OrderType> {
  OrderTypeNotifier() : super(OrderType.market);

  void setType(OrderType type) {
    state = type;
  }
}

/// Buy/Sell Mode Provider
final buySellModeProvider = StateNotifierProvider<BuySellModeNotifier, bool>((
  ref,
) {
  return BuySellModeNotifier();
});

class BuySellModeNotifier extends StateNotifier<bool> {
  BuySellModeNotifier() : super(true); // true = Buy

  void setMode(bool isBuy) {
    state = isBuy;
  }
}
