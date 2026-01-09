import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/gift_card.dart';
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
          );
        }
        return card;
      }).toList();

      controller.add(cards);

      // Clear image cache to ensure fresh images are loaded
      await DefaultCacheManager().emptyCache();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      controller.add(GiftCardsData.getAllGiftCards());
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

/// Gift Cards from Database Provider (backward compatible wrapper)
/// Uses the stream provider but exposes as AsyncValue
final giftCardsFromDbProvider = Provider<AsyncValue<List<GiftCard>>>((ref) {
  return ref.watch(giftCardsStreamProvider);
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

/// Selected Category Provider
final selectedCategoryProvider =
    StateNotifierProvider<CategoryNotifier, String>((ref) {
  return CategoryNotifier();
});

class CategoryNotifier extends StateNotifier<String> {
  CategoryNotifier() : super(GiftCardCategory.all);

  void setCategory(String category) {
    state = category;
  }
}

/// Search Query Provider
final searchQueryProvider = StateNotifierProvider<SearchQueryNotifier, String>((
  ref,
) {
  return SearchQueryNotifier();
});

class SearchQueryNotifier extends StateNotifier<String> {
  SearchQueryNotifier() : super('');

  void setQuery(String query) {
    state = query;
  }
}

/// Selected Currency Provider
final selectedCurrencyProvider =
    StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('USD');

  void setCurrency(String currency) {
    state = currency;
  }
}

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
