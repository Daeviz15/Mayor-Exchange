import 'package:flutter/material.dart';
import '../models/gift_card.dart';

/// Redemption URLs for popular gift cards
const Map<String, String> _redemptionUrls = {
  'nintendo': 'redeem.nintendo.com',
  'playstation': 'store.playstation.com/redeem',
  'xbox': 'redeem.microsoft.com',
  'steam': 'store.steampowered.com/account/redeemwalletcode',
  'roblox': 'roblox.com/redeem',
  'epic-games': 'epicgames.com/redeem',
  'netflix': 'netflix.com/redeem',
  'spotify': 'spotify.com/redeem',
  'itunes': 'apple.com/redeem',
  'disney-plus': 'disneyplus.com/redeem',
  'hulu': 'hulu.com/gift',
  'amazon-prime': 'amazon.com/gc/redeem',
  'apple': 'apple.com/redeem',
  'google-play': 'play.google.com/redeem',
  'microsoft': 'redeem.microsoft.com',
  'amazon': 'amazon.com/gc/redeem',
  'walmart': 'walmart.com/giftcard',
  'target': 'target.com/gift-cards',
  'best-buy': 'bestbuy.com/giftcards',
  'ebay': 'ebay.com/giftcard',
  'starbucks': 'starbucks.com/gift',
  'mcdonalds': 'mcdonalds.com/us/en-us/mymcdonalds.html',
  'dominos': 'dominos.com/giftcard',
  'uber-eats': 'uber.com/gift',
  'doordash': 'doordash.com/gift',
};

/// Gift Cards Data
/// Comprehensive list of popular gift cards
class GiftCardsData {
  /// Get redemption URL for a card ID
  static String? getRedemptionUrl(String cardId) {
    return _redemptionUrls[cardId.toLowerCase()];
  }

  /// Get redemption instructions for a card ID
  static String getRedemptionInstructions(String cardId, String cardName) {
    final url = _redemptionUrls[cardId.toLowerCase()];
    if (url != null) {
      return 'Redeem at $url';
    }
    return 'Visit the official $cardName website to redeem your code.';
  }

