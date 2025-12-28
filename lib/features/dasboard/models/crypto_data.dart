import 'package:flutter/material.dart';

/// Crypto Data Model
/// Represents cryptocurrency market data
class CryptoData {
  final String id;
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final Color iconColor;
  final String iconLetter;
  final String? iconUrl; // CoinGecko icon URL
  final List<double> chartData; // Simple price history for chart
  final DateTime lastUpdated; // Timestamp when price was last fetched

  CryptoData({
    required this.id,
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.iconColor,
    required this.iconLetter,
    this.iconUrl,
    required this.chartData,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory CryptoData.fromJson(Map<String, dynamic> json) {
    // Safely parse lastUpdated - handle old cached data gracefully
    DateTime parsedLastUpdated = DateTime.now();
    try {
      if (json['lastUpdated'] != null && json['lastUpdated'] is int) {
        parsedLastUpdated =
            DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] as int);
      }
    } catch (_) {
      // If parsing fails, use current time
      parsedLastUpdated = DateTime.now();
    }

    return CryptoData(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      iconColor: Color(json['iconColor'] as int),
      iconLetter: json['iconLetter'] as String,
      iconUrl: json['iconUrl'] as String?,
      chartData: (json['chartData'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      lastUpdated: parsedLastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'price': price,
      'changePercent': changePercent,
      'iconColor': iconColor.value,
      'iconLetter': iconLetter,
      'iconUrl': iconUrl,
      'chartData': chartData,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  /// Get a human-readable string for how long ago the price was updated
  String get updatedAgo {
    final now = DateTime.now();
    final diff = now.difference(lastUpdated);

    if (diff.inSeconds < 10) {
      return 'Just now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
