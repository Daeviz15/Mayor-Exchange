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
  final String? imageUrl; // URL to image in Supabase Storage
  final String? redemptionUrl; // URL where user can redeem the gift card
  final bool isActive;
  final int displayOrder;
  final double
      buyRate; // Rate per $1 when platform BUYS from user (legacy/default)
  final double physicalRate; // Rate for physical gift cards
  final double ecodeRate; // Rate for e-codes/digital codes
  final double minValue; // Minimum card value accepted
  final double maxValue; // Maximum card value accepted
  final List<double> allowedDenominations; // Specific allowed values

  GiftCard({
    required this.id,
    required this.name,
    required this.category,
    required this.cardColor,
    this.logoText,
    this.icon,
    this.imageUrl,
    this.redemptionUrl,
    this.isActive = true,
    this.displayOrder = 0,
    this.buyRate = 0.0,
    this.physicalRate = 0.0,
    this.ecodeRate = 0.0,
    this.minValue = 5.0,
    this.maxValue = 500.0,
    this.allowedDenominations = const [],
  });

  /// Create GiftCard from database JSON
  factory GiftCard.fromJson(Map<String, dynamic> json) {
    final buyRate = _parseDouble(json['buy_rate']);
    return GiftCard(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Retail',
      cardColor: _parseColor(json['card_color'] as String?),
      logoText: json['logo_text'] as String?,
      imageUrl: json['image_url'] as String?,
      redemptionUrl: json['redemption_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      buyRate: buyRate,
      physicalRate: _parseDouble(json['physical_rate']),
      ecodeRate: _parseDouble(json['ecode_rate']), // Default: same as buy_rate
      minValue: _parseDouble(json['min_value']) > 0
          ? _parseDouble(json['min_value'])
          : 5.0,
      maxValue: _parseDouble(json['max_value']) > 0
          ? _parseDouble(json['max_value'])
          : 500.0,
      allowedDenominations: _parseDenominations(json['allowed_denominations']),
    );
  }

  /// Get rate based on card type (physical or e-code)
  double getRate({required bool isPhysical}) {
    if (isPhysical) {
      return physicalRate;
    }
    return ecodeRate;
  }

  /// Check if a value is valid for this card
  bool isValidValue(double value) {
    if (value < minValue || value > maxValue) return false;
    if (allowedDenominations.isNotEmpty) {
      return allowedDenominations.contains(value);
    }
    return true;
  }

  /// Get denominations to display (either allowed list or default)
  List<double> getValidDenominations() {
    if (allowedDenominations.isNotEmpty) {
      return allowedDenominations
          .where((d) => d >= minValue && d <= maxValue)
          .toList();
    }
    // Return common denominations within min/max range
    return [25.0, 50.0, 100.0, 200.0, 500.0]
        .where((d) => d >= minValue && d <= maxValue)
        .toList();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      if (value.trim().isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static List<double> _parseDenominations(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => _parseDouble(e)).where((e) => e > 0).toList();
    }
    return [];
  }

  /// Parse hex color string to Color
  static Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return const Color(0xFFFF6B00); // Default orange
    }
    // Remove # if present
    String hex = hexColor.replaceFirst('#', '');
    // Add alpha if not present
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  /// Get redemption instructions based on card type
  String get redemptionInstructions {
    if (redemptionUrl != null) {
      return 'Redeem at $redemptionUrl';
    }
    return 'Visit the official $name website to redeem your code.';
  }

  /// Check if card has an image to display
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
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
