import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../models/gift_card.dart';
import '../providers/gift_cards_providers.dart';
import '../widgets/gift_card_item.dart';
import 'sell_giftcard_screen.dart';
import '../widgets/category_chip.dart';
import '../widgets/search_bar_widget.dart';

/// Gift Cards Screen
/// Main screen for browsing and searching gift cards
class GiftCardsScreen extends ConsumerStatefulWidget {
  const GiftCardsScreen({super.key});

  @override
  ConsumerState<GiftCardsScreen> createState() => _GiftCardsScreenState();
}

class _GiftCardsScreenState extends ConsumerState<GiftCardsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = GiftCardCategory.all;
  String _searchQuery = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  /// Handle pull-to-refresh
  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);

    try {
      await refreshGiftCards(ref);
      // Small delay to show the loader
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// Filter cards based on search and category
  List<GiftCard> _filterCards(List<GiftCard> cards) {
    return cards.where((card) {
      final categoryMatch = _selectedCategory == GiftCardCategory.all ||
          card.category == _selectedCategory;
      final searchMatch = _searchQuery.isEmpty ||
          card.name.toLowerCase().contains(_searchQuery) ||
          card.category.toLowerCase().contains(_searchQuery);
      return categoryMatch && searchMatch;
    }).toList();
  }

  /// Get unique categories from cards
  List<String> _getCategories(List<GiftCard> cards) {
    final categories = cards.map((c) => c.category).toSet().toList();
    categories.sort();
    return [GiftCardCategory.all, ...categories];
  }

  @override
  Widget build(BuildContext context) {
    // Get user's preferred currency from their profile

    const userCurrency = 'NGN'; // Hardcoded - country selection coming in v2.0

    // Watch gift cards stream from database (real-time updates)
    final giftCardsAsync = ref.watch(giftCardsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: giftCardsAsync.when(
          loading: () => const Center(child: RocketLoader()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $e', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _onRefresh,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                  ),
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          data: (allCards) {
            final filteredCards = _filterCards(allCards);
            final categories = _getCategories(allCards);

            return Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (Navigator.canPop(context))
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundCard,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          Text('Giftcards',
                              style: AppTextStyles.headlineMedium(context)),
                        ],
                      ),
                      Row(
                        children: [
                          // Refresh indicator
                          if (_isRefreshing)
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: RocketLoader(
                                    size: 20, color: AppColors.primaryOrange),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              userCurrency,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SearchBarWidget(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(() => _searchController.clear()),
                  ),
                ),

                const SizedBox(height: 20),

                // Category Filters
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: CategoryChip(
                          label: category,
                          isSelected: _selectedCategory == category,
                          onTap: () => _onCategorySelected(category),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Gift Cards Grid with Pull-to-Refresh
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppColors.primaryOrange,
                    backgroundColor: AppColors.backgroundCard,
                    child: filteredCards.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.15),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 64,
                                        color: AppColors.textTertiary),
                                    const SizedBox(height: 16),
                                    Text('No gift cards found',
                                        style: AppTextStyles.titleMedium(
                                                context)
                                            .copyWith(
                                                color: AppColors.textTertiary)),
                                    const SizedBox(height: 8),
                                    Text('Try a different search or category',
                                        style:
                                            AppTextStyles.bodyMedium(context)),
                                    const SizedBox(height: 24),
                                    Text('Pull down to refresh',
                                        style: AppTextStyles.bodySmall(context)
                                            .copyWith(
                                                color: AppColors.textTertiary)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 20,
                            ),
                            itemCount: filteredCards.length,
                            itemBuilder: (context, index) {
                              return GiftCardItem(
                                giftCard: filteredCards[index],
                                onTap: () =>
                                    _showGiftCardDetails(filteredCards[index]),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showGiftCardDetails(GiftCard giftCard) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Gift Card Preview
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: giftCard.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    giftCard.imageUrl != null && giftCard.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: giftCard.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: giftCard.logoText != null
                                  ? Text(
                                      giftCard.logoText!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : const RocketLoader(
                                      size: 24, color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: giftCard.logoText != null
                                  ? Text(
                                      giftCard.logoText!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : giftCard.icon != null
                                      ? Icon(giftCard.icon,
                                          color: Colors.white, size: 48)
                                      : const SizedBox(),
                            ),
                          )
                        : Center(
                            child: giftCard.logoText != null
                                ? Text(
                                    giftCard.logoText!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : giftCard.icon != null
                                    ? Icon(
                                        giftCard.icon,
                                        color: Colors.white,
                                        size: 48,
                                      )
                                    : const SizedBox(),
                          ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              giftCard.name,
              style: AppTextStyles.headlineSmall(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Category: ${giftCard.category}',
              style: AppTextStyles.bodyMedium(context),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SellGiftCardScreen(
                        giftCard: giftCard,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Trade Gift Card',
                  style: AppTextStyles.titleSmall(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
