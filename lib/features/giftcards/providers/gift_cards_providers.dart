import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/gift_card.dart';
import '../data/gift_cards_data.dart';

/// All Gift Cards Provider
final allGiftCardsProvider = Provider<List<GiftCard>>((ref) {
  return GiftCardsData.getAllGiftCards();
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
    final searchMatch =
        query.isEmpty ||
        card.name.toLowerCase().contains(query) ||
        card.category.toLowerCase().contains(query);

    return categoryMatch && searchMatch;
  }).toList();
});
