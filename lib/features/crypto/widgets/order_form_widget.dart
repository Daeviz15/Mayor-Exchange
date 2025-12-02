import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/crypto_details.dart';

/// Order Form Widget
/// Form for placing buy/sell orders
class OrderFormWidget extends StatefulWidget {
  final CryptoDetails cryptoDetails;
  final bool isBuyOrder;
  final VoidCallback? onSubmit;

  const OrderFormWidget({
    super.key,
    required this.cryptoDetails,
    this.isBuyOrder = true,
    this.onSubmit,
  });

  @override
  State<OrderFormWidget> createState() => _OrderFormWidgetState();
}

class _OrderFormWidgetState extends State<OrderFormWidget> {
  OrderType _selectedOrderType = OrderType.market;
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Type',
                  style: AppTextStyles.titleSmall(context),
                ),
                GestureDetector(
                  onTap: _showOrderTypeDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getOrderTypeLabel(_selectedOrderType),
                          style: AppTextStyles.bodyMedium(context),
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
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Amount Input
            Text(
              'Amount',
              style: AppTextStyles.titleSmall(context),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTextStyles.bodyLarge(context),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Text(
                    widget.cryptoDetails.symbol,
                    style: AppTextStyles.titleSmall(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Estimated Value
            if (_amountController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimated Value',
                      style: AppTextStyles.bodySmall(context),
                    ),
                    Text(
                      '\$${_calculateEstimatedValue().toStringAsFixed(2)}',
                      style: AppTextStyles.titleSmall(context).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showOrderTypeDialog() {
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
            ...OrderType.values.map((type) => ListTile(
                  title: Text(
                    _getOrderTypeLabel(type),
                    style: AppTextStyles.titleSmall(context),
                  ),
                  trailing: _selectedOrderType == type
                      ? const Icon(
                          Icons.check,
                          color: AppColors.primaryOrange,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedOrderType = type;
                    });
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _getOrderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.market:
        return 'Market';
      case OrderType.limit:
        return 'Limit';
      case OrderType.stop:
        return 'Stop';
    }
  }

  double _calculateEstimatedValue() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return amount * widget.cryptoDetails.currentPrice;
  }
}

