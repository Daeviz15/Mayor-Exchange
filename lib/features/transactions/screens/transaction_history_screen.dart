import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/transaction.dart';
import '../providers/transaction_service.dart';

import '../../../core/widgets/rocket_loader.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(userTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text('History', style: AppTextStyles.titleLarge(context)),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryOrange,
        backgroundColor: AppColors.backgroundCard,
        onRefresh: () async {
          // Refresh the provider to restart the stream/fetch
          return ref.refresh(userTransactionsProvider.future);
        },
        child: transactionsAsync.when(
          loading: () => const Center(child: RocketLoader()),
          error: (err, stack) => Center(
              child: Text('Error: $err',
                  style: const TextStyle(color: Colors.red))),
          data: (transactions) {
            if (transactions.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.35), // Center vertically
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history,
                            size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet.',
                          style: AppTextStyles.bodyMedium(context)
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _HistoryCard(transaction: transaction);
              },
            );
          },
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TransactionModel transaction;

  const _HistoryCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isBuy = transaction.type == TransactionType.buyCrypto ||
        transaction.type == TransactionType.buyGiftCard;

    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isBuy
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                color: isBuy ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitle(transaction),
                    style: AppTextStyles.titleSmall(context)
                        .copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.createdAt.toString().split('.')[0],
                    style: AppTextStyles.bodySmall(context)
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),

            // Amount & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isBuy ? '+' : '-'} ₦${transaction.amountFiat}',
                  style: AppTextStyles.bodyMedium(context)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.status.name.toUpperCase(),
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: _getStatusColor(transaction.status),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(TransactionModel t) {
    switch (t.type) {
      case TransactionType.buyCrypto:
        return 'Buy ${t.details['asset'] ?? 'Crypto'}';
      case TransactionType.sellCrypto:
        return 'Sell ${t.details['asset'] ?? 'Crypto'}';
      case TransactionType.buyGiftCard:
        return 'Buy Gift Card';
      case TransactionType.sellGiftCard:
        return 'Sell Gift Card';
    }
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
