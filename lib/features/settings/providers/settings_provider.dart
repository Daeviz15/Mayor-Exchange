import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

class AppSettings {
  final Map<String, dynamic> bankDetails;
  final Map<String, dynamic> adminWallets;

  AppSettings({required this.bankDetails, required this.adminWallets});

  factory AppSettings.empty() {
    return AppSettings(bankDetails: {}, adminWallets: {});
  }
}

// Stream of settings (Realtime)
final settingsProvider = StreamProvider<AppSettings>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.from('app_settings').stream(primaryKey: ['key']).map((data) {
    final Map<String, dynamic> bankDetails = {};
    final Map<String, dynamic> adminWallets = {};

    for (var row in data) {
      if (row['key'] == 'admin_bank_details') {
        bankDetails.addAll(row['value'] as Map<String, dynamic>);
      }
      if (row['key'] == 'admin_wallets') {
        adminWallets.addAll(row['value'] as Map<String, dynamic>);
      }
    }

    return AppSettings(bankDetails: bankDetails, adminWallets: adminWallets);
  });
});

class SettingsService {
  final Ref ref;
  SettingsService(this.ref);

  Future<void> updateBankDetails({
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final value = {
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
    };

    await client.from('app_settings').upsert({
      'key': 'admin_bank_details',
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': client.auth.currentUser?.id,
    });
  }

  Future<void> updateAdminWallets(Map<String, String> wallets) async {
    final client = ref.read(supabaseClientProvider);

    await client.from('app_settings').upsert({
      'key': 'admin_wallets',
      'value': wallets,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': client.auth.currentUser?.id,
    });
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref);
});
