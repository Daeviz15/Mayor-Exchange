import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/cache_service.dart';
import '../models/coingecko_models.dart';
import '../models/crypto_details.dart';

/// CoinGecko API Service
/// Handles all API calls to CoinGecko for real-time cryptocurrency data
class CoinGeckoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  // Mapping of symbols to CoinGecko IDs
  static const Map<String, String> _coinIds = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'SOL': 'solana',
    'USDT': 'tether',
    'BNB': 'binancecoin',
    'XRP': 'ripple',
    'ADA': 'cardano',
    'DOGE': 'dogecoin',
    'TRX': 'tron',
    'DOT': 'polkadot',
  };

  /// Get CoinGecko ID from symbol
  static String? _getCoinId(String symbol) {
    return _coinIds[symbol.toUpperCase()];
  }

  /// Get headers for API requests
  static Map<String, String> _getHeaders() {
    final apiKey = dotenv.env['COINGECKO_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      return {'x-cg-demo-api-key': apiKey, 'Content-Type': 'application/json'};
    }
    return {'Content-Type': 'application/json'};
  }

  /// Fetch market data for multiple cryptocurrencies
  /// Returns list of market data for BTC, ETH, and SOL
  /// Uses cache to reduce API calls (5 minute cache duration)
  static Future<List<CoinGeckoMarketData>> getMarketData(
      {bool forceRefresh = false}) async {
    const cacheKey = 'coingecko_market_data';

    // Try to get from cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = await CacheService.getList<CoinGeckoMarketData>(
        cacheKey,
        (json) => CoinGeckoMarketData(
          id: json['id'] as String,
          symbol: json['symbol'] as String,
          name: json['name'] as String,
          currentPrice: (json['currentPrice'] as num).toDouble(),
          priceChange24h: (json['priceChange24h'] as num).toDouble(),
          priceChangePercent24h:
              (json['priceChangePercent24h'] as num).toDouble(),
          high24h: (json['high24h'] as num).toDouble(),
          low24h: (json['low24h'] as num).toDouble(),
          volume24h: (json['volume24h'] as num).toDouble(),
          marketCap: (json['marketCap'] as num).toDouble(),
          imageUrl: json['imageUrl'] as String,
          lastUpdated: DateTime.parse(json['lastUpdated'] as String),
        ),
      );

      if (cached != null && cached.isNotEmpty) {
        debugPrint('✅ CoinGecko API: Using cached market data');
        return cached;
      }
    }

    try {
      final coinIds = _coinIds.values.join(',');
      final url = Uri.parse(
        '$_baseUrl/coins/markets?vs_currency=usd&ids=$coinIds&order=market_cap_desc&per_page=20&page=1&sparkline=false&price_change_percentage=24h',
      );

      debugPrint('🌐 CoinGecko API: Requesting market data from: $url');
      final response = await http.get(url, headers: _getHeaders());
      debugPrint('📡 CoinGecko API: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<CoinGeckoMarketData> marketData = [];

        for (final coinData in data) {
          final coinId = coinData['id'] as String;
          final symbol = _getSymbolFromId(coinId);

          if (symbol != null) {
            marketData.add(
              CoinGeckoMarketData(
                id: coinId,
                symbol: symbol,
                name: coinData['name'] as String? ?? _getCoinName(symbol),
                currentPrice:
                    (coinData['current_price'] as num?)?.toDouble() ?? 0.0,
                priceChange24h:
                    (coinData['price_change_24h'] as num?)?.toDouble() ?? 0.0,
                priceChangePercent24h:
                    (coinData['price_change_percentage_24h'] as num?)
                            ?.toDouble() ??
                        0.0,
                high24h: (coinData['high_24h'] as num?)?.toDouble() ?? 0.0,
                low24h: (coinData['low_24h'] as num?)?.toDouble() ?? 0.0,
                volume24h:
                    (coinData['total_volume'] as num?)?.toDouble() ?? 0.0,
                marketCap: (coinData['market_cap'] as num?)?.toDouble() ?? 0.0,
                imageUrl: coinData['image'] as String? ?? '',
                lastUpdated: coinData['last_updated'] != null
                    ? DateTime.parse(coinData['last_updated'] as String)
                    : DateTime.now(),
              ),
            );
          }
        }

        // Sort to maintain specific order if needed, or just return as is
        marketData.sort((a, b) {
          final order = [
            'BTC',
            'ETH',
            'SOL',
            'BNB',
            'XRP',
            'ADA',
            'DOGE',
            'TRX',
            'DOT',
            'USDT',
          ];
          final aIndex = order.indexOf(a.symbol);
          final bIndex = order.indexOf(b.symbol);
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;
          return aIndex.compareTo(bIndex);
        });

        debugPrint(
          '✅ CoinGecko API: Successfully parsed ${marketData.length} coins',
        );

        // Cache the data for 5 minutes
        await CacheService.setList<CoinGeckoMarketData>(
          cacheKey,
          marketData,
          (data) => {
            'id': data.id,
            'symbol': data.symbol,
            'name': data.name,
            'currentPrice': data.currentPrice,
            'priceChange24h': data.priceChange24h,
            'priceChangePercent24h': data.priceChangePercent24h,
            'high24h': data.high24h,
            'low24h': data.low24h,
            'volume24h': data.volume24h,
            'marketCap': data.marketCap,
            'imageUrl': data.imageUrl,
            'lastUpdated': data.lastUpdated.toIso8601String(),
          },
          duration: const Duration(minutes: 5),
        );

        return marketData;
      } else {
        debugPrint(
          '❌ CoinGecko API: Failed with status ${response.statusCode}',
        );
        debugPrint('📄 Response body: ${response.body}');
        throw Exception('Failed to load market data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ CoinGecko API: Exception in getMarketData: $e');
      throw Exception('Error fetching market data: $e');
    }
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

  /// Fetch detailed information for a specific cryptocurrency
  static Future<CoinGeckoCoinDetails> getCoinDetails(String symbol) async {
    try {
      final coinId = _getCoinId(symbol);
      if (coinId == null) {
        throw Exception('Unknown cryptocurrency symbol: $symbol');
      }

      // Fetch market data for the coin
      final url = Uri.parse(
        '$_baseUrl/coins/markets?vs_currency=usd&ids=$coinId&order=market_cap_desc&per_page=1&page=1&sparkline=false&price_change_percentage=24h',
      );

      debugPrint(
        '🌐 CoinGecko API: Requesting coin details for $symbol from: $url',
      );
      final response = await http.get(url, headers: _getHeaders());
      debugPrint('📡 CoinGecko API: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          throw Exception('No data found for $symbol');
        }

        final coinData = data[0];
        final currentPrice =
            (coinData['current_price'] as num?)?.toDouble() ?? 0.0;
        final priceChangePercent24h =
            (coinData['price_change_percentage_24h'] as num?)?.toDouble() ??
                0.0;
        final priceChange24h = currentPrice * (priceChangePercent24h / 100);

        return CoinGeckoCoinDetails(
          id: coinId,
          symbol: symbol,
          name: coinData['name'] as String? ?? _getCoinName(symbol),
          currentPrice: currentPrice,
          priceChange24h: priceChange24h,
          priceChangePercent24h: priceChangePercent24h,
          high24h: (coinData['high_24h'] as num?)?.toDouble() ?? currentPrice,
          low24h: (coinData['low_24h'] as num?)?.toDouble() ?? currentPrice,
          volume24h: (coinData['total_volume'] as num?)?.toDouble() ?? 0.0,
          marketCap: (coinData['market_cap'] as num?)?.toDouble() ?? 0.0,
          lastUpdated: coinData['last_updated'] != null
              ? DateTime.parse(coinData['last_updated'] as String)
              : DateTime.now(),
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

      // Calculate days based on time range
      final int days = switch (range) {
        TimeRange.oneHour => 1, // Get 1 day of data for hourly granularity
        TimeRange.twentyFourHours => 1,
        TimeRange.oneWeek => 7,
        TimeRange.oneMonth => 30,
        TimeRange.oneYear => 365,
      };

      // For 1 hour, we need to be careful. '1' day gives 5-min intervals.
      // We can filter later.

      final url = Uri.parse(
        '$_baseUrl/coins/$coinId/market_chart?vs_currency=usd&days=$days${days > 90 ? "&interval=daily" : ""}',
      );

      debugPrint(
        '🌐 CoinGecko API: Requesting historical data for $symbol from: $url',
      );
      final response = await http.get(url, headers: _getHeaders());
      debugPrint('📡 CoinGecko API: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> prices = data['prices'] as List<dynamic>;

        // Filter based on time range
        final now = DateTime.now();
        final DateTime startTime = switch (range) {
          TimeRange.oneHour => now.subtract(const Duration(hours: 1)),
          TimeRange.twentyFourHours => now.subtract(const Duration(hours: 24)),
          TimeRange.oneWeek => now.subtract(const Duration(days: 7)),
          TimeRange.oneMonth => now.subtract(const Duration(days: 30)),
          TimeRange.oneYear => now.subtract(const Duration(days: 365)),
        };

        final List<CoinGeckoPricePoint> pricePoints = [];

        for (final priceData in prices) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            (priceData[0] as int),
          );
          final price = (priceData[1] as num).toDouble();

          if (timestamp.isAfter(startTime) ||
              timestamp.isAtSameMomentAs(startTime)) {
            pricePoints.add(CoinGeckoPricePoint(time: timestamp, price: price));
          }
        }

        return pricePoints;
      } else {
        throw Exception(
          'Failed to load historical data: ${response.statusCode}',
        );
      }
    } catch (e) {
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
      case 'USDT':
        return 'Tether';
      case 'BNB':
        return 'Binance Coin';
      case 'XRP':
        return 'XRP';
      case 'ADA':
        return 'Cardano';
      case 'DOGE':
        return 'Dogecoin';
      case 'TRX':
        return 'TRON';
      case 'DOT':
        return 'Polkadot';
      default:
        return symbol;
    }
  }
}
