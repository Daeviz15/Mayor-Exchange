import 'package:flutter/material.dart';

/// Crypto Details Model
/// Detailed information about a cryptocurrency
class CryptoDetails {
  final String symbol;
  final String name;
  final String pair; // e.g., "BTC/USD"
  final double currentPrice;
  final double change24h;
  final double changePercent24h;
  final double high24h;
  final double low24h;
  final double volumeBTC;
  final double volumeUSD;
  final Color accentColor;
  final List<PricePoint> priceHistory; // For chart

  CryptoDetails({
    required this.symbol,
    required this.name,
    required this.pair,
    required this.currentPrice,
    required this.change24h,
    required this.changePercent24h,
    required this.high24h,
    required this.low24h,
    required this.volumeBTC,
    required this.volumeUSD,
    required this.accentColor,
    required this.priceHistory,
  });
}

/// Price Point for Chart
class PricePoint {
  final DateTime time;
  final double price;

  PricePoint({
    required this.time,
    required this.price,
  });
}

/// Order Type Enum
enum OrderType {
  market,
  limit,
  stop,
}

/// Time Range Enum
enum TimeRange {
  oneHour,
  twentyFourHours,
  oneWeek,
  oneMonth,
  oneYear,
}

