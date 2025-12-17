import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dasboard/providers/balance_provider.dart';
import '../../crypto/providers/crypto_providers.dart';

class PortfolioItem {
  final String id;
  final String name;
  final String symbol;
  final double quantity;
  final double valueInNaira;
  final String? iconUrl;
  final bool isFiat;

  PortfolioItem({
    required this.id,
    required this.name,
    required this.symbol,
    required this.quantity,
    required this.valueInNaira,
    this.iconUrl,
    this.isFiat = false,
  });
}

class PortfolioState {
  final double totalValue;
  final List<PortfolioItem> items;
  final double fiatPercentage;
  final double cryptoPercentage;

  PortfolioState({
    this.totalValue = 0.0,
    this.items = const [],
    this.fiatPercentage = 0.0,
    this.cryptoPercentage = 0.0,
  });
}

final portfolioProvider = Provider<PortfolioState>((ref) {
  final balanceState = ref.watch(balanceProvider);
  // Keep watch to trigger updates, even if unused locally for now
  // ignore: unused_local_variable
  final cryptoListAsync = ref.watch(cryptoListProvider);

  double fiatBalance = balanceState.totalBalance;
  List<PortfolioItem> items = [];

  // Add Fiat
  if (fiatBalance > 0) {
    items.add(PortfolioItem(
      id: 'naira',
      name: 'Nigerian Naira',
      symbol: 'NGN',
      quantity: fiatBalance,
      valueInNaira: fiatBalance,
      isFiat: true,
    ));
  }

  // Placeholder for real crypto wallet integration
  double cryptoTotal = 0.0;
  final totalValue = fiatBalance + cryptoTotal;

  return PortfolioState(
    totalValue: totalValue,
    items: items,
    fiatPercentage: totalValue == 0 ? 0 : (fiatBalance / totalValue) * 100,
    cryptoPercentage: totalValue == 0 ? 0 : (cryptoTotal / totalValue) * 100,
  );
});

// Mock Provider for demonstration
final mockPortfolioProvider = Provider<PortfolioState>((ref) {
  final balanceState = ref.watch(balanceProvider);
  // Get the list of available coins (market data)
  final cryptoList = ref.watch(cryptoListProvider).asData?.value ?? [];

  double fiatBalance = balanceState.totalBalance;
  // If user has 0 balance, pretend they have some for the "Stunning UI" demo
  if (fiatBalance == 0) fiatBalance = 150000.0;

  List<PortfolioItem> items = [];

  // Add Fiat
  items.add(PortfolioItem(
    id: 'naira',
    name: 'Nigerian Naira',
    symbol: 'NGN',
    quantity: fiatBalance,
    valueInNaira: fiatBalance,
    isFiat: true,
  ));

  double cryptoTotal = 0.0;

  if (cryptoList.isNotEmpty) {
    // Mock: User owns some crypto based on what's available in the market list
    // We limit to 3 items for a clean demo
    for (var i = 0; i < cryptoList.length && i < 3; i++) {
      final crypto = cryptoList[i]; // This is CryptoData
      final qty = (i + 1) * 0.5; // Arbitrary quantity
      final val = qty * crypto.price;
      cryptoTotal += val;

      items.add(PortfolioItem(
        id: crypto.id,
        name: crypto.name,
        symbol: crypto.symbol.toUpperCase(),
        quantity: qty,
        valueInNaira: val,
        iconUrl: crypto.iconUrl,
        isFiat: false,
      ));
    }
  } else {
    // Fallback mocks if API is down or empty
    items.add(PortfolioItem(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'BTC',
      quantity: 0.05,
      valueInNaira: 3500000,
      isFiat: false,
    ));
    cryptoTotal += 3500000;
  }

  final totalValue = fiatBalance + cryptoTotal;

  return PortfolioState(
    totalValue: totalValue,
    items: items,
    fiatPercentage: totalValue == 0 ? 0 : (fiatBalance / totalValue) * 100,
    cryptoPercentage: totalValue == 0 ? 0 : (cryptoTotal / totalValue) * 100,
  );
});
