import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../models/gift_card.dart';
import '../models/gift_card_variant.dart';
import '../data/gift_cards_data.dart';

/// Gift Cards Stream Provider - Real-time updates from Supabase
/// Automatically updates when admin makes any changes
final giftCardsStreamProvider = StreamProvider<List<GiftCard>>((ref) {
  final client = ref.read(supabaseClientProvider);

  // Create a stream controller to manage updates
  final controller = StreamController<List<GiftCard>>();

  // Initial fetch
  Future<void> fetchCards() async {
    try {
      final response = await client
          .from('gift_cards')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      if (response.isEmpty) {
        controller.add(GiftCardsData.getAllGiftCards());
        return;
      }

      // Add cache-busting timestamp to image URLs
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final cards = (response as List).map((json) {
        final card = GiftCard.fromJson(json as Map<String, dynamic>);
        if (card.imageUrl != null && card.imageUrl!.isNotEmpty) {
          final separator = card.imageUrl!.contains('?') ? '&' : '?';
          final cacheBustedUrl = '${card.imageUrl}${separator}t=$timestamp';
          return GiftCard(
            id: card.id,
            name: card.name,
            category: card.category,
            cardColor: card.cardColor,
            logoText: card.logoText,
            icon: card.icon,
            imageUrl: cacheBustedUrl,
            redemptionUrl: card.redemptionUrl,
            isActive: card.isActive,
            displayOrder: card.displayOrder,
            buyRate: card.buyRate,
            physicalRate: card.physicalRate,
            ecodeRate: card.ecodeRate,
            minValue: card.minValue,
            maxValue: card.maxValue,
            allowedDenominations: card.allowedDenominations,
          );
        }
        return card;
      }).toList();

      controller.add(cards);

      // Clear image cache to ensure fresh images are loaded
      await DefaultCacheManager().emptyCache();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e, stack) {
      debugPrint('Error fetching gift cards: $e');
      // Expose error to UI for debugging
      controller.addError(e, stack);
    }
  }

  // Initial fetch
  fetchCards();

  // Subscribe to real-time changes on gift_cards table
  final channel = client.channel('gift_cards_realtime');

  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'gift_cards',
        callback: (payload) {
          // Refetch all cards when any change happens
          fetchCards();
        },
      )
      .subscribe();

  // Cleanup on dispose
  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Admin Gift Cards Stream Provider - Fetches all cards (including inactive ones)
final adminGiftCardsStreamProvider = StreamProvider<List<GiftCard>>((ref) {
  final client = ref.read(supabaseClientProvider);
  final controller = StreamController<List<GiftCard>>();

  Future<void> fetchCards() async {
    try {
      final response = await client
          .from('gift_cards')
          .select()
          .order('display_order', ascending: true);

      final cards = (response as List).map((json) {
        return GiftCard.fromJson(json as Map<String, dynamic>);
      }).toList();

      controller.add(cards);
    } catch (e, stack) {
      debugPrint('Error fetching admin gift cards: $e');
      controller.addError(e, stack);
    }
  }

  fetchCards();

  final channel = client.channel('admin_gift_cards_realtime');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'gift_cards',
        callback: (payload) => fetchCards(),
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Gift Cards from Database Provider (backward compatible wrapper)
/// Uses the stream provider but exposes as AsyncValue
final giftCardsFromDbProvider = Provider<AsyncValue<List<GiftCard>>>((ref) {
  return ref.watch(giftCardsStreamProvider);
});

/// Admin Gift Cards from Database Provider
final adminGiftCardsFromDbProvider =
    Provider<AsyncValue<List<GiftCard>>>((ref) {
  return ref.watch(adminGiftCardsStreamProvider);
});

/// Clear image cache and refresh gift cards (for manual refresh)
Future<void> refreshGiftCards(WidgetRef ref) async {
  // Clear the cached network image cache
  await DefaultCacheManager().emptyCache();
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();

  // Invalidate the stream provider to force reconnection
  ref.invalidate(giftCardsStreamProvider);
}

/// All Gift Cards Provider (for backward compatibility)
/// Uses database cards if available, otherwise local data
final allGiftCardsProvider = Provider<List<GiftCard>>((ref) {
  final dbCards = ref.watch(giftCardsStreamProvider);
  return dbCards.when(
    data: (cards) => cards,
    loading: () => GiftCardsData.getAllGiftCards(),
    error: (_, __) => GiftCardsData.getAllGiftCards(),
  );
});

/// Selected Category Provider - Modern StateProvider
final selectedCategoryProvider =
    StateProvider<String>((ref) => GiftCardCategory.all);

/// Search Query Provider - Modern StateProvider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected Currency Provider - Modern StateProvider
final selectedCurrencyProvider = StateProvider<String>((ref) => 'USD');

/// Filtered Gift Cards Provider
/// Combines search and category filters
final filteredGiftCardsProvider = Provider<List<GiftCard>>((ref) {
  final allCards = ref.watch(allGiftCardsProvider);
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return allCards.where((card) {
    // Category filter
    final categoryMatch =
        category == GiftCardCategory.all || card.category == category;

    // Search filter
    final searchMatch = query.isEmpty ||
        card.name.toLowerCase().contains(query) ||
        card.category.toLowerCase().contains(query);

    return categoryMatch && searchMatch;
  }).toList();
});

/// Get categories from database or local
final giftCardCategoriesProvider = Provider<List<String>>((ref) {
  final cards = ref.watch(allGiftCardsProvider);
  final categories = cards.map((c) => c.category).toSet().toList();
  categories.sort();
  return [GiftCardCategory.all, ...categories];
});

// ============================================================
// APPLE GIFT CARD VARIANTS - Efficient per-denomination pricing
// ============================================================

/// Cache key for Apple variants
const _appleVariantsCacheKey = 'apple_variants_cache';
const _appleVariantsCacheTimestampKey = 'apple_variants_cache_ts';
const _cacheExpiry = Duration(minutes: 10);

/// Apple Variants Provider - Cached with real-time updates
/// Only fetches from DB, uses SharedPreferences for caching
final appleVariantsProvider =
    FutureProvider<List<GiftCardVariant>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final prefs = ref.read(sharedPreferencesProvider);

  // Try cache first
  final cached = _getCachedVariants(prefs);
  if (cached != null) {
    // Schedule background refresh
    _refreshVariantsInBackground(client, prefs, ref);
    return cached;
  }

  // No cache, fetch from DB
  return _fetchAppleVariants(client, prefs, onlyActive: true);
});

/// Admin version - Fetches all variants (including inactive ones)
final adminAppleVariantsProvider =
    FutureProvider<List<GiftCardVariant>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  return _fetchAppleVariants(client, null, onlyActive: false);
});

