import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../settings/providers/settings_provider.dart';

class AdminBankDetailsScreen extends ConsumerStatefulWidget {
  const AdminBankDetailsScreen({super.key});

  @override
  ConsumerState<AdminBankDetailsScreen> createState() =>
      _AdminBankDetailsScreenState();
}

class _AdminBankDetailsScreenState
    extends ConsumerState<AdminBankDetailsScreen> {
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load initial values safely
    // We can't use ref.watch directly in initState, but the StreamProvider will update the UI
  }

  // Effect to sync controller with provider data
  void _syncControllers(AppSettings settings) {
    if (_bankNameController.text.isEmpty &&
        settings.bankDetails['bank_name'] != null) {
      _bankNameController.text = settings.bankDetails['bank_name'];
      _accountNumberController.text =
          settings.bankDetails['account_number'] ?? '';
      _accountNameController.text = settings.bankDetails['account_name'] ?? '';
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(settingsServiceProvider).updateBankDetails(
            bankName: _bankNameController.text,
            accountNumber: _accountNumberController.text,
            accountName: _accountNameController.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bank details updated!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Bank Settings', style: AppTextStyles.titleLarge(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(
            child: RocketLoader(size: 40, color: AppColors.primaryOrange)),
        error: (err, _) => Center(
            child:
                Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (settings) {
          // Sync only if empty to avoid overwriting user while typing if random stream update happens
          // But actually streams update on save, so it's fine.
          // Better logic: use a flag or just simplistic approach:
          if (_bankNameController.text.isEmpty &&
              settings.bankDetails['bank_name'] != null) {
            _bankNameController.text = settings.bankDetails['bank_name'];
            _accountNumberController.text =
                settings.bankDetails['account_number'] ?? '';
            _accountNameController.text =
                settings.bankDetails['account_name'] ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Set the bank account where users should send payments.',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                _buildTextField('Bank Name', _bankNameController),
                const SizedBox(height: 16),
                _buildTextField('Account Number', _accountNumberController,
                    isNumber: true),
                const SizedBox(height: 16),
                _buildTextField('Account Name', _accountNameController),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: Colors.grey[800],
                    ),
                    onPressed: _isLoading ? null : _saveSettings,
                    child: _isLoading
                        ? const RocketLoader(size: 24, color: Colors.white)
                        : const Text('Save Details',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: AppColors.backgroundCard,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
