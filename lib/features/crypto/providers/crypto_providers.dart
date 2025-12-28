import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'dart:math';
import 'dart:convert';
import '../models/crypto_details.dart';
import '../services/coingecko_service.dart';
import '../../dasboard/models/crypto_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/shared_preferences_provider.dart';

/// Crypto List Provider
/// Provides real-time list of cryptocurrencies for dashboard with caching
final cryptoListProvider =
    AsyncNotifierProvider<CryptoListNotifier, List<CryptoData>>(() {
  return CryptoListNotifier();
});

class CryptoListNotifier extends AsyncNotifier<List<CryptoData>> {
  @override
  List<CryptoData> build() {
    // 1. Load from cache synchronously
    final cachedData = _loadFromCacheSync();

    // 2. Trigger fresh fetch in background (post-frame to avoid build side-effects)
    Future.microtask(() => _fetchFreshData());

    // 3. Return cached data immediately (or empty list if none)
    // This sets the initial state to AsyncData(cachedData)
    return cachedData;
  }

  List<CryptoData> _loadFromCacheSync() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final jsonString = prefs.getString('cached_crypto_list');
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList
            .map((e) => CryptoData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Debug removed
    }
    return [];
  }

  Future<void> _fetchFreshData({bool forceRefresh = false}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Show loading only if we have no data yet
    if (state.asData?.value.isEmpty ?? true) {
      state = const AsyncLoading();
    }

    try {
      // Debug removed
      final marketData = await CoinGeckoService.getMarketData();

      final List<CryptoData> cryptoList = [];

      final fetchTime = DateTime.now();

      for (final data in marketData) {
        final chartPoints = _generateChartData(
          data.currentPrice,
          data.priceChangePercent24h,
        );

        cryptoList.add(
          CryptoData(
            id: data.id,
            symbol: data.symbol,
            name: data.name,
            price: data.currentPrice,
            changePercent: data.priceChangePercent24h,
            iconColor: _getIconColor(data.symbol),
            iconLetter: _getIconLetter(data.symbol),
            iconUrl: data.imageUrl.isNotEmpty ? data.imageUrl : null,
            chartData: chartPoints,
            lastUpdated: fetchTime,
          ),
        );
      }

      // Update Cache
      final jsonString = jsonEncode(cryptoList.map((e) => e.toJson()).toList());
      await prefs.setString('cached_crypto_list', jsonString);
      await prefs.setInt('last_crypto_fetch_time', now);

      // Update State
      state = AsyncData(cryptoList);
    } catch (e, stack) {
      // Debug removed
      // If we have cached data, we keep it but maybe show a snackbar (UI responsibility)
      // or we set state to Error only if we have no data?
      if (state.asData?.value.isEmpty ?? true) {
        state = AsyncError(e, stack);
      }
      // If we have data, we silently fail the refresh (or could use a side-channel for errors)
    }
  }

  /// Manually trigger a refresh (e.g. Pull-to-Refresh)
  Future<void> refresh() async {
    await _fetchFreshData(forceRefresh: true);
  }
}

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
