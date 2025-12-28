import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/rocket_loader.dart';
import '../../giftcards/providers/giftcard_rates_provider.dart';
import '../../giftcards/data/gift_cards_data.dart';
import '../../giftcards/models/gift_card.dart';

class AdminGiftCardRatesScreen extends ConsumerStatefulWidget {
  const AdminGiftCardRatesScreen({super.key});

  @override
  ConsumerState<AdminGiftCardRatesScreen> createState() =>
      _AdminGiftCardRatesScreenState();
}

class _AdminGiftCardRatesScreenState
    extends ConsumerState<AdminGiftCardRatesScreen> {
  // Get all available gift cards from static data
  final List<GiftCard> _allGiftCards = GiftCardsData.getAllGiftCards();

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(giftCardRatesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title:
            Text('Gift Card Rates', style: AppTextStyles.titleLarge(context)),
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
            itemCount: _allGiftCards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final giftCard = _allGiftCards[index];
              // Find existing rate or create empty one
              final rate = rates.firstWhere(
                (r) => r.cardId == giftCard.id,
                orElse: () => GiftCardRate(
                  cardId: giftCard.id,
                  cardName: giftCard.name,
                  buyRate: 0,
                  sellRate: 0,
                  isActive: false,
                ),
              );
              return _buildRateCard(context, giftCard, rate);
            },
          );
        },
      ),
    );
  }

  Widget _buildRateCard(
      BuildContext context, GiftCard giftCard, GiftCardRate rate) {
    final hasRate = rate.buyRate > 0 || rate.sellRate > 0;
    final isActive = rate.isActive && hasRate;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isActive ? Colors.green.withValues(alpha: 0.3) : Colors.white10,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: giftCard.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: giftCard.icon != null
                ? Icon(giftCard.icon, color: Colors.white, size: 24)
                : Text(
                    giftCard.logoText?.substring(0, 1) ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
          ),
        ),
        title: Row(
          children: [
            Text(giftCard.name, style: AppTextStyles.titleMedium(context)),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(color: Colors.green, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: hasRate
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Buy: ₦${rate.buyRate.toStringAsFixed(0)}/\$1',
                      style:
                          const TextStyle(color: Colors.green, fontSize: 12)),
                  Text('Sell: ₦${rate.sellRate.toStringAsFixed(0)}/\$1',
                      style:
                          const TextStyle(color: Colors.orange, fontSize: 12)),
                ],
              )
            : const Text('Not configured',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.textSecondary),
          onPressed: () => _showEditDialog(context, giftCard, rate),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, GiftCard giftCard, GiftCardRate rate) async {
    final buyController = TextEditingController(
        text: rate.buyRate > 0 ? rate.buyRate.toString() : '');
    final sellController = TextEditingController(
        text: rate.sellRate > 0 ? rate.sellRate.toString() : '');
    bool isActive = rate.isActive;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: giftCard.cardColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: giftCard.icon != null
                        ? Icon(giftCard.icon, color: Colors.white, size: 18)
                        : Text(
                            giftCard.logoText?.substring(0, 1) ?? '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${giftCard.name} Rates',
                      style: AppTextStyles.titleLarge(dialogContext)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rates are per \$1 of card value. E.g., \$100 card × rate = payout',
                          style:
                              TextStyle(color: Colors.blue[300], fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField('Buy Rate (₦ per \$1)', buyController,
                    hint: 'User sells to you'),
                const SizedBox(height: 16),
                _buildTextField('Sell Rate (₦ per \$1)', sellController,
                    hint: 'User buys from you'),
                const SizedBox(height: 16),
                // Active toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active for trading',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Switch(
                      value: isActive,
                      onChanged: (val) => setState(() => isActive = val),
                      activeThumbColor: AppColors.primaryOrange,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
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

                          await ref
                              .read(adminGiftCardRatesServiceProvider)
                              .upsertRate(
                                cardId: giftCard.id,
                                cardName: giftCard.name,
                                buyRate: buy,
                                sellRate: sell,
                                isActive: isActive,
                              );

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Rates updated successfully!'),
                                backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          if (!dialogContext.mounted) return;
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
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

  Widget _buildTextField(String label, TextEditingController controller,
      {String? hint}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
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
