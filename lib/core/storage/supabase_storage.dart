import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Secure storage implementation for Supabase Auth persistence.
/// This ensures session tokens are stored in the device's secure enclave.
class SupabaseSecureStorage extends LocalStorage {
  final _secureStorage = const FlutterSecureStorage();
  static const _storageKey = 'supabase_auth_token';

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    return await _secureStorage.read(key: _storageKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await _secureStorage.delete(key: _storageKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _secureStorage.write(key: _storageKey, value: persistSessionString);
  }

  @override
  Future<bool> hasAccessToken() async {
    return await _secureStorage.containsKey(key: _storageKey);
  }
}
