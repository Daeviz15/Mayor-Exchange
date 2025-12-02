import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/crypto_details.dart';
import '../services/coingecko_service.dart';
import '../../dasboard/models/crypto_data.dart';
import '../../../core/theme/app_colors.dart';

/// Crypto List Provider
/// Provides real-time list of cryptocurrencies for dashboard
final cryptoListProvider = FutureProvider<List<CryptoData>>((ref) async {
  try {
    final marketData = await CoinGeckoService.getMarketData();

    // Fetch chart data for each coin (24h data for dashboard cards)
    final List<CryptoData> cryptoList = [];

    for (final data in marketData) {
      final chartData = await CoinGeckoService.getHistoricalData(
        data.symbol,
        TimeRange.twentyFourHours,
      );

      // Extract prices for chart (last 7 points for mini chart)
      final prices = chartData.map((point) => point.price).toList();
      final chartPoints = prices.length > 7
          ? prices.sublist(prices.length - 7)
          : prices;

      // If we don't have enough data, pad with current price
      while (chartPoints.length < 7) {
        chartPoints.insert(0, data.currentPrice);
      }

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

    return cryptoList;
  } catch (e) {
    // Return empty list on error, or you could return cached data
    return [];
  }
});

/// Crypto Details Provider
/// Provides detailed real-time crypto information by symbol
final cryptoDetailsProvider = FutureProvider.family<CryptoDetails, String>((
  ref,
  symbol,
) async {
  try {
    final coinDetails = await CoinGeckoService.getCoinDetails(symbol);
    final chartData = await CoinGeckoService.getHistoricalData(
      symbol,
      TimeRange.twentyFourHours,
    );

    // Convert CoinGecko price points to PricePoint model
    final priceHistory = chartData
        .map((point) => PricePoint(time: point.time, price: point.price))
        .toList();

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
        final chartData = await CoinGeckoService.getHistoricalData(
          params.symbol,
          params.range,
        );

        return chartData
            .map((point) => PricePoint(time: point.time, price: point.price))
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
