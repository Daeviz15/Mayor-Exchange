import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/gift_card.dart';
import '../data/gift_cards_data.dart';

/// Gift Cards from Database Provider
/// Fetches gift cards from Supabase, falls back to local data if unavailable
final giftCardsFromDbProvider = FutureProvider<List<GiftCard>>((ref) async {
  try {
    final client = ref.read(supabaseClientProvider);

    final response = await client
        .from('gift_cards')
        .select()
        .eq('is_active', true)
        .order('display_order', ascending: true);

    if (response.isEmpty) {
      // No data in database, use local fallback
      return GiftCardsData.getAllGiftCards();
    }

    return (response as List)
        .map((json) => GiftCard.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    // Database error, use local fallback
    return GiftCardsData.getAllGiftCards();
  }
});

/// All Gift Cards Provider (for backward compatibility)
/// Uses database cards if available, otherwise local data
final allGiftCardsProvider = Provider<List<GiftCard>>((ref) {
  final dbCards = ref.watch(giftCardsFromDbProvider);
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
