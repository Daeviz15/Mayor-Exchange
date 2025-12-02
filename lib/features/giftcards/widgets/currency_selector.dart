import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Currency Selector Widget
/// Dropdown for currency selection
class CurrencySelector extends StatelessWidget {
  final String selectedCurrency;
  final ValueChanged<String>? onChanged;

  const CurrencySelector({
    super.key,
    this.selectedCurrency = 'USD',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showCurrencyDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCurrency,
              style: AppTextStyles.labelMedium(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    final currencies = ['USD', 'EUR', 'GBP', 'NGN', 'CAD', 'AUD'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...currencies.map((currency) => ListTile(
                  title: Text(
                    currency,
                    style: AppTextStyles.titleSmall(context),
                  ),
                  trailing: selectedCurrency == currency
                      ? const Icon(
                          Icons.check,
                          color: AppColors.primaryOrange,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onChanged?.call(currency);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

