import 'dart:convert';
import 'package:http/http.dart' as http;
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
  };

  /// Get CoinGecko ID from symbol
  static String? _getCoinId(String symbol) {
    return _coinIds[symbol.toUpperCase()];
  }

  /// Fetch market data for multiple cryptocurrencies
  /// Returns list of market data for BTC, ETH, and SOL
  static Future<List<CoinGeckoMarketData>> getMarketData() async {
    try {
      final coinIds = _coinIds.values.join(',');
      final url = Uri.parse(
        '$_baseUrl/coins/markets?vs_currency=usd&ids=$coinIds&order=market_cap_desc&per_page=10&page=1&sparkline=false&price_change_percentage=24h',
      );

      final response = await http.get(url);

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
                lastUpdated: coinData['last_updated'] != null
                    ? DateTime.parse(coinData['last_updated'] as String)
                    : DateTime.now(),
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

        return marketData;
      } else {
        throw Exception('Failed to load market data: ${response.statusCode}');
      }
    } catch (e) {
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

      final response = await http.get(url);

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

      // CoinGecko API doesn't support hourly interval for all ranges
      // Use appropriate interval based on days
      String interval = 'daily';
      if (days <= 1) {
        interval = 'hourly';
      } else if (days <= 90) {
        interval = 'daily';
      } else {
        interval = 'daily'; // For longer ranges, use daily
      }

      final url = Uri.parse(
        '$_baseUrl/coins/$coinId/market_chart?vs_currency=usd&days=$days&interval=$interval',
      );

      final response = await http.get(url);

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
      default:
        return symbol;
    }
  }
}
