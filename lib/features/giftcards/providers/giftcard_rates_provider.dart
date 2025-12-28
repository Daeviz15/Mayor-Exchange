import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

/// Gift Card Rate Model
/// Represents admin-defined buy/sell rates for a gift card brand
class GiftCardRate {
  final String cardId; // e.g., 'amazon', 'itunes'
  final String cardName; // e.g., 'Amazon', 'iTunes'
  final double buyRate; // Rate per $1 when user sells TO platform
  final double sellRate; // Rate per $1 when user buys FROM platform
  final bool isActive;
  final DateTime? updatedAt;

  GiftCardRate({
    required this.cardId,
    required this.cardName,
    required this.buyRate,
    required this.sellRate,
    this.isActive = true,
    this.updatedAt,
  });

  factory GiftCardRate.fromJson(Map<String, dynamic> json) {
    return GiftCardRate(
      cardId: json['card_id'] as String,
      cardName: json['card_name'] as String,
      buyRate: (json['buy_rate'] as num).toDouble(),
      sellRate: (json['sell_rate'] as num).toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'card_name': cardName,
      'buy_rate': buyRate,
      'sell_rate': sellRate,
      'is_active': isActive,
    };
  }

  /// Calculate payout when user SELLS a gift card to platform
  /// e.g., $100 card at buyRate of 1450 = ₦145,000
  double calculateBuyPayout(double cardValueUSD) {
    return cardValueUSD * buyRate;
  }

  /// Calculate cost when user BUYS a gift card from platform
  /// e.g., $100 card at sellRate of 1550 = ₦155,000
  double calculateSellCost(double cardValueUSD) {
    return cardValueUSD * sellRate;
  }
}

/// Stream provider for gift card rates from Supabase
final giftCardRatesProvider = StreamProvider<List<GiftCardRate>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.from('giftcard_rates').stream(primaryKey: ['card_id']).map(
      (data) => data.map((e) => GiftCardRate.fromJson(e)).toList());
});

/// Get rate for a specific gift card
final giftCardRateForCardProvider =
    Provider.family<GiftCardRate?, String>((ref, cardId) {
  final ratesAsync = ref.watch(giftCardRatesProvider);
  return ratesAsync.when(
    data: (rates) {
      try {
        return rates.firstWhere((r) => r.cardId == cardId && r.isActive);
      } catch (_) {
        return null;
      }
    },
    error: (_, __) => null,
    loading: () => null,
  );
});

/// Get only active gift card rates
final activeGiftCardRatesProvider = Provider<List<GiftCardRate>>((ref) {
  final ratesAsync = ref.watch(giftCardRatesProvider);
  return ratesAsync.when(
    data: (rates) => rates.where((r) => r.isActive).toList(),
    error: (_, __) => [],
    loading: () => [],
  );
});

/// Admin service for managing gift card rates
class AdminGiftCardRatesService {
  final Ref ref;
  AdminGiftCardRatesService(this.ref);

  /// Update or create a gift card rate
  Future<void> upsertRate({
    required String cardId,
    required String cardName,
    required double buyRate,
    required double sellRate,
    bool isActive = true,
  }) async {
    final client = ref.read(supabaseClientProvider);

    await client.from('giftcard_rates').upsert({
      'card_id': cardId,
      'card_name': cardName,
      'buy_rate': buyRate,
      'sell_rate': sellRate,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': client.auth.currentUser?.id,
    });

    // Force refresh
    ref.invalidate(giftCardRatesProvider);
  }

  /// Toggle active status for a gift card
  Future<void> toggleActive(String cardId, bool isActive) async {
    final client = ref.read(supabaseClientProvider);

    await client.from('giftcard_rates').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('card_id', cardId);

    ref.invalidate(giftCardRatesProvider);
  }

  /// Delete a gift card rate
  Future<void> deleteRate(String cardId) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('giftcard_rates').delete().eq('card_id', cardId);
    ref.invalidate(giftCardRatesProvider);
  }
}

final adminGiftCardRatesServiceProvider =
    Provider<AdminGiftCardRatesService>((ref) {
  return AdminGiftCardRatesService(ref);
});
