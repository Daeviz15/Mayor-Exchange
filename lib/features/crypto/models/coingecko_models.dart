
/// CoinGecko Market Data Model
/// Represents market data from CoinGecko API
class CoinGeckoMarketData {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double priceChange24h;
  final double priceChangePercent24h;
  final double high24h;
  final double low24h;
  final double volume24h;
  final double marketCap;
  final DateTime lastUpdated;

  CoinGeckoMarketData({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.priceChange24h,
    required this.priceChangePercent24h,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    required this.marketCap,
    required this.lastUpdated,
  });
}

/// CoinGecko Coin Details Model
/// Detailed information about a cryptocurrency from CoinGecko
class CoinGeckoCoinDetails {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double priceChange24h;
  final double priceChangePercent24h;
  final double high24h;
  final double low24h;
  final double volume24h;
  final double marketCap;
  final DateTime lastUpdated;

  CoinGeckoCoinDetails({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.priceChange24h,
    required this.priceChangePercent24h,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    required this.marketCap,
    required this.lastUpdated,
  });
}

/// CoinGecko Price Point Model
/// Represents a single price point in historical data
class CoinGeckoPricePoint {
  final DateTime time;
  final double price;

  CoinGeckoPricePoint({
    required this.time,
    required this.price,
  });
}

