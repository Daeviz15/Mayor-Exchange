import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ForexService {
  static const String baseCurrency = 'NGN';
  static const String _apiUrl =
      'https://api.exchangerate-api.com/v4/latest/NGN';
  static const String _cacheKey = 'forex_rates_cache';
  static const String _lastFetchKey = 'forex_last_fetch_time';

  final Ref ref;

  ForexService(this.ref);

  Map<String, double> _rates = {
    'USD': 1500.0,
    'GBP': 1900.0,
    'EUR': 1600.0,
    'CAD': 1100.0,
    'GHS': 90.0,
    'NGN': 1.0,
  };

  /// Initialize: Try to load from cache, then fetch fresh
  Future<void> init() async {
    await _loadFromCache();
    await _fetchRates();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);
      if (cachedString != null) {
        final Map<String, dynamic> json = jsonDecode(cachedString);
        _updateRates(json);
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<void> _fetchRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt(_lastFetchKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Cache for 1 hour (3600000 ms)
      if (now - lastFetch < 3600000 && _rates['USD'] != 1500.0) {
        return;
      }

      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> newRates = data['rates'];

        // The API returns 1 NGN = X USD (e.g. 0.00066).
        // Our logic uses "How many NGN is 1 USD?" (Inverse)
        // Ensure we store it in a way compatible with our convert method or simple invert logic.
        // Wait, convert method: `amountInNgn / rate`.
        // If 1 NGN = 0.00066 USD.
        // 1 USD = 1 / 0.00066 = 1515 NGN.
        // So we need to INVERT the rates from this specific API endpoint if it gives Base: NGN.

        // Actually, let's normalize.
        // API (Base NGN):
        // USD: 0.00066
        // GBP: 0.00052

        // Our App Logic:
        // convert(ngn, USD) => ngn / rate?
        // 15000 NGN / 1500 (rate) = 10 USD.
        // Here rate is "Price of 1 USD in NGN".

        // So we need to calculate: Rate = 1 / API_Value.

        final Map<String, double> processedRates = {};
        newRates.forEach((key, value) {
          if (value is num && value != 0) {
            processedRates[key] = 1 / value.toDouble();
          }
        });

        // NGN is always 1
        processedRates['NGN'] = 1.0;

        _rates = processedRates;
        _saveToCache(_rates, now);
      }
    } catch (e) {
      // Fallback silently to mock/cache
    }
  }

  Future<void> _saveToCache(Map<String, double> rates, int timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Inverse back to simple map for json
      await prefs.setString(_cacheKey, jsonEncode(rates));
      await prefs.setInt(_lastFetchKey, timestamp);
    } catch (e) {
      // Ignore
    }
  }

  void _updateRates(Map<String, dynamic> json) {
    // Helper to safely load double map
    final Map<String, double> loaded = {};
    json.forEach((key, value) {
      if (value is num) loaded[key] = value.toDouble();
    });
    if (loaded.isNotEmpty) {
      _rates = loaded;
    }
  }

  /// Determine conversion. Logic: Amount (NGN) / Rate (NGN per 1 Unit)
  double convert(double amountInNgn, String targetCurrency) {
    if (targetCurrency == 'NGN') return amountInNgn;
    // If we don't have the rate, default to 1 (should generally not happen for major currencies)
    final rate = _rates[targetCurrency] ?? 1.0;
    return amountInNgn / rate;
  }

  // Helper to force refresh manually if needed
  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastFetchKey); // Force invalidation
    await _fetchRates();
  }
}

final forexServiceProvider = Provider<ForexService>((ref) {
  final service = ForexService(ref);
  // Fire and forget initialization
  service.init();
  return service;
});
