import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/coingecko_models.dart';
import '../models/crypto_details.dart';

/// CoinCap API Service
/// Handles all API calls to CoinCap for real-time cryptocurrency data
class CoinCapService {
  static const String _baseUrl = 'https://api.coincap.io/v2';

  // Get API key from environment
  static String? get _apiKey => dotenv.env['COINCAP_API_KEY'];

  // Mapping of symbols to CoinCap IDs (lowercase)
  static const Map<String, String> _coinIds = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'SOL': 'solana',
  };

  /// Get CoinCap ID from symbol
  static String? _getCoinId(String symbol) {
    return _coinIds[symbol.toUpperCase()];
  }

  /// Get symbol from coin ID
  static String? _getSymbolFromId(String coinId) {
    for (final entry in _coinIds.entries) {
      if (entry.value == coinId) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get headers with API key if available
  static Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_apiKey != null &&
        _apiKey!.isNotEmpty &&
        _apiKey != 'YOUR_COINCAP_API_KEY_HERE') {
      headers['Authorization'] = 'Bearer $_apiKey';
      debugPrint('🔑 CoinCap: Using API key for authenticated requests');
    } else {
      debugPrint(
        '⚠️  CoinCap: No API key found, using free tier (limited requests)',
      );
    }

    return headers;
  }

  /// Fetch market data for multiple cryptocurrencies
  /// Returns list of market data for BTC, ETH, and SOL
  static Future<List<CoinGeckoMarketData>> getMarketData() async {
    try {
      final coinIds = _coinIds.values.join(',');
      final url = Uri.parse('$_baseUrl/assets?ids=$coinIds');

      debugPrint('🌐 CoinCap API: Requesting market data from: $url');
      final response = await http.get(url, headers: _getHeaders());
      debugPrint('📡 CoinCap API: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] as List<dynamic>;
        final List<CoinGeckoMarketData> marketData = [];

        for (final coinData in data) {
          final coinId = coinData['id'] as String;
          final symbol = _getSymbolFromId(coinId);

          if (symbol != null) {
            // Parse CoinCap response to fit existing model
            final currentPrice =
                double.tryParse(coinData['priceUsd']?.toString() ?? '0') ?? 0.0;
            final priceChangePercent24h =
                double.tryParse(
                  coinData['changePercent24Hr']?.toString() ?? '0',
                ) ??
                0.0;
            final priceChange24h = currentPrice * (priceChangePercent24h / 100);

            marketData.add(
              CoinGeckoMarketData(
                id: coinId,
                symbol: symbol,
                name: coinData['name'] as String? ?? _getCoinName(symbol),
                currentPrice: currentPrice,
                priceChange24h: priceChange24h,
                priceChangePercent24h: priceChangePercent24h,
                high24h:
                    currentPrice *
                    1.02, // CoinCap doesn't provide high/low, approximate
                low24h: currentPrice * 0.98,
                volume24h:
                    double.tryParse(
                      coinData['volumeUsd24Hr']?.toString() ?? '0',
                    ) ??
                    0.0,
                marketCap:
                    double.tryParse(
                      coinData['marketCapUsd']?.toString() ?? '0',
                    ) ??
                    0.0,
                lastUpdated: DateTime.now(),
              ),
            );
          }
        }

        // Sort to maintain BTC, ETH, SOL order
        marketData.sort((a, b) {
          final order = ['BTC', 'ETH', 'SOL'];
          final aIndex = order.indexOf(a.symbol);
          final bIndex = order.indexOf(b.symbol);
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;
          return aIndex.compareTo(bIndex);
        });

        debugPrint(
          '✅ CoinCap API: Successfully parsed ${marketData.length} coins',
        );
        return marketData;
      } else {
        debugPrint('❌ CoinCap API: Failed with status ${response.statusCode}');
        debugPrint('📄 Response body: ${response.body}');
        throw Exception('Failed to load market data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ CoinCap API: Exception in getMarketData: $e');
      throw Exception('Error fetching market data: $e');
    }
  }

  /// Fetch detailed information for a specific cryptocurrency
  static Future<CoinGeckoCoinDetails> getCoinDetails(String symbol) async {
    try {
      final coinId = _getCoinId(symbol);
      if (coinId == null) {
        throw Exception('Unknown cryptocurrency symbol: $symbol');
      }

      final url = Uri.parse('$_baseUrl/assets/$coinId');

      debugPrint(
        '🌐 CoinCap API: Requesting coin details for $symbol from: $url',
      );
      final response = await http.get(url, headers: _getHeaders());
      debugPrint('📡 CoinCap API: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final coinData = responseData['data'];

        final currentPrice =
            double.tryParse(coinData['priceUsd']?.toString() ?? '0') ?? 0.0;
        final priceChangePercent24h =
            double.tryParse(coinData['changePercent24Hr']?.toString() ?? '0') ??
            0.0;
        final priceChange24h = currentPrice * (priceChangePercent24h / 100);

        return CoinGeckoCoinDetails(
          id: coinId,
          symbol: symbol,
          name: coinData['name'] as String? ?? _getCoinName(symbol),
          currentPrice: currentPrice,
          priceChange24h: priceChange24h,
          priceChangePercent24h: priceChangePercent24h,
          high24h: currentPrice * 1.02,
          low24h: currentPrice * 0.98,
          volume24h:
              double.tryParse(coinData['volumeUsd24Hr']?.toString() ?? '0') ??
              0.0,
          marketCap:
              double.tryParse(coinData['marketCapUsd']?.toString() ?? '0') ??
              0.0,
          lastUpdated: DateTime.now(),
        );
      } else {
        throw Exception('Failed to load coin details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching coin details: $e');
    }
  }

  /// Fetch historical price data for chart
  /// Returns list of price points for the specified time range
  static Future<List<CoinGeckoPricePoint>> getHistoricalData(
    String symbol,
    TimeRange range,
  ) async {
    try {
      final coinId = _getCoinId(symbol);
      if (coinId == null) {
        throw Exception('Unknown cryptocurrency symbol: $symbol');
      }

      // Calculate interval based on time range
      final String interval = switch (range) {
        TimeRange.oneHour => 'm5', // 5-minute intervals
        TimeRange.twentyFourHours => 'h1', // 1-hour intervals
        TimeRange.oneWeek => 'h6', // 6-hour intervals
        TimeRange.oneMonth => 'd1', // 1-day intervals
        TimeRange.oneYear => 'd1', // 1-day intervals
      };

      // Calculate start and end times
      final now = DateTime.now();
      final DateTime startTime = switch (range) {
        TimeRange.oneHour => now.subtract(const Duration(hours: 1)),
        TimeRange.twentyFourHours => now.subtract(const Duration(hours: 24)),
        TimeRange.oneWeek => now.subtract(const Duration(days: 7)),
        TimeRange.oneMonth => now.subtract(const Duration(days: 30)),
        TimeRange.oneYear => now.subtract(const Duration(days: 365)),
      };

      final url = Uri.parse(
        '$_baseUrl/assets/$coinId/history?interval=$interval&start=${startTime.millisecondsSinceEpoch}&end=${now.millisecondsSinceEpoch}',
      );

      debugPrint(
        '🌐 CoinCap API: Requesting historical data for $symbol from: $url',
      );
      final response = await http.get(url, headers: _getHeaders());
      debugPrint('📡 CoinCap API: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] as List<dynamic>;

        final List<CoinGeckoPricePoint> pricePoints = [];

        for (final priceData in data) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            priceData['time'] as int,
          );
          final price =
              double.tryParse(priceData['priceUsd']?.toString() ?? '0') ?? 0.0;

          pricePoints.add(CoinGeckoPricePoint(time: timestamp, price: price));
        }

        debugPrint(
          '✅ CoinCap API: Received ${pricePoints.length} price points',
        );
        return pricePoints;
      } else {
        debugPrint('❌ CoinCap API: Failed with status ${response.statusCode}');
        debugPrint('📄 Response body: ${response.body}');
        throw Exception(
          'Failed to load historical data: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ CoinCap API: Exception in getHistoricalData: $e');
      throw Exception('Error fetching historical data: $e');
    }
  }

  /// Get coin name from symbol
  static String _getCoinName(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'BTC':
        return 'Bitcoin';
      case 'ETH':
        return 'Ethereum';
      case 'SOL':
        return 'Solana';
      default:
        return symbol;
    }
  }
}
