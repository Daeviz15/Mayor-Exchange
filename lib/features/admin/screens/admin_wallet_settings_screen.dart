import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../settings/providers/settings_provider.dart';

class AdminWalletSettingsScreen extends ConsumerStatefulWidget {
  const AdminWalletSettingsScreen({super.key});

  @override
  ConsumerState<AdminWalletSettingsScreen> createState() =>
      _AdminWalletSettingsScreenState();
}

class _AdminWalletSettingsScreenState
    extends ConsumerState<AdminWalletSettingsScreen> {
  final List<String> _assets = [
    'BTC',
    'ETH',
    'USDT',
    'SOL',
    'BNB',
    'XRP',
    'DOGE',
    'ADA',
    'TRX',
    'DOT'
  ];
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var asset in _assets) {
      _controllers[asset] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveWallets() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, String> wallets = {};
      _controllers.forEach((asset, controller) {
        if (controller.text.isNotEmpty) {
          wallets[asset] = controller.text.trim();
        }
      });

      await ref.read(settingsServiceProvider).updateAdminWallets(wallets);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Wallet addresses updated!'),
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
        title:
            Text('Deposit Wallets', style: AppTextStyles.titleLarge(context)),
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
          // Sync controllers with loaded settings (safely)
          settings.adminWallets.forEach((asset, address) {
            if (_controllers.containsKey(asset) &&
                _controllers[asset]!.text.isEmpty) {
              _controllers[asset]!.text = address.toString();
            }
          });

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _assets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    return _buildWalletInput(asset);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundCard,
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: Colors.grey[800],
                    ),
                    onPressed: _isLoading ? null : _saveWallets,
                    child: _isLoading
                        ? const RocketLoader(size: 24, color: Colors.white)
                        : const Text('Save Wallets',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWalletInput(String asset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.backgroundElevated,
                shape: BoxShape.circle,
              ),
              child: Text(asset[0],
                  style: const TextStyle(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Text('$asset Deposit Address',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controllers[asset],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter Admin $asset Address',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: AppColors.backgroundCard,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            suffixIcon: IconButton(
              icon: const Icon(Icons.paste, color: AppColors.textSecondary),
              onPressed: () {
                // Future enhancement: Paste from clipboard
              },
            ),
          ),
        ),
      ],
    );
  }
}
