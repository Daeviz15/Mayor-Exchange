import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache Service
/// Handles caching of API responses and data to reduce network calls
class CacheService {
  static const String _prefix = 'cache_';
  static const Duration _defaultCacheDuration = Duration(minutes: 5);

  /// Get cached data
  static Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_prefix$key');
      
      if (cachedData == null) return null;

      final Map<String, dynamic> data = json.decode(cachedData);
      final timestamp = DateTime.parse(data['timestamp'] as String);
      final duration = Duration(seconds: data['duration'] as int? ?? _defaultCacheDuration.inSeconds);
      
      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > duration) {
        await prefs.remove('$_prefix$key');
        return null;
      }

      return fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Cache data
  static Future<void> set<T>(
    String key,
    T data,
    Map<String, dynamic> Function(T) toJson, {
    Duration? duration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': toJson(data),
        'timestamp': DateTime.now().toIso8601String(),
        'duration': (duration ?? _defaultCacheDuration).inSeconds,
      };
      await prefs.setString('$_prefix$key', json.encode(cacheData));
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  /// Cache list data
  static Future<List<T>?> getList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_prefix$key');
      
      if (cachedData == null) return null;

      final Map<String, dynamic> data = json.decode(cachedData);
      final timestamp = DateTime.parse(data['timestamp'] as String);
      final duration = Duration(seconds: data['duration'] as int? ?? _defaultCacheDuration.inSeconds);
      
      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > duration) {
        await prefs.remove('$_prefix$key');
        return null;
      }

      final List<dynamic> listData = data['data'] as List<dynamic>;
      return listData.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Cache list data
  static Future<void> setList<T>(
    String key,
    List<T> data,
    Map<String, dynamic> Function(T) toJson, {
    Duration? duration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data.map((item) => toJson(item)).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'duration': (duration ?? _defaultCacheDuration).inSeconds,
      };
      await prefs.setString('$_prefix$key', json.encode(cacheData));
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  /// Clear specific cache
  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

