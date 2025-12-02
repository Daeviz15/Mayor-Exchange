import 'package:flutter/material.dart';

/// Crypto Data Model
/// Represents cryptocurrency market data
class CryptoData {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final Color iconColor;
  final String iconLetter;
  final List<double> chartData; // Simple price history for chart

  CryptoData({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.iconColor,
    required this.iconLetter,
    required this.chartData,
  });
}
