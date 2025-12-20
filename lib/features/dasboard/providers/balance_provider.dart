import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../portfolio/providers/portfolio_provider.dart';
import '../../crypto/providers/crypto_providers.dart';

/// User Balance State
class BalanceState {
  final double totalBalance;
  final double changePercent24h;

  const BalanceState({
    this.totalBalance = 12450.78,
    this.changePercent24h = 2.5,
  });

  BalanceState copyWith({double? totalBalance, double? changePercent24h}) {
    return BalanceState(
      totalBalance: totalBalance ?? this.totalBalance,
      changePercent24h: changePercent24h ?? this.changePercent24h,
    );
  }
}

/// Balance Provider
/// Now derives authentic data from PortfolioProvider
final balanceProvider = Provider<BalanceState>((ref) {
  final portfolioState = ref.watch(portfolioProvider);

  // 1. Total Balance is direct from portfolio
  final totalBalance = portfolioState.totalValue;

  // 2. Calculate Weighted 24h Change
  // Formula: Sum(AssetValue * AssetChange%) / TotalValue
  double weightedChangeSum = 0.0;
  final cryptoList = ref.watch(cryptoListProvider).value ?? [];

  for (final item in portfolioState.items) {
    if (item.isFiat) {
      // Fiat (NGN) has 0% change relative to itself in this context
      // weightedChangeSum += item.valueInNaira * 0.0;
      continue;
    }

    // Find 24h change for this crypto asset
    double changePercent = 0.0;
    final cryptoData = cryptoList
        .where((c) => c.symbol.toUpperCase() == item.symbol.toUpperCase())
        .firstOrNull;

    if (cryptoData != null) {
      changePercent = cryptoData.changePercent;
    }

    weightedChangeSum += (item.valueInNaira * changePercent);
  }

  final weightedChangePercent =
      totalBalance == 0 ? 0.0 : (weightedChangeSum / totalBalance);

  return BalanceState(
    totalBalance: totalBalance,
    changePercent24h: weightedChangePercent,
  );
});
