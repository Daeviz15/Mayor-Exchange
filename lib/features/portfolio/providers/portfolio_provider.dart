import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../crypto/providers/crypto_providers.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_service.dart';
import '../../transactions/providers/rates_provider.dart';

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
  final transactionsAsync = ref.watch(userTransactionsProvider);
  final cryptoListAsync = ref.watch(cryptoListProvider);
  final ratesAsync = ref.watch(ratesProvider);

  // Default empty state
  if (transactionsAsync.isLoading) {
    return PortfolioState();
  }

  final transactions = transactionsAsync.value ?? [];
  final cryptoList = cryptoListAsync.value ?? [];
  final rates = ratesAsync.value ?? [];

  double fiatBalance = 0.0;
  final Map<String, double> cryptoHoldings = {};

  for (final t in transactions) {
    // Skip rejected/cancelled transactions entirely
    if (t.status == TransactionStatus.rejected ||
        t.status == TransactionStatus.cancelled) continue;

    // For non-withdrawals, we generally only count completed transactions for balance
    // But for withdrawals, we want to deduct pending ones too.
    if (t.type != TransactionType.withdrawal &&
        t.status != TransactionStatus.completed) continue;

    switch (t.type) {
      case TransactionType.deposit:
        fiatBalance += t.amountFiat;
        break;
      case TransactionType.withdrawal:
        // Deduct if completed OR pending (lock funds)
        if (t.status == TransactionStatus.completed ||
            t.status == TransactionStatus.pending ||
            t.status == TransactionStatus.paymentPending ||
            t.status == TransactionStatus.verificationPending) {
          fiatBalance -= t.amountFiat;
        }
        break;
      case TransactionType.buyCrypto:
        fiatBalance -= t.amountFiat;
        final asset = t.details['asset']?.toString().toUpperCase() ?? '';
        final amount = t.amountCrypto ?? 0.0;
        if (asset.isNotEmpty) {
          cryptoHoldings[asset] = (cryptoHoldings[asset] ?? 0.0) + amount;
        }
        break;
      case TransactionType.sellCrypto:
        fiatBalance += t.amountFiat;
        final asset = t.details['asset']?.toString().toUpperCase() ?? '';
        final amount = t.amountCrypto ?? 0.0;
        if (asset.isNotEmpty) {
          cryptoHoldings[asset] = (cryptoHoldings[asset] ?? 0.0) - amount;
        }
        break;
      case TransactionType.buyGiftCard:
        fiatBalance -= t.amountFiat;
        break;
      case TransactionType.sellGiftCard:
        fiatBalance += t.amountFiat;
        break;
    }
  }

  // Ensure no negative balances from weird data
  if (fiatBalance < 0) fiatBalance = 0.0;

  List<PortfolioItem> items = [];
  double cryptoTotalValue = 0.0;

  // Add Fiat Item
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

  // Create Lookup Maps for O(1) access
  final cryptoMap = {
    for (var c in cryptoList) c.symbol.toUpperCase(): c,
  };
  final ratesMap = {
    for (var r in rates) r.assetSymbol.toUpperCase(): r,
  };

  // Process Crypto Items
  cryptoHoldings.forEach((symbol, quantity) {
    if (quantity <= 0) return;

    // 1. Get Metadata (Name, Icon) from CoinGecko (Rich UI)
    final cryptoMeta = cryptoMap[symbol];

    // 2. Get Price from Admin Rates (Authentic Valuation)
    // We use SELL RATE because Net Worth = what you get if you sell.
    final rate = ratesMap[symbol];
    final price = rate?.sellRate ?? 0.0;

    final valueInNaira = quantity * price;
    cryptoTotalValue += valueInNaira;

    items.add(PortfolioItem(
      id: symbol.toLowerCase(),
      name: cryptoMeta?.name ?? symbol,
      symbol: symbol,
      quantity: quantity,
      valueInNaira: valueInNaira,
      iconUrl: cryptoMeta?.iconUrl,
      isFiat: false,
    ));
  });

  final totalValue = fiatBalance + cryptoTotalValue;

  return PortfolioState(
    totalValue: totalValue,
    items: items,
    fiatPercentage: totalValue == 0 ? 0 : (fiatBalance / totalValue) * 100,
    cryptoPercentage:
        totalValue == 0 ? 0 : (cryptoTotalValue / totalValue) * 100,
  );
});
