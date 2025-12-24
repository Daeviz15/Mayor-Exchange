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
  });

  factory CryptoData.fromJson(Map<String, dynamic> json) {
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
    };
  }
}
