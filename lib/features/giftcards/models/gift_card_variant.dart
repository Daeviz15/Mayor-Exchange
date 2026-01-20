import 'package:flutter/foundation.dart';

/// Represents a denomination and its rate for a gift card variant
@immutable
class DenominationRate {
  final String id;
  final String variantId;
  final double denomination;
  final double rate; // NGN rate
  final bool isActive;

  const DenominationRate({
    required this.id,
    required this.variantId,
    required this.denomination,
    required this.rate,
    this.isActive = true,
  });

  factory DenominationRate.fromJson(Map<String, dynamic> json) {
    return DenominationRate(
      id: json['id'] as String,
      variantId: json['variant_id'] as String,
      denomination: _parseDouble(json['denomination']),
      rate: _parseDouble(json['rate']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'variant_id': variantId,
        'denomination': denomination,
        'rate': rate,
        'is_active': isActive,
      };

  DenominationRate copyWith({
    String? id,
    String? variantId,
    double? denomination,
    double? rate,
    bool? isActive,
  }) {
    return DenominationRate(
      id: id ?? this.id,
      variantId: variantId ?? this.variantId,
      denomination: denomination ?? this.denomination,
      rate: rate ?? this.rate,
      isActive: isActive ?? this.isActive,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DenominationRate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          denomination == other.denomination;

  @override
  int get hashCode => id.hashCode ^ denomination.hashCode;
}

/// Represents an Apple gift card variant (Normal, Vertical, Ecode, Code)
@immutable
class GiftCardVariant {
  final String id;
  final String parentCardId;
  final String name;
  final String? description;
  final int displayOrder;
  final bool isActive;
  final List<DenominationRate> denominationRates;

  const GiftCardVariant({
    required this.id,
    required this.parentCardId,
    required this.name,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
    this.denominationRates = const [],
  });

  factory GiftCardVariant.fromJson(Map<String, dynamic> json) {
    // Parse nested denomination_rates if present
    final ratesJson = json['gift_card_denomination_rates'] as List? ?? [];
    final rates = ratesJson
        .map((r) => DenominationRate.fromJson(r as Map<String, dynamic>))
        .where((r) => r.isActive)
        .toList()
      ..sort((a, b) => a.denomination.compareTo(b.denomination));

    return GiftCardVariant(
      id: json['id'] as String,
      parentCardId: json['parent_card_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      denominationRates: rates,
    );
  }

  /// Get rate for a specific denomination
  double getRateForDenomination(double denomination) {
    try {
      return denominationRates
          .firstWhere((r) => r.denomination == denomination)
          .rate;
    } catch (_) {
      return 0.0;
    }
  }

  /// Get list of valid denominations (with rate > 0)
  List<double> get validDenominations => denominationRates
      .where((r) => r.rate > 0)
      .map((r) => r.denomination)
      .toList();

  /// Check if variant has any valid rates
  bool get hasValidRates => denominationRates.any((r) => r.rate > 0);

  GiftCardVariant copyWith({
    String? id,
    String? parentCardId,
    String? name,
    String? description,
    int? displayOrder,
    bool? isActive,
    List<DenominationRate>? denominationRates,
  }) {
    return GiftCardVariant(
      id: id ?? this.id,
      parentCardId: parentCardId ?? this.parentCardId,
      name: name ?? this.name,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      denominationRates: denominationRates ?? this.denominationRates,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GiftCardVariant &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
