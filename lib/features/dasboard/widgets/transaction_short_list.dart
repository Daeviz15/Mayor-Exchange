import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/currency_text.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_service.dart';
import '../../transactions/screens/transaction_history_screen.dart';
import '../../transactions/screens/buyer_transaction_status_screen.dart';
import '../../transactions/services/forex_service.dart';

import '../../../core/widgets/animations/fade_in_slide.dart';
import 'transaction_card_skeleton.dart';

class TransactionShortList extends ConsumerWidget {
  const TransactionShortList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(userTransactionsProvider);

    const currency = 'NGN'; // Hardcoded - country selection coming in v2.0
    final forexService = ref.read(forexServiceProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: AppTextStyles.titleMedium(context),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionHistoryScreen(),
                    ),
                  );
                },
                child: Text(
                  'View all',
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No recent transactions',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            final recentTransactions = transactions.take(3).toList();

            return Column(
              children: [
                for (int i = 0; i < recentTransactions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  FadeInSlide(
                    duration: const Duration(milliseconds: 600),
                    delay: Duration(milliseconds: i * 100),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BuyerTransactionStatusScreen(
                              transactionId: recentTransactions[i].id,
                              initialTransaction: recentTransactions[i],
                            ),
                          ),
                        );
                      },
                      child: _CompactTransactionCard(
                        transaction: recentTransactions[i],
                        userCurrency: currency,
                        forexService: forexService,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const TransactionCardSkeletonList(count: 3),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _CompactTransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final String userCurrency;
  final ForexService forexService;

  const _CompactTransactionCard({
    required this.transaction,
    required this.userCurrency,
    required this.forexService,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if this is a Credit (Inflow) or Debit (Outflow) from Fiat Wallet perspective
    final isCredit = transaction.type == TransactionType.sellCrypto ||
        transaction.type == TransactionType.sellGiftCard ||
        transaction.type == TransactionType.deposit;

    // Determine icon based on type
    IconData iconData;
    Color iconColor;

    // Gift cards get a gift icon, others standard arrows
    if (transaction.type == TransactionType.buyGiftCard ||
        transaction.type == TransactionType.sellGiftCard) {
      iconData = Icons.card_giftcard;
      iconColor = Colors.purple; // Differentiation for gift cards
    } else {
      iconData = isCredit ? Icons.arrow_downward : Icons.arrow_upward; // In/Out
      iconColor = isCredit ? AppColors.success : AppColors.error; // Green/Red
    }

    // Currency Conversion
    // Assuming transaction.amountFiat is in NGN (Base)
    final convertAmount =
        forexService.convert(transaction.amountFiat, userCurrency);
    final String symbol = _getSymbol(userCurrency);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(transaction),
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getSubtitle(transaction),
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CurrencyText(
                symbol: '${isCredit ? '+' : '-'}$symbol',
                amount: convertAmount.toStringAsFixed(2),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isCredit
                    ? AppColors.success
                    : AppColors.textPrimary, // Highlight inflow
              ),
              const SizedBox(height: 2),
              Text(
                transaction.status.name
                    .toUpperCase(), // Using name for now, simpler
                style: TextStyle(
                    color: _getStatusColor(transaction.status),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'CAD':
        return 'C\$';
      case 'GHS':
        return '₵';
      default:
        return '₦';
    }
  }

  String _getTitle(TransactionModel t) {
    if (t.details['product_name'] != null) {
      return t.details['product_name'];
    }
    if (t.details['asset'] != null) {
      return '${t.details['asset']}';
    }
    switch (t.type) {
      case TransactionType.buyCrypto:
        return 'Buy Crypto';
      case TransactionType.sellCrypto:
        return 'Sell Crypto';
      case TransactionType.buyGiftCard:
        return 'Buy Gift Card';
      case TransactionType.sellGiftCard:
        return 'Sell Gift Card';
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.withdrawal:
        return 'Withdrawal';
    }
  }

  String _getSubtitle(TransactionModel t) {
    // Format: "Gift Card • 2:30 PM"
    String typeStr = 'Transaction';
    if (t.type.toString().contains('GiftCard')) typeStr = 'Gift Card';
    if (t.type.toString().contains('Crypto')) typeStr = 'Crypto';

    // Simple time formatter could be used here or just basic string
    // Assuming t.createdAt is DateTime
    // We will just show "Crypto • Date" for simplicity without external formatters if possible
    final date = t.createdAt;
    final timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    return "$typeStr • $timeStr";
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.rejected:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
