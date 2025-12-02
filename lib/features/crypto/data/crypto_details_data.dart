import '../models/crypto_details.dart';
import '../../../core/theme/app_colors.dart';

/// Crypto Details Data
/// Dummy data for crypto details screens
class CryptoDetailsData {
  static CryptoDetails getBitcoinDetails() {
    return CryptoDetails(
      symbol: 'BTC',
      name: 'Bitcoin',
      pair: 'BTC/USD',
      currentPrice: 68450.20,
      change24h: 1245.50,
      changePercent24h: 2.15,
      high24h: 69123.45,
      low24h: 67543.21,
      volumeBTC: 65420.0,
      volumeUSD: 4500000000.0, // 4.5B
      accentColor: AppColors.btcBackground,
      priceHistory: _generatePriceHistory(68450.20),
    );
  }

  static CryptoDetails getEthereumDetails() {
    return CryptoDetails(
      symbol: 'ETH',
      name: 'Ethereum',
      pair: 'ETH/USD',
      currentPrice: 3567.89,
      change24h: -18.50,
      changePercent24h: -0.52,
      high24h: 3620.00,
      low24h: 3550.00,
      volumeBTC: 125000.0,
      volumeUSD: 445000000.0, // 445M
      accentColor: AppColors.ethBackground,
      priceHistory: _generatePriceHistory(3567.89),
    );
  }

  static CryptoDetails getSolanaDetails() {
    return CryptoDetails(
      symbol: 'SOL',
      name: 'Solana',
      pair: 'SOL/USD',
      currentPrice: 172.10,
      change24h: 8.40,
      changePercent24h: 5.12,
      high24h: 175.50,
      low24h: 163.20,
      volumeBTC: 89000.0,
      volumeUSD: 153000000.0, // 153M
      accentColor: AppColors.solBackground,
      priceHistory: _generatePriceHistory(172.10),
    );
  }

  static CryptoDetails getDetailsBySymbol(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'BTC':
        return getBitcoinDetails();
      case 'ETH':
        return getEthereumDetails();
      case 'SOL':
        return getSolanaDetails();
      default:
        return getBitcoinDetails();
    }
  }

  static List<PricePoint> _generatePriceHistory(double basePrice) {
    final now = DateTime.now();
    final List<PricePoint> history = [];
    
    // Generate 50 data points for the last 24 hours
    for (int i = 50; i >= 0; i--) {
      final time = now.subtract(Duration(hours: i));
      // Simulate price fluctuations
      final variation = (basePrice * 0.02) * (i % 10 - 5) / 5;
      final price = basePrice + variation;
      history.add(PricePoint(time: time, price: price));
    }
    
    return history;
  }
}

