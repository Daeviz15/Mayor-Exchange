import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../transactions/providers/rates_provider.dart';

class AdminRatesScreen extends ConsumerStatefulWidget {
  const AdminRatesScreen({super.key});

  @override
  ConsumerState<AdminRatesScreen> createState() => _AdminRatesScreenState();
}

class _AdminRatesScreenState extends ConsumerState<AdminRatesScreen> {
  final List<String> _supportedAssets = [
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

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(ratesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text('Exchange Rates', style: AppTextStyles.titleLarge(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ratesAsync.when(
        loading: () => const Center(
            child: RocketLoader(size: 40, color: AppColors.primaryOrange)),
        error: (err, stack) => Center(
            child:
                Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (rates) {
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _supportedAssets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final asset = _supportedAssets[index];
              final rate = rates.firstWhere(
                (r) => r.assetSymbol == asset,
                orElse: () =>
                    CryptoRate(assetSymbol: asset, buyRate: 0, sellRate: 0),
              );
              return _buildRateCard(context, rate);
            },
          );
        },
      ),
    );
  }

  Widget _buildRateCard(BuildContext context, CryptoRate rate) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.backgroundElevated,
            shape: BoxShape.circle,
          ),
          child: Text(
            rate.assetSymbol.substring(0, 1),
            style: const TextStyle(
                color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
          ),
        ),
        title:
            Text(rate.assetSymbol, style: AppTextStyles.titleMedium(context)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Buy: ₦${rate.buyRate.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.green)),
            Text('Sell: ₦${rate.sellRate.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.textSecondary),
          onPressed: () => _showEditDialog(context, rate),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, CryptoRate rate) async {
    final buyController = TextEditingController(text: rate.buyRate.toString());
    final sellController =
        TextEditingController(text: rate.sellRate.toString());
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Edit ${rate.assetSymbol} Rates',
                style: AppTextStyles.titleLarge(context)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Buy Rate (NGN)', buyController),
                const SizedBox(height: 16),
                _buildTextField('Sell Rate (NGN)', sellController),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() => isSaving = true);
                        try {
                          final buy = double.tryParse(buyController.text) ?? 0;
                          final sell =
                              double.tryParse(sellController.text) ?? 0;

                          await ref.read(adminRatesServiceProvider).updateRate(
                                assetSymbol: rate.assetSymbol,
                                buyRate: buy,
                                sellRate: sell,
                              );

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Rates updated successfully!'),
                                backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: RocketLoader(size: 16, color: Colors.white))
                    : const Text('Save',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.backgroundElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryOrange)),
      ),
    );
  }
}