/// Fetch Apple variants with nested denomination rates
Future<List<GiftCardVariant>> _fetchAppleVariants(
    SupabaseClient client, SharedPreferences? prefs,
    {bool onlyActive = true}) async {
  try {
    var query = client.from('gift_card_variants').select('''
          *,
          gift_card_denomination_rates (*)
        ''').eq('parent_card_id', 'apple');

    if (onlyActive) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('display_order', ascending: true);

    final variants = (response as List)
        .map((json) => GiftCardVariant.fromJson(json as Map<String, dynamic>))
        .toList();

    // Cache the result (only if it's the active-only fetch)
    if (onlyActive && prefs != null) {
      _cacheVariants(prefs, variants);
    }

    return variants;
  } catch (e) {
    debugPrint('Error fetching Apple variants: $e');
    return [];
  }
}

/// Get cached variants if not expired
List<GiftCardVariant>? _getCachedVariants(SharedPreferences prefs) {
  try {
    final timestamp = prefs.getInt(_appleVariantsCacheTimestampKey);
    if (timestamp == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cachedAt) > _cacheExpiry) {
      return null; // Cache expired
    }

    final jsonString = prefs.getString(_appleVariantsCacheKey);
    if (jsonString == null) return null;

    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((json) => GiftCardVariant.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('Error reading Apple variants cache: $e');
    return null;
  }
}

/// Cache variants to SharedPreferences
void _cacheVariants(SharedPreferences prefs, List<GiftCardVariant> variants) {
  try {
    // Manually serialize with nested rates
    final jsonList = variants
        .map((v) => {
              'id': v.id,
              'parent_card_id': v.parentCardId,
              'name': v.name,
              'description': v.description,
              'display_order': v.displayOrder,
              'is_active': v.isActive,
              'gift_card_denomination_rates':
                  v.denominationRates.map((r) => r.toJson()).toList(),
            })
        .toList();

    prefs.setString(_appleVariantsCacheKey, jsonEncode(jsonList));
    prefs.setInt(
        _appleVariantsCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  } catch (e) {
    debugPrint('Error caching Apple variants: $e');
  }
}

/// Background refresh for stale-while-revalidate pattern
void _refreshVariantsInBackground(
    SupabaseClient client, SharedPreferences prefs, Ref ref) {
  Future.microtask(() async {
    await _fetchAppleVariants(client, prefs);
    // Invalidate to pick up fresh data on next access
    ref.invalidateSelf();
  });
}

/// Clear Apple variants cache (call when admin updates rates)
Future<void> clearAppleVariantsCache(WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.remove(_appleVariantsCacheKey);
  await prefs.remove(_appleVariantsCacheTimestampKey);
  ref.invalidate(appleVariantsProvider);
  ref.invalidate(adminAppleVariantsProvider);
}

/// Check if a gift card has variants
final hasVariantsProvider = Provider.family<bool, String>((ref, cardId) {
  // Only Apple has variants for now
  return cardId == 'apple';
});
