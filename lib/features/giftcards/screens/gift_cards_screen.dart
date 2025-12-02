import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/gift_card.dart';
import '../data/gift_cards_data.dart';
import '../widgets/gift_card_item.dart';
import '../widgets/category_chip.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/currency_selector.dart';
import '../../dasboard/widgets/bottom_nav_bar.dart';
import '../../dasboard/screens/home_screen.dart';
import '../../dasboard/screens/settings_screen.dart';

/// Gift Cards Screen
/// Main screen for browsing and searching gift cards
class GiftCardsScreen extends StatefulWidget {
  const GiftCardsScreen({super.key});

  @override
  State<GiftCardsScreen> createState() => _GiftCardsScreenState();
}

class _GiftCardsScreenState extends State<GiftCardsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = GiftCardCategory.all;
  String _selectedCurrency = 'USD';
  int _currentNavIndex = 3; // Gift Cards tab index
  List<GiftCard> _allGiftCards = [];
  List<GiftCard> _filteredGiftCards = [];

  @override
  void initState() {
    super.initState();
    _allGiftCards = GiftCardsData.getAllGiftCards();
    _filteredGiftCards = _allGiftCards;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterGiftCards();
  }

  void _filterGiftCards() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      
      _filteredGiftCards = _allGiftCards.where((card) {
        // Category filter
        final categoryMatch = _selectedCategory == GiftCardCategory.all ||
            card.category == _selectedCategory;
        
        // Search filter
        final searchMatch = query.isEmpty ||
            card.name.toLowerCase().contains(query) ||
            card.category.toLowerCase().contains(query);
        
        return categoryMatch && searchMatch;
      }).toList();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterGiftCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giftcards',
                    style: AppTextStyles.headlineMedium(context),
                  ),
                  CurrencySelector(
                    selectedCurrency: _selectedCurrency,
                    onChanged: (currency) {
                      setState(() {
                        _selectedCurrency = currency;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SearchBarWidget(
                controller: _searchController,
                onChanged: (_) => _filterGiftCards(),
                onClear: () => _filterGiftCards(),
              ),
            ),

            const SizedBox(height: 20),

            // Category Filters
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: GiftCardsData.getCategories().map((category) {
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

            // Gift Cards Grid
            Expanded(
              child: _filteredGiftCards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No gift cards found',
                            style: AppTextStyles.titleMedium(context).copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search or category',
                            style: AppTextStyles.bodyMedium(context),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _filteredGiftCards.length,
                      itemBuilder: (context, index) {
                        return GiftCardItem(
                          giftCard: _filteredGiftCards[index],
                          onTap: () {
                            // Navigate to gift card details or trade screen
                            _showGiftCardDetails(_filteredGiftCards[index]);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          
          // Handle navigation
          if (index == 0) {
            // Home tab
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (index == 3) {
            // Gift Cards tab - already here, do nothing
          } else if (index == 4) {
            // Settings tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ).then((_) {
              // Return to gift cards screen
              setState(() {
                _currentNavIndex = 3;
              });
            });
          }
        },
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
              child: Center(
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
                  // Navigate to trade screen
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

