import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

class CryptoRate {
  final String assetSymbol;
  final double buyRate;
  final double sellRate;

  CryptoRate({
    required this.assetSymbol,
    required this.buyRate,
    required this.sellRate,
  });

  factory CryptoRate.fromJson(Map<String, dynamic> json) {
    return CryptoRate(
      assetSymbol: json['asset_symbol'] as String,
      buyRate: (json['buy_rate'] as num).toDouble(),
      sellRate: (json['sell_rate'] as num).toDouble(),
    );
  }
}

final ratesProvider = StreamProvider<List<CryptoRate>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.from('admin_rates').stream(primaryKey: ['asset_symbol']).map(
      (data) => data.map((e) => CryptoRate.fromJson(e)).toList());
});

// Helper to get specific rate safely
final rateForAssetProvider =
    Provider.family<CryptoRate?, String>((ref, assetSymbol) {
  final ratesAsync = ref.watch(ratesProvider);
  return ratesAsync.when(
    data: (rates) {
      try {
        return rates.firstWhere((r) => r.assetSymbol == assetSymbol);
      } catch (_) {
        return null;
      }
    },
    error: (_, __) => null,
    loading: () => null,
  );
});

/// Controller for Admin to update rates
class AdminRatesService {
  final Ref ref;
  AdminRatesService(this.ref);

  Future<void> updateRate({
    required String assetSymbol,
    required double buyRate,
    required double sellRate,
  }) async {
    final client = ref.read(supabaseClientProvider);

    // Upsert allows updating existing or creating new if missing
    await client.from('admin_rates').upsert({
      'asset_symbol': assetSymbol,
      'buy_rate': buyRate,
      'sell_rate': sellRate,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': client.auth.currentUser?.id,
    });

    // Force refresh to ensure UI updates immediately even if realtime lags
    ref.invalidate(ratesProvider);
  }
}

final adminRatesServiceProvider = Provider<AdminRatesService>((ref) {
  return AdminRatesService(ref);
});
