import 'package:flutter/material.dart';

/// Gift Card Model
/// Represents a gift card brand/type
class GiftCard {
  final String id;
  final String name;
  final String category;
  final Color cardColor;
  final String? logoText; // Text to display if no image
  final IconData? icon; // Icon to display if no image/text
  final String? imageAsset; // Asset path for logo image (optional)
  final String? redemptionUrl; // URL where user can redeem the gift card

  GiftCard({
    required this.id,
    required this.name,
    required this.category,
    required this.cardColor,
    this.logoText,
    this.icon,
    this.imageAsset,
    this.redemptionUrl,
  });

  /// Get redemption instructions based on card type
  String get redemptionInstructions {
    if (redemptionUrl != null) {
      return 'Redeem at $redemptionUrl';
    }
    return 'Visit the official $name website to redeem your code.';
  }
}

/// Gift Card Categories
class GiftCardCategory {
  static const String all = 'All';
  static const String games = 'Games';
  static const String entertainment = 'Entertainment';
  static const String retail = 'Retail';
  static const String food = 'Food & Dining';
  static const String tech = 'Technology';
  static const String streaming = 'Streaming';
  static const String supermarkets = 'Supermarkets';
  static const String automobile = 'Automobile';
}