  static List<GiftCard> getAllGiftCards() {
    return [
      // Games
      GiftCard(
        id: 'nintendo',
        name: 'Nintendo',
        category: GiftCardCategory.games,
        cardColor: const Color(0xFFE60012), // Nintendo Red
        logoText: 'Nintendo',
        redemptionUrl: _redemptionUrls['nintendo'],
      ),
      GiftCard(
        id: 'playstation',
        name: 'PlayStation',
        category: GiftCardCategory.games,
        cardColor: const Color(0xFF003087), // PlayStation Blue
        logoText: 'PS',
      ),
      GiftCard(
        id: 'xbox',
        name: 'Xbox',
        category: GiftCardCategory.games,
        cardColor: const Color(0xFF107C10), // Xbox Green
        logoText: 'XBOX',
      ),
      GiftCard(
        id: 'steam',
        name: 'Steam',
        category: GiftCardCategory.games,
        cardColor: const Color(0xFF171A21),
        logoText: 'Steam',
      ),
      GiftCard(
        id: 'roblox',
        name: 'Roblox',
        category: GiftCardCategory.games,
        cardColor: const Color(0xFF00A2FF),
        logoText: 'Roblox',
      ),
      GiftCard(
        id: 'epic-games',
        name: 'Epic Games',
        category: GiftCardCategory.games,
        cardColor: const Color(0xFF313131),
        logoText: 'Epic',
      ),

      // Entertainment & Streaming
      GiftCard(
        id: 'netflix',
        name: 'Netflix',
        category: GiftCardCategory.streaming,
        cardColor: const Color(0xFFE50914), // Netflix Red
        logoText: 'Netflix',
      ),
      GiftCard(
        id: 'spotify',
        name: 'Spotify',
        category: GiftCardCategory.streaming,
        cardColor: const Color(0xFF1DB954), // Spotify Green
        logoText: 'Spotify',
      ),
      GiftCard(
        id: 'itunes',
        name: 'iTunes',
        category: GiftCardCategory.entertainment,
        cardColor: const Color(0xFFFA2D48), // iTunes Pink
        icon: Icons.music_note,
      ),
      GiftCard(
        id: 'disney-plus',
        name: 'Disney+',
        category: GiftCardCategory.streaming,
        cardColor: const Color(0xFF113CCF),
        logoText: 'Disney+',
      ),
      GiftCard(
        id: 'hulu',
        name: 'Hulu',
        category: GiftCardCategory.streaming,
        cardColor: const Color(0xFF1CE783),
        logoText: 'Hulu',
      ),
      GiftCard(
        id: 'amazon-prime',
        name: 'Amazon Prime',
        category: GiftCardCategory.streaming,
        cardColor: const Color(0xFF146EB4),
        logoText: 'Prime',
      ),

      // Technology
      GiftCard(
        id: 'apple',
        name: 'Apple',
        category: GiftCardCategory.tech,
        cardColor: const Color(0xFF000000),
        icon: Icons.apple,
      ),
      GiftCard(
        id: 'google-play',
        name: 'Google Play',
        category: GiftCardCategory.tech,
        cardColor: const Color(0xFF4285F4),
        logoText: 'Google',
      ),
      GiftCard(
        id: 'microsoft',
        name: 'Microsoft',
        category: GiftCardCategory.tech,
        cardColor: const Color(0xFF00A4EF),
        logoText: 'MS',
      ),

      // Retail
      GiftCard(
        id: 'amazon',
        name: 'Amazon',
        category: GiftCardCategory.retail,
        cardColor: const Color(0xFF000000),
        logoText: 'amazon',
      ),
      GiftCard(
        id: 'walmart',
        name: 'Walmart',
        category: GiftCardCategory.retail,
        cardColor: const Color(0xFF0071CE),
        logoText: 'Walmart',
      ),
      GiftCard(
        id: 'target',
        name: 'Target',
        category: GiftCardCategory.retail,
        cardColor: const Color(0xFFCC0000),
        logoText: 'Target',
      ),
      GiftCard(
        id: 'best-buy',
        name: 'Best Buy',
        category: GiftCardCategory.retail,
        cardColor: const Color(0xFF003B64),
        logoText: 'Best Buy',
      ),
      GiftCard(
        id: 'ebay',
        name: 'eBay',
        category: GiftCardCategory.retail,
        cardColor: const Color(0xFF0064D2),
        logoText: 'eBay',
      ),

      // Food & Dining
      GiftCard(
        id: 'starbucks',
        name: 'Starbucks',
        category: GiftCardCategory.food,
        cardColor: const Color(0xFF00704A), // Starbucks Green
        icon: Icons.local_cafe,
      ),
      GiftCard(
        id: 'mcdonalds',
        name: 'McDonald\'s',
        category: GiftCardCategory.food,
        cardColor: const Color(0xFFFBC02D),
        logoText: 'M',
      ),
      GiftCard(
        id: 'dominos',
        name: 'Domino\'s',
        category: GiftCardCategory.food,
        cardColor: const Color(0xFF0B648F),
        logoText: 'Domino\'s',
      ),
      GiftCard(
        id: 'uber-eats',
        name: 'Uber Eats',
        category: GiftCardCategory.food,
        cardColor: const Color(0xFF000000),
        logoText: 'Uber',
      ),
      GiftCard(
        id: 'doordash',
        name: 'DoorDash',
        category: GiftCardCategory.food,
        cardColor: const Color(0xFFFF3000),
        logoText: 'Dash',
      ),

      // Supermarkets
      GiftCard(
        id: 'kroger',
        name: 'Kroger',
        category: GiftCardCategory.supermarkets,
        cardColor: const Color(0xFF0E4C92),
        logoText: 'Kroger',
      ),
      GiftCard(
        id: 'whole-foods',
        name: 'Whole Foods',
        category: GiftCardCategory.supermarkets,
        cardColor: const Color(0xFF5C8A3A),
        logoText: 'WF',
      ),
      GiftCard(
        id: 'safeway',
        name: 'Safeway',
        category: GiftCardCategory.supermarkets,
        cardColor: const Color(0xFFE31837),
        logoText: 'Safeway',
      ),

      // Automobile
      GiftCard(
        id: 'shell',
        name: 'Shell',
        category: GiftCardCategory.automobile,
        cardColor: const Color(0xFFFFD700),
        logoText: 'Shell',
      ),
      GiftCard(
        id: 'exxon',
        name: 'Exxon',
        category: GiftCardCategory.automobile,
        cardColor: const Color(0xFFED1C24),
        logoText: 'Exxon',
      ),
      GiftCard(
        id: 'bp',
        name: 'BP',
        category: GiftCardCategory.automobile,
        cardColor: const Color(0xFF00A859),
        logoText: 'BP',
      ),
    ];
  }

  static List<String> getCategories() {
    return [
      GiftCardCategory.all,
      GiftCardCategory.games,
      GiftCardCategory.streaming,
      GiftCardCategory.retail,
      GiftCardCategory.food,
      GiftCardCategory.tech,
      GiftCardCategory.supermarkets,
      GiftCardCategory.automobile,
    ];
  }
}
